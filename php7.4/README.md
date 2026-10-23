# PHP 7.4

## 中文

当前提供 **[PHP 7.4.33 / Windows x64 / NTS / VC15](7.4.33/README.md)**，从干净官方源码应用 PHP 团队的 7.4 专用 PHP2Shell 补丁后重新编译。Windows 二进制为本项目的非官方构建。

它使用官方旧分支的最小缓解方案：OOM 时退出当前工作进程，Session 上传进度回调停用。与本仓库 PHP 7.3.4 的延迟 OOM 移植方案不同。普通文件上传仍可用。

补丁及自动安装脚本针对精确的 7.4.33 版本，不代表已经单独制作 7.4.5 或 7.4.6 的同版本补丁。

## English

The available target is **[PHP 7.4.33 / Windows x64 / NTS / VC15](7.4.33/README.md)**, rebuilt from pristine upstream source with the PHP team's 7.4-specific PHP2Shell patch. The Windows binaries are unofficial project builds.

This follows the upstream EOL minimal mitigation: OOM terminates the current worker and the Session upload-progress callback is disabled. It differs from this repository's PHP 7.3.4 delayed-OOM port. Ordinary file uploads remain supported.

The source patch and automatic installer target exactly 7.4.33. They are not separate same-version patches for 7.4.5 or 7.4.6.
