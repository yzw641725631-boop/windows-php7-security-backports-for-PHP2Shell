# PHP 7.3.4 Windows x64 NTS VC15 — Unofficial source-port candidate

## 中文

这是 PHP2Shell（CVE-2026-109618 / CVE-2026-109619）的非官方 PHP 7.3.4 源码移植候选版，适用 **Windows x64 / NTS / VC15**。本次 Release 中的 ZIP 与仓库 `php7.3/7.3.4/dist/` 中已发布文件完全一致，只增加明确的 Release 下载入口。

请在下方 **Assets** 中选择：

- `php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip`：**完整 PHP 运行包**，包含 PHP 程序、内置扩展和匹配依赖；不包含你的 `php.ini`。
- `phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-bilingual-20261023.zip`：**phpStudy 安装包**，包含同一个运行包，以及安装、备份、回滚脚本与双语说明。
- `SHA256SUMS.txt`：以上两个 ZIP 的 SHA-256 校验值。

GitHub 自动提供的 **Source code (zip)** / **Source code (tar.gz)** 是仓库源码快照，不是已经编译好的 PHP 运行目录。

phpStudy 安装：解压安装包到 PHP 目录之外，先停服务，以管理员身份运行 `Install.cmd`，填写当前 `php7.3.4nts` 目录。安装保留原配置和自装扩展，在原路径启用补丁版并另存旧目录备份。成功后再启动服务并验证业务。

**仍为预发布候选版：** 未完成独立安全审计或完整利用回归认证。XML 大属性比较用例超时仍未解决；Windows Server 2019 / 实际 ThinkPHP 应用与大文件上传路径尚未完整验证，大文件 500 需要日志定位。第三方扩展和历史依赖不因本补丁获得全面安全保证。更多信息见版本目录中的 README、安装说明和验证记录。

## English

This is an unofficial PHP 7.3.4 source-port candidate for PHP2Shell (CVE-2026-109618 / CVE-2026-109619), targeting **Windows x64 / NTS / VC15**. The ZIPs are byte-identical to the already-published files under `php7.3/7.3.4/dist/`; this release adds an explicit download entry point.

Choose the appropriate file under **Assets**:

- `php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip`: the **complete compiled runtime**, including PHP binaries, bundled extensions and matched dependencies, without your `php.ini`.
- `phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-bilingual-20261023.zip`: the **phpStudy installer kit**, containing the same runtime plus installation, backup, rollback scripts and bilingual instructions.
- `SHA256SUMS.txt`: SHA-256 hashes for both ZIPs.

GitHub's automatic **Source code (zip)** / **Source code (tar.gz)** assets are repository snapshots, not extracted compiled PHP runtime directories.

For phpStudy, extract the installer kit outside the PHP directory, stop services, run `Install.cmd` as Administrator, and enter the active `php7.3.4nts` directory. Configuration/add-ons are preserved and the old directory is backed up. Start services and validate your applications after success.

**Prerelease candidate:** no independent security audit or full exploit-regression certification. The XML large-attribute timeout remains unresolved. Windows Server 2019, actual ThinkPHP applications and large-upload paths are not fully validated; upload HTTP 500 reports need logs. Third-party extensions and historical dependencies are not comprehensively secured by this port. Read the version README, installer guide and validation evidence.
