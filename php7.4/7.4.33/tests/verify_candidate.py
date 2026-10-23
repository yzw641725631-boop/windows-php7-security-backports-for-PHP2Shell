"""Run bounded local functional checks against the candidate and original PHP."""
from contextlib import contextmanager
from pathlib import Path
import hashlib
import http.client
import json
import os
import socket
import subprocess
import time
import urllib.parse

ROOT = Path(__file__).resolve().parents[1]
BUILD = ROOT / "stage"
BASELINE = ROOT / "baseline/php.exe"
LOGS = ROOT / "logs"
CASE_DIR = ROOT / "verification"
LOGS.mkdir(parents=True, exist_ok=True)


def run_php(binary, code, options=(), timeout=25):
    args = [str(binary), "-n", *options, "-r", code]
    result = subprocess.run(args, cwd=binary.parent, capture_output=True, timeout=timeout,
                            text=True, encoding="utf-8", errors="replace")
    return {"exit_code": result.returncode, "stdout": result.stdout, "stderr": result.stderr}


@contextmanager
def local_server(binary, label, extra=()):
    session_dir = CASE_DIR / (label + "-sessions")
    session_dir.mkdir(exist_ok=True)
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
    error_stream = (LOGS / (label + "-http-server.log")).open("w", encoding="utf-8")
    args = [str(binary), "-n", "-d", "session.save_path=" + str(session_dir),
            "-d", "session.upload_progress.enabled=1", "-d", "session.upload_progress.cleanup=0",
            "-d", "display_errors=0", "-d", "log_errors=1", *extra,
            "-S", "127.0.0.1:" + str(port), "-t", str(CASE_DIR)]
    proc = subprocess.Popen(args, cwd=binary.parent, stdout=error_stream, stderr=error_stream,
                            creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        for attempt in range(80):
            if proc.poll() is not None:
                raise RuntimeError("PHP local server exited before readiness: " + label)
            try:
                with socket.create_connection(("127.0.0.1", port), timeout=0.2):
                    break
            except OSError:
                time.sleep(0.1)
        else:
            raise RuntimeError("PHP local server did not start")
        yield port
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=8)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=5)
        error_stream.close()


def request(port, method, path, body=None, headers=None):
    conn = http.client.HTTPConnection("127.0.0.1", port, timeout=20)
    try:
        conn.request(method, path, body=body, headers=headers or {})
        response = conn.getresponse()
        return response.status, dict(response.getheaders()), response.read().decode("utf-8", "replace")
    finally:
        conn.close()


def multipart(fields, upload=None):
    boundary = "php7433functional" + os.urandom(8).hex()
    parts = []
    for name, value in fields:
        parts.append(("--" + boundary + '\r\nContent-Disposition: form-data; name="' + name +
                      '"\r\n\r\n' + value + "\r\n").encode("utf-8"))
    if upload is not None:
        parts.append(("--" + boundary + '\r\nContent-Disposition: form-data; name="upload"; filename="fixture.bin"\r\n'
                      "Content-Type: application/octet-stream\r\n\r\n").encode() + upload + b"\r\n")
    parts.append(("--" + boundary + "--\r\n").encode())
    return b"".join(parts), "multipart/form-data; boundary=" + boundary


