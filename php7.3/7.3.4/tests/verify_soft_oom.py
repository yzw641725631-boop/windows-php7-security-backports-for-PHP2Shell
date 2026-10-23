"""Bounded local FastCGI availability checks for an experimental engine port.
Passing is not a complete memory-safety or RCE regression certification.
"""
from pathlib import Path
import json
import os
import socket
import struct
import subprocess
import time
import argparse
import uuid
from verify_fastcgi import record, length, exact

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / "stage"
CASES = ROOT / "soft-oom-cases" / uuid.uuid4().hex
LOGS = ROOT / "logs"
LOGS.mkdir(parents=True, exist_ok=True)

PHP = r'''<?php
header('X-PHP-PID: '.getmypid());
$case=isset($_GET['case'])?$_GET['case']:'normal';
if ($case !== 'normal' && $case !== 'hard') {
    register_shutdown_function(function(){echo 'SHUTDOWN-MARKER';});
}
function exhaust_in_steps() {
    $a=[];
    for($i=0;$i<1024;$i++)$a[]=str_repeat(chr(65+$i%26),65536);
}
function accept_args($a,$b=null) { return 1; }
switch($case) {
case 'loop': exhaust_in_steps(); break;
case 'try_finally':
    try { exhaust_in_steps(); } catch(Throwable $e) { echo 'CAUGHT-INVALID'; }
    finally { echo 'FINALLY-INVALID'; }
    echo 'CONTINUED-INVALID'; break;
case 'array_fill': $a=array_fill(0,400000,$case); echo 'CONTINUED-INVALID'; break;
case 'array_fill_unused': array_fill(0,400000,$case); echo 'CONTINUED-INVALID'; break;
case 'json_unused': $s=str_repeat(substr($case,0,1),10*1024*1024); json_encode($s); echo 'CONTINUED-INVALID'; break;
case 'nested_argument': accept_args(array_fill(0,400000,$case),str_repeat($case,1024)); echo 'CONTINUED-INVALID'; break;
case 'callback': $items=[1,2,3]; array_walk($items,function($x){exhaust_in_steps();}); echo 'CONTINUED-INVALID'; break;
case 'exception_inflight':
    try { throw new Exception('ordinary'); } finally { exhaust_in_steps(); }
    echo 'CONTINUED-INVALID'; break;
case 'shutdown_oom':
    register_shutdown_function(function(){exhaust_in_steps();}); echo 'before-shutdown'; break;
case 'destructor':
    class LargeDestructor { function __destruct(){exhaust_in_steps();} }
    $o=new LargeDestructor; unset($o); echo 'CONTINUED-INVALID'; break;
case 'concat':
    $a=[];$s=str_repeat(substr($case,0,1),65536);for($i=0;$i<1024;$i++){$a[]=$s.$i;}
    echo 'CONTINUED-INVALID';break;
case 'hard': $a=[]; for($i=0;$i<4000000;$i++) $a[]=$i; echo 'CONTINUED-INVALID';break;
default:
    header('Content-Type: application/json');
    echo json_encode(['pid'=>getmypid(),'version'=>PHP_VERSION,'status'=>'ok','error'=>error_get_last(),
        'opcache_cached'=>function_exists('opcache_is_script_cached')?opcache_is_script_cached(__FILE__):false]);
}
'''


def fcgi(port, case):
    params={"GATEWAY_INTERFACE":"CGI/1.1","SERVER_SOFTWARE":"php734-prototype-validation",
            "REQUEST_METHOD":"GET","SCRIPT_FILENAME":str(CASES/'index.php'),"SCRIPT_NAME":"/index.php",
            "QUERY_STRING":"case="+case,"REQUEST_URI":"/index.php?case="+case,"SERVER_PROTOCOL":"HTTP/1.1",
            "SERVER_NAME":"localhost","SERVER_PORT":"80","REMOTE_ADDR":"127.0.0.1","REMOTE_PORT":"40000",
            "REDIRECT_STATUS":"200"}
    packed=b''
    for key,value in params.items():
        key,value=key.encode(),value.encode()
        packed+=length(len(key))+length(len(value))+key+value
    with socket.create_connection(('127.0.0.1',port),timeout=12) as sock:
        sock.settimeout(12)
        sock.sendall(record(1,struct.pack('!HB5s',1,0,b'\0'*5))+record(4,packed)+record(4)+record(5))
        stdout,stderr=b'',b''
        while True:
            version,kind,rid,size,padding,reserved=struct.unpack('!BBHHBB',exact(sock,8))
            content=exact(sock,size)
            if padding:exact(sock,padding)
            if kind==6:stdout+=content
            elif kind==7:stderr+=content
            elif kind==3:
                app_status,protocol_status=struct.unpack('!IB',content[:5]);break
    text=stdout.decode('utf-8','replace')
    headers,sep,body=text.partition('\r\n\r\n')
    return {'app_status':app_status,'protocol_status':protocol_status,'headers':headers,'body':body,
            'stderr':stderr.decode('utf-8','replace')}


