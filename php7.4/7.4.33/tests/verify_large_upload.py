"""Stream a 260 MiB multipart file to a disposable loopback FastCGI worker.
No business endpoint is called. File bytes are generated incrementally and checked
by SHA-256. A 32 MiB PHP limit demonstrates that file bytes can be streamed to disk.
"""
from pathlib import Path
import hashlib
import json
import os
import socket
import struct
import subprocess
import time
from verify_fastcgi import record, length, exact

ROOT = Path(__file__).resolve().parents[1]
STAGE = ROOT / 'stage'
WORK = ROOT / 'verification/large-upload'
WORK.mkdir(parents=True, exist_ok=True)
PHP = '''<?php
session_start();
header('Content-Type: application/json');
$file = isset($_FILES['upload']) ? $_FILES['upload'] : null;
echo json_encode(array('pid'=>getmypid(), 'file'=>$file ? array('size'=>$file['size'], 'error'=>$file['error'],
    'sha256'=>$file['error']===0 ? hash_file('sha256', $file['tmp_name']) : null) : null,
    'peak'=>memory_get_peak_usage(true), 'memory_limit'=>ini_get('memory_limit'),
    'progress'=>isset($_SESSION['upload_progress_largecheck'])));
'''
(WORK / 'probe.php').write_text(PHP, encoding='ascii')
with socket.socket() as sock:
    sock.bind(('127.0.0.1', 0))
    port = sock.getsockname()[1]
env = os.environ.copy()
env['PHP_FCGI_CHILDREN'] = '0'
env['PHP_FCGI_MAX_REQUESTS'] = '100'
stream = (ROOT / 'logs/large-upload-server.log').open('w', encoding='utf-8')
args = [str(STAGE / 'php-cgi.exe'), '-n', '-d', 'memory_limit=32M', '-d', 'post_max_size=300M',
        '-d', 'upload_max_filesize=280M', '-d', 'upload_tmp_dir=' + str(WORK), '-d', 'session.save_path=' + str(WORK),
        '-d', 'session.upload_progress.enabled=1', '-d', 'session.upload_progress.cleanup=0',
        '-d', 'max_execution_time=30', '-d', 'max_input_time=30', '-b', '127.0.0.1:' + str(port)]
proc = subprocess.Popen(args, cwd=STAGE, env=env, stdout=stream, stderr=stream, creationflags=subprocess.CREATE_NO_WINDOW)
try:
    for attempt in range(100):
        if proc.poll() is not None:
            raise RuntimeError('FastCGI worker exited before startup')
        try:
            with socket.create_connection(('127.0.0.1', port), timeout=0.1):
                break
        except OSError:
            time.sleep(0.05)
    boundary = 'php74boundedlargeupload'
    prefix = ('--' + boundary + '\r\nContent-Disposition: form-data; name="PHP_SESSION_UPLOAD_PROGRESS"\r\n\r\nlargecheck\r\n'
              '--' + boundary + '\r\nContent-Disposition: form-data; name="upload"; filename="fixture.bin"\r\n'
              'Content-Type: application/octet-stream\r\n\r\n').encode()
    suffix = ('\r\n--' + boundary + '--\r\n').encode()
    size = 260 * 1024 * 1024
    chunk = b'php74-large-file-stream-check\0' * 2000
    chunk = chunk[:60000]
    params = {'GATEWAY_INTERFACE':'CGI/1.1','SERVER_SOFTWARE':'bounded-large-upload-check','REQUEST_METHOD':'POST',
              'SCRIPT_FILENAME':str(WORK/'probe.php'),'SCRIPT_NAME':'/probe.php','REQUEST_URI':'/probe.php',
              'QUERY_STRING':'','SERVER_PROTOCOL':'HTTP/1.1','SERVER_NAME':'localhost','SERVER_PORT':'80',
              'REMOTE_ADDR':'127.0.0.1','REMOTE_PORT':'40000','REDIRECT_STATUS':'200',
              'CONTENT_LENGTH':str(len(prefix)+size+len(suffix)), 'CONTENT_TYPE':'multipart/form-data; boundary='+boundary}
    packed = b''
    for key, value in params.items():
        a, b = key.encode(), value.encode()
        packed += length(len(a)) + length(len(b)) + a + b
    expected = hashlib.sha256()
    with socket.create_connection(('127.0.0.1',port),timeout=35) as sock:
        sock.sendall(record(1,struct.pack('!HB5s',1,0,b'\0'*5))+record(4,packed)+record(4)+record(5,prefix))
        remaining = size
        while remaining:
            data = chunk[:min(remaining,len(chunk))]
            expected.update(data)
            sock.sendall(record(5,data))
            remaining -= len(data)
        sock.sendall(record(5,suffix)+record(5))
        stdout,stderr = b'',b''
        while True:
            version,kind,rid,count,padding,reserved=struct.unpack('!BBHHBB',exact(sock,8))
            content=exact(sock,count)
            if padding:exact(sock,padding)
            if kind==6:stdout+=content
            elif kind==7:stderr+=content
            elif kind==3:break
    assert not stderr, stderr.decode('utf-8','replace')
    result=json.loads(stdout.decode().split('\r\n\r\n',1)[1])
    assert result['file']['size']==size and result['file']['error']==0
    assert result['file']['sha256']==expected.hexdigest()
    assert result['peak']<32*1024*1024 and proc.poll() is None
    assert result['progress'] is False
    report={'passed':True,'transport':'loopback native FastCGI; no Nginx or business application',
            'upload_bytes':size,'sha256':expected.hexdigest(),'same_worker_alive':True,
            'php_memory_limit':'32M','peak_php_allocated_bytes':result['peak'],
            'session_progress_callback_disabled':True,'covers_business_upload_500':False}
    (ROOT/'logs/large-upload-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
    print(json.dumps(report,indent=2))
finally:
    if proc.poll() is None:
        proc.terminate()
        proc.wait(timeout=5)
    stream.close()
