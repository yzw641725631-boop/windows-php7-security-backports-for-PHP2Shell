"""Exercise the built php-cgi.exe over local FastCGI with bounded requests."""
from pathlib import Path
import hashlib
import json
import os
import socket
import struct
import subprocess
import time
from verify_candidate import ROOT, BUILD, CASE_DIR, LOGS, multipart


def record(kind, payload=b""):
    return struct.pack("!BBHHBB", 1, kind, 1, len(payload), 0, 0) + payload


def length(value):
    return bytes([value]) if value < 128 else struct.pack("!I", value | 0x80000000)


def exact(sock, count):
    result = b""
    while len(result) < count:
        chunk = sock.recv(count - len(result))
        if not chunk:
            raise RuntimeError("FastCGI connection ended early")
        result += chunk
    return result


def request(port, params, body=b""):
    packed = b""
    for key, value in params.items():
        key, value = key.encode(), value.encode()
        packed += length(len(key)) + length(len(value)) + key + value
    with socket.create_connection(("127.0.0.1", port), timeout=15) as sock:
        wire = record(1, struct.pack("!HB5s", 1, 0, b"\0" * 5)) + record(4, packed) + record(4)
        for start in range(0, len(body), 60000):
            wire += record(5, body[start:start + 60000])
        sock.sendall(wire + record(5))
        stdout, stderr = b"", b""
        while True:
            version, kind, request_id, size, padding, reserved = struct.unpack("!BBHHBB", exact(sock, 8))
            data = exact(sock, size)
            if padding:
                exact(sock, padding)
            if kind == 6:
                stdout += data
            elif kind == 7:
                stderr += data
            elif kind == 3:
                app_status, protocol_status = struct.unpack("!IB", data[:5])
                assert app_status == protocol_status == 0
                break
    headers, text = stdout.decode("utf-8").split("\r\n\r\n", 1)
    assert not stderr, stderr.decode("utf-8", "replace")
    return headers, json.loads(text)


def main():
    binary = BUILD / "php-cgi.exe"
    version = subprocess.run([str(binary), "-n", "-v"], capture_output=True, text=True, encoding="utf-8", cwd=BUILD)
    assert version.returncode == 0 and "7.3.4 (cgi-fcgi)" in version.stdout
    with socket.socket() as sock:
        sock.bind(("127.0.0.1", 0))
        port = sock.getsockname()[1]
    sessions = CASE_DIR / "fastcgi-sessions"
    sessions.mkdir(exist_ok=True)
    env = os.environ.copy()
    env["PHP_FCGI_MAX_REQUESTS"] = "8"
    env["PHP_FCGI_CHILDREN"] = "0"
    stream = (LOGS / "fastcgi-server.log").open("w", encoding="utf-8")
    args = [str(binary), "-n", "-d", "session.save_path=" + str(sessions),
            "-d", "session.upload_progress.enabled=1", "-d", "session.upload_progress.cleanup=0",
            "-d", "display_errors=0", "-b", "127.0.0.1:" + str(port)]
    proc = subprocess.Popen(args, cwd=BUILD, env=env, stdout=stream, stderr=stream,
                            creationflags=subprocess.CREATE_NO_WINDOW)
    try:
        for attempt in range(100):
            assert proc.poll() is None, "FastCGI process stopped before readiness"
            try:
                with socket.create_connection(("127.0.0.1", port), timeout=0.1):
                    break
            except OSError:
                time.sleep(0.1)
        else:
            raise RuntimeError("FastCGI did not listen")
        params = {"GATEWAY_INTERFACE": "CGI/1.1", "SERVER_SOFTWARE": "php734-local-validation",
                  "REQUEST_METHOD": "GET", "SCRIPT_FILENAME": str(CASE_DIR / "probe.php"),
                  "SCRIPT_NAME": "/probe.php", "QUERY_STRING": "", "REQUEST_URI": "/probe.php",
                  "SERVER_PROTOCOL": "HTTP/1.1", "SERVER_NAME": "localhost", "SERVER_PORT": "80",
                  "REMOTE_ADDR": "127.0.0.1", "REMOTE_PORT": "40000", "REDIRECT_STATUS": "200"}
        headers, first = request(port, params)
        cookie = next(line.split(":", 1)[1].strip().split(";", 1)[0] for line in headers.split("\r\n")
                      if line.lower().startswith("set-cookie:"))
        fixture = b"fastcgi-upload" * 1000
        body, content_type = multipart([("PHP_SESSION_UPLOAD_PROGRESS", "guardcheck"), ("name", "fastcgi")], fixture)
        post = dict(params, REQUEST_METHOD="POST", CONTENT_LENGTH=str(len(body)), CONTENT_TYPE=content_type, HTTP_COOKIE=cookie)
        _, second = request(port, post, body)
        assert second["post"]["name"] == "fastcgi"
        assert second["upload_size"] == len(fixture) and second["upload_error"] == 0
        assert second["upload_sha256"] == hashlib.sha256(fixture).hexdigest()
        assert second["session_progress_present"] is True
        _, third = request(port, dict(params, HTTP_COOKIE=cookie))
        assert third["session_progress_present"] is True and proc.poll() is None
        outcome = {"status": "passed", "transport": "native Windows php-cgi FastCGI over loopback",
                   "requests": 3, "single_worker_survived": True,
                   "normal_upload_hash_verified": True, "session_upload_progress_retained": True,
                   "cgi_version": version.stdout.strip(), "not_an_rce_exploit_test": True}
        report_path = LOGS / "candidate-verification.json"
        report = json.loads(report_path.read_text())
        report["tests"]["native_fastcgi"] = outcome
        report_path.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
        print(json.dumps(outcome, indent=2))
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=6)
        except subprocess.TimeoutExpired:
            proc.kill()
            proc.wait(timeout=3)
        stream.close()


if __name__ == "__main__":
    main()
