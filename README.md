# Windows security backports for PHP 7.x / PHP 7.x Windows 安全补丁回补

[中文](#中文) · [English](#english)

## 中文

本仓库提供针对 **PHP2Shell（CVE-2026-109618 / CVE-2026-109619）** 的非官方源码回补、Windows 构建产物，以及 phpStudy 安装和回滚脚本。

当前仅提供 **PHP 7.3.4 / Windows x64 / NTS / VC15**。`php7.3/` 是版本系列目录，不代表全部 PHP 7.3 版本都已支持；其他 PHP 7.x 版本将在完成适配和验证后单独发布。

**状态：实验性源码移植候选版，未经过独立安全审计，不是 PHP 官方发行版。** 本项目按 PHP 8.2 官方修复适配旧引擎，改动范围大于官方 7.4 的最小缓解补丁。已发现的验证限制和待解决问题公开记录，不将编译成功、启动成功或 HTTP 状态码当作漏洞修复认证。

### 下载与使用

| 版本 | 平台 | 文档 | 下载 |
| --- | --- | --- | --- |
| 7.3.4 | Windows x64 / NTS / VC15 | [版本说明](php7.3/7.3.4/README.md) | [phpStudy 安装包](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.3.4-php2shell-20261023-rc1/phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-bilingual-20261023.zip) · [完整运行包](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.3.4-php2shell-20261023-rc1/php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip) |

phpStudy 用户：解压安装包到 PHP 安装目录之外，在 phpStudy 停止服务，以管理员身份运行 `Install.cmd`，输入实际的 PHP 7.3.4 目录。安装成功后再启动服务并验证业务。脚本保留原 `php.ini`、第三方扩展和原安装路径，另存完整旧目录备份。回滚使用 `Rollback.cmd`。详见[中英双语安装说明](php7.3/7.3.4/installer/README.md)。

### 仓库结构

```text
php7.3/
  README.md                   PHP 7.3 系列入口
  7.3.4/
    README.md                 适配范围、行为、验证与限制
    patches/                  对干净 7.3.4 的统一补丁
    source/                   114 个更改文件、哈希与应用脚本
    build/                    可配置的 Windows 构建入口和说明
    installer/                phpStudy 安装、回滚和说明
    dist/                     运行包、双语安装包、SHA-256
    evidence/                 构建和测试记录、官方文件映射
    reference/                官方补丁、来源和依赖下载清单
    tests/                    本机回归工具和上游比较用例
```

### 已知验证范围

- 本机构建与测试宿主为 Windows 11；Windows Server 2019 是目标平台，尚无独立、完整的实机业务验证记录。
- 核心与常用扩展、普通 HTTP/FastCGI 上传及 Session 上传进度已做功能检查；220 次有界软内存超限检查记录为通过，检查后同一工作进程继续响应。
- 安装脚本的 12 项隔离检查记录为通过，包括配置保留、哈希拒绝、失败恢复及回滚。测试时进程清单仅限隔离目录；正式脚本没有跳过进程检查的参数。
- PHP 8.2 PHPT 比较为 139 个输出匹配、17 个输出差异、14 个语法不兼容、57 个未运行、1 个超时。XML 大属性用例超时仍需调查；这不是完整上游测试框架或利用回归认证。
- 第三方扩展加载成功不等于其全部 OOM 路径已修复；历史依赖没有因此获得全面安全更新。大文件上传出现的 500 需要结合日志诊断，不能视为防护成功证据。

详见[版本说明](php7.3/7.3.4/README.md)、[验证记录](php7.3/7.3.4/evidence/README.md)和[安全报告指引](SECURITY.md)。

## English

This repository contains **unofficial source backports for PHP2Shell (CVE-2026-109618 / CVE-2026-109619)**, Windows runtime builds, and phpStudy installation/rollback scripts.

The only published target is **PHP 7.3.4 / Windows x64 / NTS / VC15**. The `php7.3/` directory groups the version family; it does not claim support for every PHP 7.3 release. Other PHP 7.x targets require separate adaptation and validation.

**Status: experimental source-port candidate; not independently security-audited and not an official PHP release.** This project adapts the PHP 8.2 upstream design to the older engine. Its scope is larger than the upstream PHP 7.4 minimal mitigation. Compilation, startup checks and HTTP status codes are not proof of exploit prevention.

### Downloads and installation

Use the [PHP 7.3.4 documentation](php7.3/7.3.4/README.md), [phpStudy installer ZIP](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.3.4-php2shell-20261023-rc1/phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-bilingual-20261023.zip), or [standalone runtime ZIP](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.3.4-php2shell-20261023-rc1/php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip). Verify the downloads against [`SHA256SUMS.txt`](php7.3/7.3.4/dist/SHA256SUMS.txt).

Extract the installer outside your PHP directory, stop services in phpStudy, run `Install.cmd` as Administrator, and enter the active PHP 7.3.4 directory. Restart services after success and validate your applications. The script preserves the existing `php.ini`, third-party extensions and installation path, while keeping a full original-directory backup. Use `Rollback.cmd` to restore it. See the [bilingual installation guide](php7.3/7.3.4/installer/README.md).

### Validation and limitations

- The build and recorded tests ran on Windows 11. Windows Server 2019 remains the intended target without complete independent application validation.
- Core/common-extension checks, ordinary HTTP/FastCGI uploads and retained Session upload progress were exercised. The recorded 220 bounded soft-OOM checks passed and the same worker responded afterward.
- Twelve isolated deployment checks passed, including configuration preservation, archive verification, failure recovery and rollback. Test process inventory was restricted to disposable fixtures; production scripts have no process-check bypass option.
- The PHP 8.2 PHPT comparison recorded 139 matching outputs, 17 differing outputs, 14 syntax-incompatible tests, 57 tests not run and one timeout. The XML large-attribute timeout remains unresolved. This is not the full upstream harness or exploit-regression certification.
- Third-party extension load checks do not cover all their OOM paths. Historical bundled dependencies are not comprehensively updated. A large-upload HTTP 500 needs log-based diagnosis and is not evidence that the vulnerability was blocked.

See [version details](php7.3/7.3.4/README.md), [validation evidence](php7.3/7.3.4/evidence/README.md), and [security reporting guidance](SECURITY.md).

### Upstream / 上游参考

- [PHP 8.2 official repair / 官方修复 `01a40e8`](https://github.com/php/php-src/commit/01a40e89fbfc499936e3b05888d8f00bfde886df)
- [PHP 7.4 minimal mitigation / 最小缓解 `712e60f`](https://github.com/php/php-src/commit/712e60f9edfd03f0960fc4fc3c2c375f42b90aa2)
- [CVE-2026-109618 upstream advisory](https://github.com/php/php-src/security/advisories/GHSA-w8hw-w9fx-j79w)
- [CVE-2026-109619 upstream advisory](https://github.com/php/php-src/security/advisories/GHSA-6wmf-4rv5-p3rp)

### License / 许可

PHP-derived source and patches retain upstream notices and the [PHP License 3.01](LICENSE). Project-authored scripts and documentation are also supplied under that license. Bundled third-party components retain their respective licenses; see [NOTICE](NOTICE.md) and the runtime's `readme-redist-bins.txt`.

This product includes PHP software, freely available from <http://www.php.net/software/>.
