# Validation / 验证

## 中文

这些记录来自 Windows 11 本机；工作区、引导运行目录与用户目录路径替换成占位符，日志不是原字节副本。

| 记录 | 结论 |
| --- | --- |
| `source-changes.json`（在 `../source/`） | 精确官方补丁修改 17 个文件，前后哈希可检查 |
| `records/source-reproduction.json` | 官方补丁重新应用到干净输入，与编译输入更改文件一致 |
| `records/build-status.json` / `records/build-06.log` | 全量 `/O2 /Ob0 /d2SSAOptimizer-` 构建成功；生成 Makefile 去除 `/d2FuncCache1`；历史数值转换/缺少依赖 PDB 等警告保留 |
| `records/stage-manifest.json` | 同次重建 44 个 EXE/DLL，补入 15 个依赖 DLL，无必需静态导入缺失；Firebird 外部客户端单独注明 |
| `records/candidate-verification.json` | 核心、常用扩展、HTTP 上传、分段限制与 Session 上传进度回调停用检查 |
| `records/official-mitigation-verification.json` | 22 个 OOM 场景（普通/OPcache 各 11）：工作进程退出码 1，不继续业务和普通 shutdown 回调 |
| `records/large-upload-verification.json` | 260 MiB 流式上传、32 MiB PHP 内存限额、文件 SHA-256 匹配、PHP 峰值分配约 2 MiB、进程存活 |
| `records/deployment-verification.json` | Windows PowerShell 5.1 隔离安装、配置/自定义扩展文件保留、拒绝活动进程/损坏包、失败恢复与回滚检查 |

普通 FastCGI 检查还验证三次请求和上传哈希。大文件检查只经过回环 FastCGI，不经过 Nginx 或 ThinkPHP，不证明业务 500 已解决。测试里的原始 DLL 自定义副本用于验证扩展文件保留和加载，不代表全面测试实际第三方扩展。

没有完整上游测试、独立安全审计、内存检查器审计或利用回归认证。Windows Server 2019、phpStudy 的守护/补进程机制、实际应用兼容性和所有扩展 OOM 路径未完整验证。不得把“编译成功”或“退出码符合预期”等同于这些保证。

## English

Records were produced locally on Windows 11. Build/baseline/profile paths are replaced with placeholders, so published logs are not byte-identical originals.

The exact upstream patch changes 17 files and replays to the recorded build inputs. The complete build succeeded with `/O2 /Ob0 /d2SSAOptimizer-` and generated-Makefile removal of `/d2FuncCache1`; historical conversion and dependency-debug-symbol warnings remain visible. Staging records 44 rebuilt binaries, 15 dependency DLL additions and no required static-import gaps, with an optional Firebird client dependency noted separately.

Checks cover core/common extensions, ordinary HTTP/native FastCGI uploads, multipart limits and disabled Session progress. Twenty-two OOM cases (11 plain, 11 OPcache) exited the worker with code 1 without continuing business/shutdown callbacks. The 260 MiB streamed upload under a 32 MiB PHP memory limit matched SHA-256, used about 2 MiB peak PHP allocation and retained the worker. It bypasses Nginx and actual application code, so it does not resolve reported business HTTP 500 errors.

Isolated Windows PowerShell 5.1 installer tests cover preservation, rejection, recovery and rollback. A renamed baseline extension DLL is a file/loading fixture, not a comprehensive third-party-extension assessment.

No complete upstream harness, independent security/memory audit or exploit-regression certification was performed. Windows Server 2019, phpStudy supervision, application compatibility and all extension OOM paths remain unverified. Build success and expected exits are not substitutes for those guarantees.