def start(label, extra=()):
    with socket.socket() as sock:
        sock.bind(('127.0.0.1',0));port=sock.getsockname()[1]
    env=os.environ.copy();env['PHP_FCGI_MAX_REQUESTS']='1000';env['PHP_FCGI_CHILDREN']='0'
    stream=(LOGS/(label+'-soft-oom-server.log')).open('w',encoding='utf-8')
    args=[str(STAGE/'php-cgi.exe'),'-n','-d','memory_limit=16M','-d','display_errors=0','-d','log_errors=1',
          *extra,'-b','127.0.0.1:'+str(port)]
    process=subprocess.Popen(args,cwd=STAGE,env=env,stdout=stream,stderr=stream,creationflags=subprocess.CREATE_NO_WINDOW)
    for attempt in range(100):
        if process.poll() is not None:raise RuntimeError('Process stopped before readiness: '+label)
        try:
            with socket.create_connection(('127.0.0.1',port),timeout=.1):break
        except OSError:time.sleep(.1)
    return process,port,stream


def stop(process,stream):
    if process.poll() is None:
        process.terminate()
        try:process.wait(timeout=5)
        except subprocess.TimeoutExpired:process.kill();process.wait(timeout=3)
    stream.close()


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--cycles',type=int,default=10)
    options=parser.parse_args()
    if not 1<=options.cycles<=20:parser.error('cycles must be between 1 and 20')
    CASES.mkdir(parents=True,exist_ok=True);(CASES/'index.php').write_text(PHP,encoding='ascii',newline='\n')
    report={'kind':'experimental','security_equivalence_to_official_patch':False,'cycles':options.cycles,'cases':[],'failures':[]}
    modes=[('plain',[]),('opcache',['-d','zend_extension='+str(STAGE/'ext/php_opcache.dll'),'-d','opcache.enable=1','-d','opcache.enable_cli=1','-d','opcache.file_update_protection=0'])]
    for label,mode_options in modes:
        process,port,stream=start(label,mode_options)
        try:
            initial=fcgi(port,'normal')
            try:
                pid=json.loads(initial['body'])['pid'];assert pid==process.pid
            except Exception as error:
                report['failures'].append({'mode':label,'case':'initial','reply':initial,'error':str(error)})
                print(label+' initial: FAIL '+str(error),flush=True)
                continue
            cases=('loop','try_finally','array_fill','array_fill_unused','json_unused','nested_argument','callback','exception_inflight','shutdown_oom','destructor','concat')
            for index,case in enumerate(cases*options.cycles):
                row={'mode':label,'case':case,'cycle':index//len(cases)+1,'initial_pid':pid}
                try:
                    reply=fcgi(port,case);row['reply']=reply
                    assert 'INVALID' not in reply['body'],'Business code continued after the memory error'
                    assert 'SHUTDOWN-MARKER' in reply['body'],'Ordinary registered shutdown callback did not run'
                    assert 'Exception thrown without a stack frame' not in reply['stderr'],'Invalid shutdown exception handling'
                    assert process.poll() is None,'The worker stopped after a soft OOM'
                    after=fcgi(port,'normal');data=json.loads(after['body']);row['after']=data
                    assert data['pid']==pid and data['status']=='ok','Next request did not use the same worker'
                    assert data['opcache_cached']==(label=='opcache'),'OPcache mode did not match actual script caching'
                    assert data['error'] is None,'Previous request error state leaked into the next request'
                    assert 'Allowed memory size' in reply['stderr'] or 'Allowed memory size' in reply['body'],'No OOM was observed'
                    row['passed']=True
                except Exception as error:
                    row['passed']=False;row['error']=str(error);row['process_exit']=process.poll();report['failures'].append(row)
                report['cases'].append(row)
                if index<len(cases) or not row['passed']:
                    print(label+' '+case+': '+('PASS' if row['passed'] else 'FAIL '+row['error']),flush=True)
                if not row['passed']:break
        finally:stop(process,stream)
    # The hard-limit check uses a separate process and a bounded pre-allocation failure.
    process,port,stream=start('hard',['-d','memory_hard_limit_percent=100'])
    try:
        fcgi(port,'normal')
        try:fcgi(port,'hard')
        except (RuntimeError,ConnectionError,OSError):pass
        try:code=process.wait(timeout=5)
        except subprocess.TimeoutExpired:code=None
        report['hard_limit_exit_code']=code
        if code!=137:report['failures'].append({'case':'hard','error':'Expected exit 137','actual':code})
    finally:stop(process,stream)
    report['passed']=not report['failures']
    (LOGS/'soft-oom-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps({'passed':report['passed'],'case_count':len(report['cases']),'failure_count':len(report['failures']),
                      'hard_limit_exit_code':report['hard_limit_exit_code']},indent=2))
    if not report['passed']:raise SystemExit(1)


if __name__=='__main__':main()
