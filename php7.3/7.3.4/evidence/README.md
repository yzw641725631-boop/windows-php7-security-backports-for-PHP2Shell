# Validation evidence / 验证记录

## 中文

安装器 v2 的隔离检查和旧 API 编译检查另记在 `legacy-installer-verification.json`。它不重新验证 PHP 引擎：实际宿主仍为 Windows 11 / PowerShell 5.1，辅助进程捕获类通过 C# 2 / .NET 2.0 引用程序集编译检查；真正的 PowerShell 2.0 运行时无法在本机执行。用户报告 Server 2008 R2 SP1 上补丁 CLI 启动成功，但旧系统完整安装/业务验证未完成。

本目录保存本机构建阶段的记录，不是第三方安全认证。`records/` 中将构建工作区、引导 PHP 与用户目录的绝对路径替换为占位符；数值、状态、输出和用例名称保持原样。因此这里的日志不是原始日志的字节级副本。

| 文件 | 内容与结论 |
| --- | --- |
| `port-manifest.json` | 构建规格、范围和限制摘要 |
| `source-port-mapping.json` | 111 个上游非测试代码映射条目；45 版本适配、56 上下文移植、9 不适用、1 重新生成 |
| `records/source-reproduction.json` | 114 个更改文件通过统一补丁和校验替换两种方式复现，并与构建输入匹配 |
| `records/optimized-build-status.json` / `build-optimized-01.log` | 历史优化构建退出码 0，`/O2 /Ob2` 与 `/d2SSAOptimizer-` |
| `records/candidate-verification.json` | 核心、常用扩展、部分第三方扩展加载、普通上传与原生 FastCGI 检查 |
| `records/soft-oom-verification.json` | 11 场景 × 普通/OPcache 两模式 × 10 轮 = 220 次有界软 OOM 检查；后续请求使用同一 PID，硬限制另进程退出码 137 |
| `records/upstream-case-probe.json` | 228 个 PHP 8.2 PHPT 的有界比较：139 匹配、17 输出差异、14 语法不兼容、57 未运行、1 超时 |
| `records/targeted-followup.json` | 特定回溯、异常和流/多字节函数的补充记录；不是全路径覆盖 |
| `records/package-verification.json` | 原运行包 ZIP CRC、83 个清单文件哈希及解压后的版本检查 |
| `records/deployment-verification.json` | Windows PowerShell 5.1 下 12 项隔离安装/回滚检查 |

完整上游测试框架、独立内存检查器/安全审计和漏洞利用回归认证均未执行。XML 大属性比较用例超时仍需处理；PHP 8 语法/API 差异不等同于安全问题已经逐项排除。Windows Server 2019、IIS、实际 ThinkPHP 应用和大文件上传路径没有完整验证。第三方扩展的加载检查不能证明其全部 ABI 或内存处理路径兼容。

安装检查使用实际 CIM 进程信息，但在非管理员测试进程中只选择隔离目录内可见的测试进程；未知路径拒绝逻辑另行模拟。正式脚本没有绕过进程检查的开关。仓库发布前对公共路径改造和打包的检查另记在 `publication-verification.json`（生成后提供），不将历史记录冒充本次重新运行的完整测试。

## English

Installer-v2 observations are recorded separately in `legacy-installer-verification.json`. They do not retest or certify the PHP engine: execution used Windows 11 / PowerShell 5.1, while the capture helper compiled as C# 2 against .NET 2.0 reference assemblies. The actual PowerShell 2.0 engine is unavailable on this host. A user-reported patched CLI startup on Server 2008 R2 SP1 does not complete installer/business validation.

These are local build-time observations, not third-party certification. Absolute build-workspace, bootstrap-PHP and user-profile paths in `records/` were replaced with placeholders; values, statuses, outputs and case names are otherwise retained. Redacted logs are not byte-identical copies of the originals.

- `port-manifest.json` and `source-port-mapping.json` describe the target, limitations and 111 upstream mapping entries (45 version adaptations, 56 context ports, 9 not applicable, 1 regenerated).
- Source reproduction records show 114 changed files matched the build input using both unified-patch application and checked replacement copying.
- The historical optimized build completed with exit code 0 using `/O2 /Ob2` and `/d2SSAOptimizer-`.
- Core/common extensions, selected third-party extension loading, ordinary uploads and native FastCGI were checked.
- The soft-OOM record covers 11 cases × two modes × ten cycles = 220 checks; the same PID handled follow-up requests. A separate hard-limit process exited with code 137.
- The bounded comparison of 228 PHP 8.2 PHPTs recorded 139 matching outputs, 17 differences, 14 syntax incompatibilities, 57 not run and one timeout.
- Runtime packaging checked ZIP CRC, 83 manifest-file hashes and the extracted version. Twelve isolated installer/rollback checks ran under Windows PowerShell 5.1.

The complete upstream harness, an independent memory-safety audit and exploit-regression certification were not performed. The XML large-attribute timeout remains unresolved. Windows Server 2019, IIS, target ThinkPHP applications and large-file upload paths lack complete validation. Third-party extension load checks do not prove complete ABI or OOM-path compatibility.

Installer test CIM inventory was limited to visible disposable-fixture processes on the non-admin test host; unknown-path rejection was simulated separately. The production scripts have no process-check bypass parameter. Checks of the public path adaptations and packages are recorded separately in `publication-verification.json` when generated; historical results are not presented as a new full test run.
