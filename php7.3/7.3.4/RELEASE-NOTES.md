# PHP 7.3.4 Windows x64 NTS VC15 — Unofficial source-port candidate

## Installer v3 / 安装器更新

**rc3 仅修复安装工具，PHP 运行包与 rc1/rc2 完全一致。**

- 修复用户在 PowerShell 2.0 上报告的 `LiteralPath` 参数不兼容。旧版助手的路径检查、复制、权限保留和清理改用 .NET 2.0 文件系统 API，不依赖这些命令的新版参数。
- `Install.cmd` 仍按版本自动选择助手；Server 2008 R2 SP1 推荐明确运行 `Install-Legacy.cmd`，回滚使用 `Rollback-Legacy.cmd`。仅切换旧 v2 的入口不能修复此错误，需完整更新到 v3。
- 保留 84 个运行文件的固定哈希、原 INI/自装扩展/ACL、完整备份、进程检查和失败恢复。安装失败输出具体脚本位置。
- 23 项本地隔离检查包括禁用文件系统 provider 命令后安装/回滚、方括号及中文目录（相对 extension_dir）、只读自定义文件/目录、受保护 ACL、无关同级目录保留和旧 CLIXML 记录读取。宿主仍是 Windows 11 / PowerShell 5.1；C# 2 / .NET 2.0 引用程序集编译检查通过。实际 PowerShell 2.0 和旧服务器业务仍待现场验证。
- 推荐安装包：`phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-v3-20261023.zip`。

**rc3 changes installer tools only; runtime bytes match rc1/rc2.** The legacy helper replaces `LiteralPath`-dependent filesystem commands with .NET 2.0 APIs, retaining hashes, backup, original configuration/add-ons/ACLs and recovery. Failure diagnostics now include the script position. The generic launcher still selects by PowerShell version; use `Install-Legacy.cmd` / `Rollback-Legacy.cmd` on Server 2008 R2 SP1. Merely switching entry points in an old v2 kit does not fix this failure. Twenty-three isolated checks ran on Windows 11 / PowerShell 5.1, including provider-command blocking, literal bracket/Unicode paths with relative extension_dir, read-only custom files/directories, protected ACLs, sibling preservation and old CLIXML receipt reading. C# 2/.NET 2.0 API compilation passed; actual PowerShell 2.0 end-to-end and legacy-server business checks remain pending.

## 中文

这是 PHP2Shell（CVE-2026-109618 / CVE-2026-109619）的非官方 PHP 7.3.4 源码移植候选版，适用 **Windows x64 / NTS / VC15**。rc3 保持原运行包不变，更新安装器并提供 PowerShell 2.0 兼容入口。文件与仓库 `php7.3/7.3.4/dist/` 当前清单一致。

请在下方 **Assets** 中选择：

- `php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip`：**完整 PHP 运行包**，包含 PHP 程序、内置扩展和匹配依赖；不包含你的 `php.ini`。
- `phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-v3-20261023.zip`：**phpStudy 安装包**，包含同一个运行包，以及更新后的安装、备份、回滚脚本与双语说明。
- `SHA256SUMS.txt`：以上两个 ZIP 的 SHA-256 校验值。

GitHub 自动提供的 **Source code (zip)** / **Source code (tar.gz)** 是仓库源码快照，不是已经编译好的 PHP 运行目录。

phpStudy 安装：解压安装包到 PHP 目录之外，先停服务，以管理员身份运行 `Install.cmd`，填写当前 `php7.3.4nts` 目录。安装保留原配置和自装扩展，在原路径启用补丁版并另存旧目录备份。成功后再启动服务并验证业务。

**仍为预发布候选版：** 未完成独立安全审计或完整利用回归认证。XML 大属性比较用例超时仍未解决；Windows Server 2019 / 实际 ThinkPHP 应用与大文件上传路径尚未完整验证，大文件 500 需要日志定位。第三方扩展和历史依赖不因本补丁获得全面安全保证。更多信息见版本目录中的 README、安装说明和验证记录。

## English

This is an unofficial PHP 7.3.4 source-port candidate for PHP2Shell (CVE-2026-109618 / CVE-2026-109619), targeting **Windows x64 / NTS / VC15**. rc3 preserves runtime bytes and refreshes the installer with PowerShell 2.0-compatible entry points. Assets match the current manifest under `php7.3/7.3.4/dist/`.

Choose the appropriate file under **Assets**:

- `php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip`: the **complete compiled runtime**, including PHP binaries, bundled extensions and matched dependencies, without your `php.ini`.
- `phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-v3-20261023.zip`: the **v3 phpStudy installer kit**, containing the same runtime plus updated installation, backup, rollback scripts and bilingual instructions.
- `SHA256SUMS.txt`: SHA-256 hashes for both ZIPs.

GitHub's automatic **Source code (zip)** / **Source code (tar.gz)** assets are repository snapshots, not extracted compiled PHP runtime directories.

For phpStudy, extract the installer kit outside the PHP directory, stop services, run `Install.cmd` as Administrator, and enter the active `php7.3.4nts` directory. Configuration/add-ons are preserved and the old directory is backed up. Start services and validate your applications after success.

**Prerelease candidate:** no independent security audit or full exploit-regression certification. The XML large-attribute timeout remains unresolved. Windows Server 2019, actual ThinkPHP applications and large-upload paths are not fully validated; upload HTTP 500 reports need logs. Third-party extensions and historical dependencies are not comprehensively secured by this port. Read the version README, installer guide and validation evidence.
