# PHP 7.4.33 — Windows x64 / NTS / VC15

[中文](#中文) · [English](#english) · [Repository / 仓库](../../README.md)

## 中文

本版本从干净的 **PHP 7.4.33 官方源码**出发，完整应用 PHP 团队专为 7.4 提供的提交 [`712e60f9edfd03f0960fc4fc3c2c375f42b90aa2`](https://github.com/php/php-src/commit/712e60f9edfd03f0960fc4fc3c2c375f42b90aa2)，再编译成 Windows x64 / NTS / VC15 运行包。修复针对 PHP2Shell（CVE-2026-109618 / CVE-2026-109619）。

**源码补丁来自 PHP 官方，Windows 二进制是本项目的非官方构建，并非 PHP 官方 Windows 安全发行版。** 没有将本仓库 7.3.4 的 PHP 8.2 延迟 OOM 移植混入 7.4。

### 下载

- [完整 PHP 运行包](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.4.33-php2shell-20261023-rc1/php-7.4.33-nts-Win32-VC15-x64-unofficial-upstream-backport-20261023.zip)
- [phpStudy 一键安装包](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.4.33-php2shell-20261023-rc1/phpStudy-PHP-7.4.33-nts-VC15-x64-unofficial-backport-install-kit-20261023.zip)
- [SHA-256 清单](dist/SHA256SUMS.txt) · [安装/回滚](installer/README.md) · [构建](build/README.md) · [验证记录](evidence/README.md)

### 与 7.3.4 移植包的区别

| 项目 | 本版本 7.4.33 | 本仓库 7.3.4 |
| --- | --- | --- |
| 修复依据 | 官方 7.4 专用最小缓解补丁 | 非官方移植 PHP 8.2 的较大改造 |
| OOM | 退出当前 PHP 工作进程 | 普通软 OOM 尽量仅结束请求，硬限制仍退出进程 |
| Session 上传进度回调 | 停用，即使 INI 显示开启 | 保留并改造初始化反序列化 |
| 普通文件上传 | 保留 | 保留 |
| `max_multipart_body_parts` | 有，默认 `-1` 为自动计算 | 有 |
| `memory_hard_limit_percent` | 没有 | 有 |

工作进程退出后能否补充，由 phpStudy / FastCGI 管理器负责；不保证整个站点始终可用。补丁停用的是 Session 上传进度回调，并非禁止 `$_FILES` 上传。依赖该回调展示实时上传进度的应用需要调整。

### 构建和源码

- 版本保持 **7.4.33**，构建日期为 2026-10-23；PHP API 为 20190902。
- 官方补丁逐字节保留，完整更改 **17 个源码文件**，没有修改其中的实现逻辑。源码前后 SHA-256、补丁哈希和来源在 `source/source-changes.json`。
- 原始源码包 `php-7.4.33.tar.xz` SHA-256：`924846abf93bc613815c55dd3f5809377813ac62a9ec4eb3778675b82a27b927`。
- VC15 19.16.27054，Windows SDK 10.0.26100.0。该旧编译器在内联优化时发生内部错误，最终使用 **`/O2 /Ob0 /d2SSAOptimizer-`** 并从生成的 Makefile 移除 `/d2FuncCache1`，没有更改 PHP 源码来绕过编译。`/Ob0` 禁用内联扩展，尚未做性能对比，不宣称性能与官方原版完全相同。
- 同次构建的核心和内置扩展配套分发。历史第三方库来自对应 VC15 x64 依赖系列，不意味着它们获得了全面安全更新。

在独立的干净源码目录中，可二选一：

```powershell
python .\source\apply_source_patch.py --source C:\lab\php-7.4.33
# 或在干净源码目录 git apply --check 后应用 patches/ 内的官方补丁
```

### 安装和配置

自动安装脚本仅接受 **现有 PHP 7.4.33 / NTS / VC15 / x64**。不要直接把它用于 PHP 7.3、TS、x86 或其他 7.4.x。若需要从旧 7.4.x 升级，请单独准备新目录、迁移配置和匹配扩展并验证业务；此脚本不代替升级评估。

先停 phpStudy 服务，再以管理员身份运行 `Install.cmd`，输入当前 `php7.4.33nts` 目录。原 `php.ini`、自装扩展、自定义文件和旧目录备份保留，新版仍放在原路径。脚本不会自动停止/启动服务，不强杀进程。安装后验证网站与 API；回滚使用 `Rollback.cmd`。

旧 `php.ini` 可以继续使用，新增分段限制使用内置默认值，不必额外添加。**不要照搬 7.3.4 的 `memory_hard_limit_percent` 配置来判断本版本是否有补丁**；本版本没有这个指令。网站可用 `ini_get_all()` 检查 `max_multipart_body_parts` 是否存在，但这不能代替完整文件哈希校验。

### 验证与限制

本机验证宿主是 Windows 11，目标 Windows Server 2019 / phpStudy / ThinkPHP 项目没有完整实机验证。记录了核心、常用扩展、普通 HTTP / 原生 FastCGI 上传、分段限制、22 个有界 OOM 退出场景（普通/OPcache 各 11 个）。单独使用 32 MiB PHP 内存限制，通过回环 FastCGI 成功流式上传 **260 MiB** 文件并核对 SHA-256，进程仍存活；该测试不经过 Nginx 或实际业务代码，不证明你的大文件 500 已解决。

这不是独立安全审计、完整上游测试或漏洞利用回归认证。未保证所有第三方扩展、旧依赖和业务路径兼容。请先在测试环境验证，并保留完整备份。安装脚本的实际隔离检查结果见 `evidence/`。

## English

This build applies the PHP team's **7.4-specific upstream commit [`712e60f`](https://github.com/php/php-src/commit/712e60f9edfd03f0960fc4fc3c2c375f42b90aa2)** to pristine PHP 7.4.33, then compiles a Windows x64 / NTS / VC15 runtime for PHP2Shell (CVE-2026-109618 / CVE-2026-109619).

**The source patch is upstream; the Windows binaries are unofficial project builds, not official PHP Windows security releases.** This does not include the PHP 8.2 delayed-OOM engine port used by this repository's PHP 7.3.4 build.

### Downloads

- [Complete runtime](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.4.33-php2shell-20261023-rc1/php-7.4.33-nts-Win32-VC15-x64-unofficial-upstream-backport-20261023.zip)
- [phpStudy installer kit](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.4.33-php2shell-20261023-rc1/phpStudy-PHP-7.4.33-nts-VC15-x64-unofficial-backport-install-kit-20261023.zip)
- [SHA-256](dist/SHA256SUMS.txt), [installation/rollback](installer/README.md), [build guide](build/README.md), [evidence](evidence/README.md).

### Behavior and scope

The exact upstream minimal mitigation terminates the current worker on OOM and disables the Session upload-progress callback even if its INI flag remains enabled. **Ordinary file uploads remain supported.** Applications relying on this callback for real-time progress need adjustment. Worker replacement depends on the process manager and uninterrupted availability is not guaranteed.

`max_multipart_body_parts` exists and defaults to automatic calculation (`-1`). **`memory_hard_limit_percent` is absent**; its presence must not be used to identify this build. The PHP 7.3.4 port has different OOM/progress behavior, as shown in the comparison table above.

### Build provenance

PHP remains 7.4.33, build date 2026-10-23, module API 20190902. The unchanged upstream patch modifies 17 source files. Before/after hashes and provenance are recorded in `source/source-changes.json`. The pristine source SHA-256 is `924846abf93bc613815c55dd3f5809377813ac62a9ec4eb3778675b82a27b927`.

The build uses VC15 19.16.27054 and Windows SDK 10.0.26100.0. An internal compiler failure with inlining required **`/O2 /Ob0 /d2SSAOptimizer-`** plus removal of `/d2FuncCache1` from the generated Makefile; no upstream PHP implementation was changed for this workaround. `/Ob0` disables inline expansion. Performance equivalence to the original vendor binaries has not been benchmarked.

Core and bundled extensions are supplied from the same build with their matched dependency DLLs. Historical libraries do not receive a comprehensive security update from this patch. Apply either the checked replacement script or unified upstream patch to a separate pristine source tree, then follow the build guide.

### Installation and validation

The automatic installer accepts **existing PHP 7.4.33 / NTS / VC15 / x64 only**, not PHP 7.3, TS, x86 or another 7.4.x release. Upgrading an older minor release needs a separate directory, configuration/add-on migration and application validation; this script does not perform that assessment.

Stop phpStudy services, run `Install.cmd` as Administrator and enter the current PHP directory. It preserves configuration, add-ons and a full original-directory backup, and keeps the active installation at the same path. Scripts do not control services or forcibly terminate workers. Use `Rollback.cmd` after stopping services to restore the snapshot.

Recorded checks ran on Windows 11, not a fully validated Windows Server 2019/phpStudy/ThinkPHP deployment. They cover core/common extensions, ordinary HTTP/native FastCGI uploads, multipart-part limits and 22 bounded OOM worker exits (11 plain and 11 OPcache cases). A separate loopback FastCGI test streamed a **260 MiB** file under a 32 MiB PHP memory limit, verified its SHA-256 and retained the worker. It does not cover Nginx or the actual application's reported large-upload HTTP 500.

This is not an independent security audit, the full upstream harness or complete exploit-regression certification. Third-party extensions, historical dependencies and all application paths are not guaranteed compatible. Use an isolated test environment and retain backups. Installer test results are recorded in `evidence/`.
