# PHP 7.3.4 Windows x64 NTS VC15 — Unofficial source-port candidate

## Installer v2 / 安装器更新

**rc2 仅更新安装工具，PHP 运行包与 rc1 完全一致。**

- 新增 PowerShell 2.0 / .NET 2.0 API 兼容助手；Server 2008 R2 SP1 请使用 `Install-Legacy.cmd` 和 `Rollback-Legacy.cmd`。
- 修复 PowerShell 版本要求拒绝执行时仍显示 `Completed` 的启动器问题；同时检查调用状态和脚本退出码。
- 保留固定哈希校验、完整备份、原配置/扩展保留与失败恢复；兼容助手新增有限的目录锁重试。
- 18 项隔离检查在 Windows 11 / PowerShell 5.1 通过，进程辅助代码以 C# 2 / .NET 2.0 引用程序集编译检查成功。真正的 PowerShell 2.0 全流程与 Server 2008 R2 业务仍待现场验证，不宣称已经实测。
- 推荐安装包：`phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-v2-20261023.zip`。完整解压后，从新目录运行兼容入口并填写**原 PHP 目录**。

**rc2 refreshes installation tools only; PHP runtime bytes match rc1.** It adds PowerShell 2.0-compatible entry points, corrects false success reporting after version rejection, and retains integrity/backup/recovery safeguards. Use the named **v2** installer kit, then `Install-Legacy.cmd` / `Rollback-Legacy.cmd` on Server 2008 R2 SP1. Eighteen isolated checks ran on Windows 11 / PowerShell 5.1 and the capture helper compiled against .NET 2.0 APIs; actual PowerShell 2.0 end-to-end execution and legacy-server business validation remain pending.

## 中文

这是 PHP2Shell（CVE-2026-109618 / CVE-2026-109619）的非官方 PHP 7.3.4 源码移植候选版，适用 **Windows x64 / NTS / VC15**。rc2 保持原运行包不变，更新安装器并提供 PowerShell 2.0 兼容入口。文件与仓库 `php7.3/7.3.4/dist/` 当前清单一致。

请在下方 **Assets** 中选择：

- `php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip`：**完整 PHP 运行包**，包含 PHP 程序、内置扩展和匹配依赖；不包含你的 `php.ini`。
- `phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-v2-20261023.zip`：**phpStudy 安装包**，包含同一个运行包，以及更新后的安装、备份、回滚脚本与双语说明。
- `SHA256SUMS.txt`：以上两个 ZIP 的 SHA-256 校验值。

GitHub 自动提供的 **Source code (zip)** / **Source code (tar.gz)** 是仓库源码快照，不是已经编译好的 PHP 运行目录。

phpStudy 安装：解压安装包到 PHP 目录之外，先停服务，以管理员身份运行 `Install.cmd`，填写当前 `php7.3.4nts` 目录。安装保留原配置和自装扩展，在原路径启用补丁版并另存旧目录备份。成功后再启动服务并验证业务。

**仍为预发布候选版：** 未完成独立安全审计或完整利用回归认证。XML 大属性比较用例超时仍未解决；Windows Server 2019 / 实际 ThinkPHP 应用与大文件上传路径尚未完整验证，大文件 500 需要日志定位。第三方扩展和历史依赖不因本补丁获得全面安全保证。更多信息见版本目录中的 README、安装说明和验证记录。

## English

This is an unofficial PHP 7.3.4 source-port candidate for PHP2Shell (CVE-2026-109618 / CVE-2026-109619), targeting **Windows x64 / NTS / VC15**. rc2 preserves runtime bytes and refreshes the installer with PowerShell 2.0-compatible entry points. Assets match the current manifest under `php7.3/7.3.4/dist/`.

Choose the appropriate file under **Assets**:

- `php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip`: the **complete compiled runtime**, including PHP binaries, bundled extensions and matched dependencies, without your `php.ini`.
- `phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-v2-20261023.zip`: the **v2 phpStudy installer kit**, containing the same runtime plus updated installation, backup, rollback scripts and bilingual instructions.
- `SHA256SUMS.txt`: SHA-256 hashes for both ZIPs.

GitHub's automatic **Source code (zip)** / **Source code (tar.gz)** assets are repository snapshots, not extracted compiled PHP runtime directories.

For phpStudy, extract the installer kit outside the PHP directory, stop services, run `Install.cmd` as Administrator, and enter the active `php7.3.4nts` directory. Configuration/add-ons are preserved and the old directory is backed up. Start services and validate your applications after success.

**Prerelease candidate:** no independent security audit or full exploit-regression certification. The XML large-attribute timeout remains unresolved. Windows Server 2019, actual ThinkPHP applications and large-upload paths are not fully validated; upload HTTP 500 reports need logs. Third-party extensions and historical dependencies are not comprehensively secured by this port. Read the version README, installer guide and validation evidence.
