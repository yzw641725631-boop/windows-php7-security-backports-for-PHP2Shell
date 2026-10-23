# Downloads / 下载

## 中文

- `php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip`：完整运行包，原字节保持不变，适用 Windows **x64** / NTS / VC15。文件名里的 `Win32` 是历史发行命名，不表示这是 x86 包。
- `phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-bilingual-20261023.zip`：相同运行包加安装/回滚脚本、双语说明、许可与内部哈希清单；交互提示为中文。
- `SHA256SUMS.txt` / `package-manifest.json`：公开包的 SHA-256 与大小。清单用于一致性校验，本次没有独立代码签名。

在本目录可用 `Get-FileHash .\文件名.zip -Algorithm SHA256` 对照清单。请先阅读 [版本范围与限制](../README.md) 和 [安装说明](../installer/README.md)。

## English

The 20261022 ZIP is the unchanged complete **x64** NTS VC15 runtime; `Win32` is legacy filename terminology, not an x86 target. The 20261023 bilingual kit contains the same runtime, installation/rollback scripts, bilingual instructions, licenses and internal hashes; script prompts are Chinese.

Compare `Get-FileHash .\filename.zip -Algorithm SHA256` with `SHA256SUMS.txt` or `package-manifest.json`. These are consistency hashes, not an independent code signature. Read the [scope/limitations](../README.md) and [installation guide](../installer/README.md) first.
