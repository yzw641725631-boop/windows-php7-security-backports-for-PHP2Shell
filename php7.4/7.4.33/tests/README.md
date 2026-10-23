# Local checks / 本机检查

## 中文

Python 3 标准库脚本只启动自己管理的回环 PHP 进程，不访问线上站点、不停止现有服务。OOM 检查会故意终止它自己启动的工作进程。将本版本运行包解压到版本目录 `stage/`，把官方干净的 7.4.33 Windows 原版解压到 `baseline/`，然后在版本目录执行：

```powershell
python .\tests\verify_candidate.py
python .\tests\verify_fastcgi.py
python .\tests\verify_upstream_mitigation.py
python .\tests\verify_large_upload.py
```

按上面顺序运行。日志和 fixture 写入忽略的 `logs/`、`verification/`。大文件检查会写约 260 MiB 临时文件并自动由 PHP 清理正常上传临时文件，需要额外空间。`verify_upstream_mitigation.py` 包含有界 PHP 片段，本目录没有把 7.3 延迟 OOM 测试冒充 7.4 行为。

## English

Python 3 standard-library tools launch only their own loopback workers, never contact production and do not stop existing services. OOM checks intentionally terminate their own workers. Extract this runtime into `stage/` and a pristine official Windows 7.4.33 baseline into `baseline/`, then run the commands above in order.

Logs and fixtures use ignored directories. The large-upload test needs over 260 MiB temporary disk space; normal upload temporary files are cleaned by PHP. Bounded OOM snippets are included in the 7.4 mitigation tool; the 7.3 delayed-OOM expectations are not reused as 7.4 claims.
