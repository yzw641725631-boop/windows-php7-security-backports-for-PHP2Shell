"""Bounded compatibility probe of locally archived upstream PHP 8.2 PHPTs.

This is a comparison probe, not the upstream PHP test harness. Different output
can reflect PHP 7/8 language or API differences; a crash remains a defect.
Original test files are kept untouched. Each executable gets a separate process.
"""
from collections import Counter
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import json
import os
import re
import subprocess

ROOT = Path(__file__).resolve().parents[1]
UPSTREAM = ROOT / 'tests/upstream-tests'
(ROOT / 'logs').mkdir(parents=True, exist_ok=True)
STAGE = ROOT / 'stage'
WORK = ROOT / 'upstream-case-work'
TIMEOUT = 8
EXTENSIONS = ('mbstring', 'openssl', 'fileinfo', 'intl', 'soap', 'sockets',
              'sodium', 'gd2', 'mysqli', 'pdo_mysql', 'pdo_sqlite', 'sqlite3',
              'bz2', 'gmp', 'zip', 'zend_test')
BASE = [str(STAGE/'php.exe'), '-n', '-d', 'display_errors=1', '-d', 'log_errors=0',
        '-d', 'html_errors=0', '-d', 'memory_limit=32M', '-d', 'max_execution_time=3',
        '-d', 'extension_dir='+str(STAGE/'ext')]
for extension in EXTENSIONS:
    dll=STAGE/'ext'/('php_'+extension+'.dll')
    if dll.exists(): BASE += ['-d', 'extension='+str(dll)]


def run(args, cwd, env=None):
    return subprocess.run(args, cwd=cwd, env=env, stdout=subprocess.PIPE,
                          stderr=subprocess.STDOUT, timeout=TIMEOUT,
                          creationflags=subprocess.CREATE_NO_WINDOW)


def normalize(text):
    return text.replace('\r\n','\n').strip()


def matches(expected, output, kind):
    expected,output=normalize(expected),normalize(output)
    if kind=='EXPECT':return expected==output
    if kind=='EXPECTREGEX':return re.fullmatch(expected,output,re.S) is not None
    parts=re.split(r'(%r.*?%r|%[eSsAaWwidfxc%])',expected,flags=re.S)
    substitutions={'%e':re.escape(os.sep),'%s':'[^\n]+','%S':'[^\n]*',
                   '%a':'.+','%A':'.*','%w':'\\s*','%i':'[+-]?\\d+',
                   '%d':'\\d+','%x':'[0-9a-fA-F]+','%f':r'[+-]?(?:\d*\.?\d+)(?:[Ee][+-]?\d+)?',
                   '%c':'.','%%':'%'}
    pattern=''
    for part in parts:
        pattern += part[2:-2] if part.startswith('%r') and part.endswith('%r') else substitutions.get(part,re.escape(part))
    return re.fullmatch(pattern,output,re.S) is not None


def test(path, available):
    relative=path.relative_to(UPSTREAM)
    row={'test':relative.as_posix()}
    parts=re.split(r'^--([A-Z_]+)--\s*\r?\n',path.read_text(encoding='utf-8'),flags=re.M)
    sections=dict(zip(parts[1::2],parts[2::2]))
    unsupported=set(sections)&{'POST','POST_RAW','GET','CGI','PHPDBG','FILE_EXTERNAL','REQUEST','COOKIE','STDIN'}
    if unsupported or 'FILE' not in sections:
        return dict(row,status='not_run',reason='Unsupported SAPI/fixture sections: '+','.join(sorted(unsupported)))
    required=set(sections.get('EXTENSIONS','').lower().split())
    missing=required-available
    if missing:return dict(row,status='not_run',reason='Unavailable extension: '+','.join(sorted(missing)))
    if re.search(r'\b(?:include|require)(?:_once)?\b|TEST_PHP_EXECUTABLE|\b(?:shell_exec|proc_open|passthru)\s*\(',sections['FILE']):
        return dict(row,status='not_run',reason='Needs external fixture or upstream subprocess harness')
    settings=[]
    for setting in sections.get('INI','').splitlines():
        setting=setting.strip()
        if not setting or setting.startswith(';'):continue
        if setting.startswith('memory_limit='):
            value=setting.partition('=')[2].strip()
            match=re.fullmatch(r'(\d+)([KMG]?)',value,re.I)
            if not match:return dict(row,status='not_run',reason='Unbounded/non-numeric memory_limit')
            size=int(match[1])*{'':1,'K':1024,'M':1024**2,'G':1024**3}[match[2].upper()]
            if size>128*1024**2:return dict(row,status='not_run',reason='Memory limit above probe budget')
        settings += ['-d',setting.replace('{PWD}',str(path.parent))]
    directory=WORK/relative.parent/path.stem
    directory.mkdir(parents=True,exist_ok=True)
    env=os.environ.copy()
    for line in sections.get('ENV','').splitlines():
        key,sep,value=line.partition('=')
        if sep:env[key]=value
    try:
        if 'SKIPIF' in sections:
            skip=directory/'skip.php';skip.write_text(sections['SKIPIF'],encoding='utf-8',newline='\n')
            result=run(BASE+settings+[str(skip)],directory,env)
            answer=result.stdout.decode('utf-8','replace')
            if answer.lstrip().lower().startswith('skip'):
                return dict(row,status='not_run',reason=normalize(answer))
        script=directory/'test.php'
        script.write_text(sections['FILE'],encoding='utf-8',newline='\n')
        lint=run(BASE+['-l',str(script)],directory,env)
        if lint.returncode:
            return dict(row,status='syntax_incompatible',output=lint.stdout.decode('utf-8','replace'))
        result=run(BASE+settings+[str(script)],directory,env)
        output=result.stdout.decode('utf-8','replace')
        expectation=next((key for key in ('EXPECT','EXPECTF','EXPECTREGEX') if key in sections),None)
        if result.returncode not in (0,1,137,255):status='crash_or_abnormal_exit'
        elif result.returncode==137:status='hard_limit_exit'
        elif expectation and matches(sections[expectation],output,expectation):status='matches_upstream'
        else:status='different_output'
        return dict(row,status=status,exit_code=result.returncode,output=output[:8000],
                    expected=sections.get(expectation,'')[:8000])
    except subprocess.TimeoutExpired:
        return dict(row,status='timeout',reason='Stopped after '+str(TIMEOUT)+' seconds')
    except Exception as error:
        return dict(row,status='probe_error',reason=str(error))


def main():
    available_result=run(BASE+['-m'],STAGE)
    assert available_result.returncode==0
    available={line.strip().lower() for line in available_result.stdout.decode().splitlines()}
    cases=sorted(UPSTREAM.rglob('*.phpt'))
    rows=[]
    with ThreadPoolExecutor(max_workers=4) as pool:
        jobs=[pool.submit(test,path,available) for path in cases]
        for number,future in enumerate(as_completed(jobs),1):
            row=future.result();rows.append(row)
            if number%25==0 or row['status'] in ('crash_or_abnormal_exit','timeout'):
                print(str(number)+'/'+str(len(cases))+': '+row['status']+' '+row['test'],flush=True)
    report={'kind':'bounded PHP 8.2 test compatibility probe',
            'not_upstream_test_harness':True,'security_equivalence_to_official_patch':False,
            'timeout_seconds_per_process':TIMEOUT,'max_configured_memory_bytes':128*1024**2,
            'counts':dict(Counter(row['status'] for row in rows)),
            'cases':sorted(rows,key=lambda row:row['test'])}
    (ROOT/'logs/upstream-case-probe.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report['counts'],indent=2))


if __name__=='__main__':main()