def main():
    CASE_DIR.mkdir(exist_ok=True)
    probe = '''<?php
session_start();
header('Content-Type: application/json');
$upload = isset($_FILES['upload']) ? $_FILES['upload'] : null;
echo json_encode([
 'post' => $_POST, 'post_count' => count($_POST),
 'upload_size' => $upload ? $upload['size'] : null,
 'upload_error' => $upload ? $upload['error'] : null,
 'upload_sha256' => $upload && $upload['error'] === 0 ? hash_file('sha256', $upload['tmp_name']) : null,
 'session_progress_present' => isset($_SESSION['upload_progress_guardcheck']),
 'upload_progress_ini' => ini_get('session.upload_progress.enabled'),
 'multipart_limit_ini' => ini_get('max_multipart_body_parts')
]);
'''
    (CASE_DIR / "probe.php").write_text(probe, encoding="ascii", newline="\n")
    binary = BUILD / "php.exe"
    report = {"candidate": str(binary), "baseline": str(BASELINE),
              "host_os": "local Windows build host; Windows Server 2019 execution not yet verified",
              "tests": {}, "rce_reproduction": "not performed; these are functional and targeted mitigation checks"}
    metadata_code = 'echo json_encode(["version"=>PHP_VERSION,"version_id"=>PHP_VERSION_ID,"zts"=>PHP_ZTS,"int_size"=>PHP_INT_SIZE,"sapi"=>PHP_SAPI]);'
    metadata = run_php(binary, metadata_code)
    assert metadata["exit_code"] == 0 and not metadata["stderr"], metadata
    values = json.loads(metadata["stdout"])
    assert values == {"version": "7.4.33", "version_id": 70433, "zts": 0, "int_size": 8, "sapi": "cli"}, values
    report["metadata"] = values
    smoke_code = '''$a=["msg"=>"ok","nested"=>[1,2,3]]; if(json_decode(json_encode($a),true)!==$a) exit(1);
$s=""; for($i=0;$i<500;$i++)$s.="x"; if(strlen($s)!==500)exit(2);
if(preg_match("/^[a-z]+$/","hello")!==1)exit(3);
if(gzdecode(gzencode("roundtrip"))!=="roundtrip")exit(4);
if(iconv("UTF-8","UTF-8","hello")!=="hello")exit(5);
if((new ReflectionClass("Exception"))->getName()!=="Exception")exit(6);
echo "core-smoke-ok";'''
    core = run_php(binary, smoke_code)
    assert core["exit_code"] == 0 and core["stdout"] == "core-smoke-ok" and not core["stderr"], core
    report["tests"]["core_operations"] = core
    addon_names = ["curl", "openssl", "mbstring", "gd2", "fileinfo", "mysqli", "pdo_mysql", "pdo_sqlite", "sqlite3", "intl", "soap", "sodium", "sockets"]
    options = ["-d", "extension_dir=" + str(BUILD / "ext")]
    for name in addon_names:
        options.extend(["-d", "extension=php_" + name + ".dll"])
    options.extend(["-d", "zend_extension=" + str(BUILD / "ext/php_opcache.dll")])
    addon_code = '''$db=new PDO("sqlite::memory:");$db->exec("create table t(n integer)");$db->exec("insert into t values(73)");
if($db->query("select n from t")->fetchColumn()!=73)exit(1);
if(mb_strlen("hello","UTF-8")!==5)exit(2);
$im=imagecreatetruecolor(2,2);if(!$im)exit(3);imagedestroy($im);
$cipher=openssl_encrypt("probe","aes-128-cbc","0123456789abcdef",0,"0123456789abcdef");
if(openssl_decrypt($cipher,"aes-128-cbc","0123456789abcdef",0,"0123456789abcdef")!=="probe")exit(4);
if(!curl_version()||!class_exists("mysqli")||!class_exists("Normalizer")||!class_exists("SoapClient"))exit(5);
echo json_encode(["extensions"=>get_loaded_extensions(),"zend_extensions"=>get_loaded_extensions(true),"result"=>"extensions-ok"]);'''
    addon = run_php(binary, addon_code, options)
    assert addon["exit_code"] == 0 and not addon["stderr"], addon
    assert json.loads(addon["stdout"])["result"] == "extensions-ok"
    report["tests"]["bundled_extensions"] = addon
    third_party = {}
    for name in ("redis", "sqlsrv", "pdo_sqlsrv", "xdebug"):
        path = BASELINE.parent / "ext" / ("php_" + name + ".dll")
        if name in ("sqlsrv", "pdo_sqlsrv"):
            path = BASELINE.parent / "ext" / ("php_" + name + "_73_nts.dll")
        if not path.exists():
            third_party[name] = {"status": "not present locally"}
            continue
        key = "zend_extension" if name == "xdebug" else "extension"
        result = run_php(binary, 'echo "load-ok";', ["-d", key + "=" + str(path)])
        third_party[name] = result
        assert result["exit_code"] == 0 and result["stdout"] == "load-ok" and not result["stderr"], (name, result)
    report["tests"]["existing_phpstudy_addon_loads"] = third_party
    fixture = (b"php7433-upload-probe\x00\xff" * 7000)
    uploads = {}
    for label, executable in (("original", BASELINE), ("patched", binary)):
        with local_server(executable, label) as port:
            status, headers, text = request(port, "GET", "/probe.php")
            assert status == 200
            cookie = headers.get("Set-Cookie", "").split(";", 1)[0]
            assert cookie.startswith("PHPSESSID=")
            fields = [("PHP_SESSION_UPLOAD_PROGRESS", "guardcheck"), ("name", "normal"), ("meta[k]", "nested")]
            body, content_type = multipart(fields, fixture)
            status, _, text = request(port, "POST", "/probe.php", body, {"Content-Type": content_type, "Cookie": cookie})
            data = json.loads(text)
            assert status == 200 and data["upload_error"] == 0 and data["upload_size"] == len(fixture)
            assert data["upload_sha256"] == hashlib.sha256(fixture).hexdigest()
            assert data["post"]["meta"]["k"] == "nested"
            uploads[label] = data
        with local_server(executable, label + "-limit", ["-d", "max_multipart_body_parts=3"]) as port:
            body, content_type = multipart([(str(i), "value") for i in range(6)])
            status, _, text = request(port, "POST", "/probe.php", body, {"Content-Type": content_type})
            data = json.loads(text)
            assert status == 200
            report["tests"][label + "_multipart_limit"] = data
        oom = run_php(executable, 'register_shutdown_function(function(){echo "SHUTDOWN-RAN";}); $s=str_repeat("x",64*1024*1024);',
                      ["-d", "memory_limit=16M", "-d", "display_errors=0", "-d", "log_errors=1"])
        assert oom["exit_code"] != 0 and ("Allowed memory size" in oom["stderr"] or "Hard memory limit" in oom["stderr"]), oom
        report["tests"][label + "_oom_shutdown"] = oom
    assert uploads["original"]["session_progress_present"] is True
    assert uploads["patched"]["session_progress_present"] is False
    assert report["tests"]["original_multipart_limit"]["post_count"] == 6
    assert report["tests"]["patched_multipart_limit"]["post_count"] == 3
    assert "SHUTDOWN-RAN" in report["tests"]["original_oom_shutdown"]["stdout"]
    assert "SHUTDOWN-RAN" not in report["tests"]["patched_oom_shutdown"]["stdout"]
    assert report["tests"]["patched_oom_shutdown"]["exit_code"] == 1
    report["tests"]["normal_http_upload_and_disabled_progress_callback"] = uploads
    report["status"] = "passed"
    (LOGS / "candidate-verification.json").write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps({"status": "passed", "version": values, "checks": list(report["tests"]),
                      "report": str(LOGS / "candidate-verification.json"),
                      "rce_reproduction": report["rce_reproduction"]}, indent=2))


if __name__ == "__main__":
    main()
