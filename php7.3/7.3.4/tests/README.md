# Local regression tools / 本机回归工具

## 中文

这些脚本面向 Windows 隔离测试机，使用 Python 3 标准库，只监听回环地址；不会连接你的线上网站或停止现有服务。OOM 用例会故意让脚本自己启动的 PHP 请求失败，硬限制用例会让自己的工作进程退出。

1. 将 `dist/` 中原运行包解压到版本目录下的 `stage/`，使 `stage/php.exe` 存在。此目录被 Git 忽略。
2. 准备**另一个**干净的 PHP 7.3.4 运行目录作为比较基线，保持它与 `stage/` 分开。
3. 在本版本目录打开 PowerShell，执行：

```powershell
$env:PHP73_BASELINE_PHP = 'C:\php73-original\php.exe'
python .\tests\verify_candidate.py
python .\tests\verify_fastcgi.py
python .\tests\verify_soft_oom.py --cycles 10
# 可选：运行有已知差异/超时的有界上游比较
python .\tests\verify_upstream_cases.py
```

先运行 candidate，生成普通上传 fixture，再运行 FastCGI。日志和临时用例留在版本目录的 `logs/`、`verification/`、`soft-oom-cases/`、`upstream-case-work/`，均被 Git 忽略。上游 `tests/upstream-tests/` 保留原 PHPT，本机比较脚本不是完整 `run-tests.php` 框架。

仓库中的公共脚本只调整了原本机脚本的根目录、基线路径和日志目录创建。历史结果在 `../evidence/records/`，公共脚本的发布前检查在 `../evidence/publication-verification.json`；不要把本机检查视为完整漏洞利用回归认证。

## English

These Python 3 standard-library tools are intended for isolated Windows test hosts. They bind only to loopback, do not contact production websites and do not stop existing services. OOM cases intentionally fail requests in workers they launch; the hard-limit case intentionally terminates its own worker.

Extract the original runtime ZIP into this version directory's ignored `stage/` folder. Set `PHP73_BASELINE_PHP` to a separate pristine PHP 7.3.4 executable. Run candidate first to prepare upload fixtures, then FastCGI and the soft-OOM checks, using the commands above. The upstream comparison is optional and has known output differences and a timeout.

Results and fixtures are written to ignored local directories. PHPT files under `upstream-tests/` are retained from upstream; this comparison is not the complete PHP test harness. Public scripts adapt workspace discovery, baseline selection and log-directory creation from the original local tools. Historical and publication-time evidence are kept separate. None of these checks is complete exploit-regression certification.
