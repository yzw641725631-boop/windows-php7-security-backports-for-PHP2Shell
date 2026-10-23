# Downloads / 下载

**v3 修复说明：** 修复旧版助手在 PowerShell 2.0 上的 `LiteralPath` 参数错误；请完整更新安装包，仅把旧 v2 的 `Install.cmd` 换成 `Install-Legacy.cmd` 不能消除此错误。`Install.cmd` 仍会自动分流。PHP 运行包未改变。

**v3 correction:** fixes the legacy helper's `LiteralPath` parameter failure. Update the complete kit; changing only the entry point in an old v2 kit does not fix it. `Install.cmd` still dispatches automatically. PHP runtime bytes are unchanged.

## 中文

当前推荐 **v3 部署包**，包含 PowerShell 2.0 兼容入口和修正后的启动器；此前安装包保留为历史文件。PHP 核心运行 ZIP 未改变。Server 2008 R2 SP1 上从新包运行 `Install-Legacy.cmd`，见[说明](../installer/LEGACY-INSTALL.zh-en.md)。

**[打开 Releases 下载页面](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/tag/php-7.3.4-php2shell-20261023-rc3)**，在 Assets 中选择运行包或 phpStudy 安装包。不要把自动生成的 Source code 当作独立运行包。

- `php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip`：完整运行包，原字节保持不变，适用 Windows **x64** / NTS / VC15。文件名里的 `Win32` 是历史发行命名，不表示这是 x86 包。
- `phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-v3-20261023.zip`：相同运行包加安装/回滚脚本、双语说明、许可与内部哈希清单；交互提示为中文。
- `SHA256SUMS.txt` / `package-manifest.json`：公开包的 SHA-256 与大小。清单用于一致性校验，本次没有独立代码签名。

在本目录可用 `Get-FileHash .\文件名.zip -Algorithm SHA256` 对照清单。请先阅读 [版本范围与限制](../README.md) 和 [安装说明](../installer/README.md)。

## English

Use the **v3 deployment kit** with PowerShell 2.0-compatible entry points and corrected launcher exit handling. Earlier kits are historical; the runtime ZIP is unchanged. On Server 2008 R2 SP1, use `Install-Legacy.cmd` from the new kit. See the [guide](../installer/LEGACY-INSTALL.zh-en.md).

**[Open the release downloads](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/tag/php-7.3.4-php2shell-20261023-rc3)** and select the runtime or phpStudy kit under Assets. The automatic Source code archives are repository snapshots.

The 20261022 ZIP is the unchanged complete **x64** NTS VC15 runtime; `Win32` is legacy filename terminology, not an x86 target. The 20261023 bilingual kit contains the same runtime, installation/rollback scripts, bilingual instructions, licenses and internal hashes; script prompts are Chinese.

Compare `Get-FileHash .\filename.zip -Algorithm SHA256` with `SHA256SUMS.txt` or `package-manifest.json`. These are consistency hashes, not an independent code signature. Read the [scope/limitations](../README.md) and [installation guide](../installer/README.md) first.
