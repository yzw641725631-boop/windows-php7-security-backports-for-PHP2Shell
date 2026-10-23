# PHP 7.3.4 — Windows x64 / NTS / VC15

[中文](#中文) · [English](#english) · [Repository / 仓库](../../README.md)

## 中文

本目录是对干净 PHP 7.3.4 的**非官方 PHP2Shell 源码移植候选版**。依据 PHP 8.2 官方提交 [`01a40e89fbfc499936e3b05888d8f00bfde886df`](https://github.com/php/php-src/commit/01a40e89fbfc499936e3b05888d8f00bfde886df)，适配 PHP 7.3 的类型、引擎结构和 Windows 接口。

| 项目 | 当前构建 |
| --- | --- |
| PHP | 7.3.4；版本号不变，构建日期为 2026-10-22 |
| 平台 | Windows x64，NTS，VC15 / MSVC 2017 |
| 优化 | `/O2 /Ob2`，旧 VC15 编译器兼容参数 `/d2SSAOptimizer-` |
| 源码 | 114 个文件更改；111 个上游非测试代码映射条目 |
| 原源码 SHA-256 | `6fe79fa1f8655f98ef6708cde8751299796d6c1e225081011f4104625b923b83` |
| 执行验证宿主 | Windows 11 Pro 10.0.26200；未完成 Windows Server 2019 实机业务验证 |

### 下载、安装与回滚

**安装器 v2：** 新增 PowerShell 2.0 兼容助手，并修复启动器错误显示成功的问题。Server 2008 R2 SP1 请使用 `Install-Legacy.cmd`；回滚使用 `Rollback-Legacy.cmd`。运行包仍是同一个 7.3.4 构建。兼容助手已做本地隔离检查和 .NET 2.0 API 编译检查，实际 PowerShell 2.0 全流程仍待现场验证，见[旧系统说明](installer/LEGACY-INSTALL.zh-en.md)。

- [phpStudy 双语安装包](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.3.4-php2shell-20261023-rc2/phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-v2-20261023.zip)：包含运行包 ZIP、安装/回滚脚本和中英说明。脚本交互提示目前为中文。
- [完整 PHP 运行包](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.3.4-php2shell-20261023-rc2/php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip)：同次构建的核心、内置扩展和配套依赖；没有用户的 `php.ini`。
- [SHA-256 清单](dist/SHA256SUMS.txt) / [安装说明](installer/README.md) / [构建说明](build/README.md)。

安装需要先停 phpStudy 服务，保持目标 PHP 进程退出。以管理员身份执行 `Install.cmd`，输入当前目录，例如 `D:\phpstudy_pro\Extensions\php\php7.3.4nts`。脚本校验精确版本/架构和包哈希、复制配置/自装扩展、完整备份旧目录、在原路径替换。安装后的配置/扩展检查失败会尝试自动恢复。成功后启动服务并验证业务；手动恢复使用 `Rollback.cmd`。

### 改动范围与运行行为

- 延迟 OOM、可失败分配、软/硬内存限额与内部退出标记；字符串、哈希表及多种扩展调用路径作版本适配。
- VM 中断、异常展开、未完成调用和请求状态清理；PHP 8 独有的语言/引擎机制在映射中注明不适用。
- 保留 Session 上传进度，初始化期间采用受限反序列化，避免触发用户对象唤醒/自定义反序列化。
- 普通软内存超限尽量结束当前请求并保留进程；达到硬限制仍会退出工作进程。进程补充由 phpStudy 或其他管理器负责。
- 第三方扩展只做过部分加载检查，不保证其二进制布局和所有 OOM 路径均兼容；更换引擎后需逐项验证实际业务。

`php.ini` 继续使用原配置，新增项不必显式填写：

```ini
; 使用默认的内存硬限制策略，不是关闭 memory_limit
memory_hard_limit_percent = -1
; 自动按 max_input_vars + max_file_uploads 计算 multipart 分段数
max_multipart_body_parts = -1
```

不填写时，第一项在 `ini_get_all()` 中可能为 `NULL`，第二项为 `-1`。它们不直接控制上传文件大小。上传大小仍受 Nginx `client_max_body_size`、PHP `post_max_size` / `upload_max_filesize` 及业务限制影响。放大上传限制不会自动解决业务处理时的内存超限或 500。

### 验证与未完成事项

记录了核心/常用扩展、普通上传、原生 FastCGI 和 Session 上传进度检查；220 次有界软 OOM 后续请求检查通过，硬限制退出码为 137；安装脚本有 12 项隔离检查通过。

PHP 8.2 用例仅做有界输出比较：139 匹配、17 差异、14 语法不兼容、57 未运行、1 超时。**XML 大属性用例超时未解决，Windows Server 2019 / 目标 ThinkPHP 业务未完成独立验证，大文件上传 500 需要继续诊断。** 这不是完整上游测试、内存安全审计或漏洞利用回归认证，不能宣称没有隐患或全部路径等价。详见 [evidence](evidence/README.md)。

### 源码复现

下载 [原始 PHP 7.3.4 源码](https://museum.php.net/php7/php-7.3.4.tar.xz) 并核对上表哈希，解压到独立目录。使用 Python 3：

```powershell
python .\source\apply_source_patch.py --source C:\lab\php-7.3.4
```

脚本先核对全部原文件和替换文件哈希，再写入。另一种方式是在干净源码目录执行 `git -c core.autocrlf=false apply --check <补丁绝对路径>` 后 `git -c core.autocrlf=false apply <补丁绝对路径>`。只选一种应用方式，不能重复套用。补丁在 `patches/`，114 个精确替换文件在 `source/patched-source/`；后续构建见 [build](build/README.md)。

## English

This directory contains an **unofficial PHP2Shell source-port candidate for pristine PHP 7.3.4**, adapted from PHP 8.2 upstream commit [`01a40e8`](https://github.com/php/php-src/commit/01a40e89fbfc499936e3b05888d8f00bfde886df) to PHP 7.3 types, engine structures and Windows interfaces.

### Target and downloads

**Installer v2:** adds a PowerShell 2.0-compatible helper and fixes the launcher's false success message. Use `Install-Legacy.cmd` / `Rollback-Legacy.cmd` on Server 2008 R2 SP1. Runtime bytes are unchanged. Isolated tests and a .NET 2.0 API compile check have been performed; actual PowerShell 2.0 end-to-end execution remains pending. See the [legacy guide](installer/LEGACY-INSTALL.zh-en.md).

The target is **Windows x64 / NTS / VC15 (MSVC 2017)**. `PHP_VERSION` remains 7.3.4; the build date is 2026-10-22. The optimized build uses `/O2 /Ob2` with `/d2SSAOptimizer-` for the legacy compiler. There are 114 changed source files and 111 upstream non-test mapping entries.

- [Bilingual phpStudy installer kit](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.3.4-php2shell-20261023-rc2/phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-v2-20261023.zip); interactive script messages are currently Chinese.
- [Standalone complete runtime](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.3.4-php2shell-20261023-rc2/php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip), without a user `php.ini`.
- [SHA-256 hashes](dist/SHA256SUMS.txt), [installation/rollback](installer/README.md), and [build instructions](build/README.md).

Stop phpStudy services before installation. Run `Install.cmd` as Administrator and enter the active PHP 7.3.4 directory. It checks the exact target and archive hashes, preserves configuration/add-ons, backs up the original directory and activates the replacement at the same path. Failed post-activation configuration checks trigger a recovery attempt. Restart services after success and test the application; use `Rollback.cmd` to restore the snapshot.

### Scope and behavior

The port introduces delayed OOM, fallible allocation, soft/hard memory limits and an internal unwind marker, alongside adapted VM, exception, hash/string, extension and request-cleanup paths. PHP 8-only features are marked not applicable in the mapping. Session upload progress is retained with restricted request-startup unserialization.

Soft OOM is intended to end the current request while retaining the worker. The hard limit can terminate the worker; replacement is the process manager's responsibility. Third-party extension loading is not a complete compatibility or OOM-path assessment.

Existing INI configuration is preserved. Both added settings are optional:

```ini
; Automatic hard-limit policy, not an unlimited memory_limit
memory_hard_limit_percent = -1
; Automatic limit: max_input_vars + max_file_uploads
max_multipart_body_parts = -1
```

When omitted, the first setting may appear as `NULL` in `ini_get_all()` and the second as `-1`. Neither directly limits uploaded file bytes. Nginx, PHP upload directives and application logic still determine upload limits. Larger upload limits do not automatically resolve application memory exhaustion or HTTP 500.

### Validation and limitations

Recorded checks cover core/common extensions, ordinary uploads, native FastCGI and retained Session progress. The 220 bounded soft-OOM follow-up-request checks passed; the hard-limit process exited with code 137. Twelve isolated installer checks passed.

The bounded PHP 8.2 comparison recorded 139 matching outputs, 17 differences, 14 syntax incompatibilities, 57 cases not run and one timeout. **The XML large-attribute timeout is unresolved, Windows Server 2019/target ThinkPHP applications lack complete independent validation, and large-upload HTTP 500 reports need further diagnosis.** This is not the full upstream test harness, an independent memory-safety audit, or exploit-regression certification. See [evidence](evidence/README.md).

### Reproduce source changes

Download [pristine PHP 7.3.4](https://museum.php.net/php7/php-7.3.4.tar.xz), verify SHA-256 `6fe79fa1f8655f98ef6708cde8751299796d6c1e225081011f4104625b923b83`, and extract it to a separate directory. With Python 3:

```powershell
python .\source\apply_source_patch.py --source C:\lab\php-7.3.4
```

The script validates all original and replacement hashes before writing. Alternatively, run `git -c core.autocrlf=false apply --check <absolute-patch-path>` and then `git -c core.autocrlf=false apply <absolute-patch-path>` from a pristine source tree. Use one method only. See `patches/`, `source/patched-source/`, and [build instructions](build/README.md).
