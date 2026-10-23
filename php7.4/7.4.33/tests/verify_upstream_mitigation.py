"""Bounded checks of the exact PHP 7.4 upstream worker-exit mitigation."""
from pathlib import Path
import json
import os
import socket
import struct
import subprocess
import time
from verify_fastcgi import record, length, exact
from oom_cases import PHP as CASES_PHP

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'stage'
LOGS = ROOT / 'logs'
CASES = ROOT / 'verification/official-mitigation'
CASES.mkdir(parents=True, exist_ok=True)
(CASES / 'index.php').write_text(CASES_PHP, encoding='ascii')


def query(port, case):
    params = {'GATEWAY_INTERFACE': 'CGI/1.1', 'SERVER_SOFTWARE': 'bounded-official74-check',
              'REQUEST_METHOD': 'GET', 'SCRIPT_FILENAME': str(CASES / 'index.php'), 'SCRIPT_NAME': '/index.php',
              'QUERY_STRING': 'case=' + case, 'REQUEST_URI': '/index.php?case=' + case, 'SERVER_PROTOCOL': 'HTTP/1.1',
              'SERVER_NAME': 'localhost', 'SERVER_PORT': '80', 'REMOTE_ADDR': '127.0.0.1',
              'REMOTE_PORT': '40000', 'REDIRECT_STATUS': '200'}
    packed = b''
    for key, value in params.items():
        a, b = key.encode(), value.encode()
        packed += length(len(a)) + length(len(b)) + a + b
    stdout = b''
    stderr = b''
    ended = False
    with socket.create_connection(('127.0.0.1', port), timeout=10) as sock:
        sock.sendall(record(1, struct.pack('!HB5s', 1, 0, b'\0' * 5)) + record(4, packed) + record(4) + record(5))
        while True:
            try:
                header = exact(sock, 8)
            except (RuntimeError, ConnectionError):
                break
            version, kind, rid, count, padding, reserved = struct.unpack('!BBHHBB', header)
            content = exact(sock, count)
            if padding:
                exact(sock, padding)
            if kind == 6:
                stdout += content
            elif kind == 7:
                stderr += content
            elif kind == 3:
                ended = True
                break
    return {'stdout': stdout.decode('utf-8', 'replace'), 'stderr': stderr.decode('utf-8', 'replace'), 'end_request_record': ended}


def start(label, extra):
    with socket.socket() as sock:
        sock.bind(('127.0.0.1', 0))
        port = sock.getsockname()[1]
    env = os.environ.copy()
    env['PHP_FCGI_MAX_REQUESTS'] = '1000'
    env['PHP_FCGI_CHILDREN'] = '0'
    logfile = LOGS / ('mitigation-' + label + '.log')
    stream = logfile.open('w', encoding='utf-8')
    proc = subprocess.Popen([str(STAGE / 'php-cgi.exe'), '-n', '-d', 'memory_limit=16M', '-d', 'display_errors=0',
                             '-d', 'log_errors=1', *extra, '-b', '127.0.0.1:' + str(port)],
                            cwd=STAGE, env=env, stdout=stream, stderr=stream, creationflags=subprocess.CREATE_NO_WINDOW)
    for attempt in range(100):
        if proc.poll() is not None:
            raise RuntimeError('Worker exited before startup: ' + label)
        try:
            with socket.create_connection(('127.0.0.1', port), timeout=0.1):
                break
        except OSError:
            time.sleep(0.05)
    return proc, port, stream, logfile


report = {'kind': 'bounded upstream PHP 7.4 mitigation behavior check', 'security_exploit_certification': False,
          'oom_worker_exit_expected': 1, 'cases': [], 'same_worker_survival_expected': False}
cases = ('loop', 'try_finally', 'array_fill', 'array_fill_unused', 'json_unused', 'nested_argument',
         'callback', 'exception_inflight', 'shutdown_oom', 'destructor', 'concat')
modes = [('plain', []), ('opcache', ['-d', 'zend_extension=' + str(STAGE / 'ext/php_opcache.dll'),
                                  '-d', 'opcache.enable=1', '-d', 'opcache.enable_cli=1',
                                  '-d', 'opcache.file_update_protection=0'])]
for mode, extra in modes:
    for case in cases:
        label = mode + '-' + case
        proc, port, stream, logfile = start(label, extra)
        try:
            initial = query(port, 'normal')
            body = initial['stdout'].split('\r\n\r\n', 1)[1]
            normal = json.loads(body)
            assert normal['status'] == 'ok' and normal['pid'] == proc.pid
            assert normal['opcache_cached'] == (mode == 'opcache')
            reply = query(port, case)
            code = proc.wait(timeout=8)
            stream.flush()
            text = reply['stdout'] + reply['stderr'] + logfile.read_text('utf-8')
            assert code == 1, (label, code)
            assert 'Allowed memory size' in text, label
            assert 'CONTINUED-INVALID' not in text and 'CAUGHT-INVALID' not in text and 'FINALLY-INVALID' not in text
            assert 'SHUTDOWN-MARKER' not in text, label
            report['cases'].append({'mode': mode, 'case': case, 'exit_code': code,
                                    'fatal_oom_recorded': True, 'ordinary_shutdown_not_run': True, 'passed': True})
            print(label + ': passed (worker exited 1)', flush=True)
        finally:
            if proc.poll() is None:
                proc.terminate()
                proc.wait(timeout=5)
            stream.close()
report['passed'] = len(report['cases']) == 22
(LOGS / 'official-mitigation-verification.json').write_text(json.dumps(report, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'passed': report['passed'], 'cases': len(report['cases'])}))
