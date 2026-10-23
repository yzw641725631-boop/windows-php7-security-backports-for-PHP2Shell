# phpStudy installation / phpStudy 安装

## 中文

**仅接受现有 PHP 7.4.33 / Windows x64 / NTS / VC15。** 本脚本不会从其他 7.4.x 自动升级，也不会替换 PHP 7.3。完整运行包可用于单独新建测试目录；迁移旧版本需自行核对配置、扩展和业务。

1. 下载并校验 [phpStudy 安装包](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.4.33-php2shell-20261023-rc1/phpStudy-PHP-7.4.33-nts-VC15-x64-unofficial-backport-install-kit-20261023.zip)，完整解压到 PHP 安装目录之外。
2. 在 phpStudy 确认网站的实际 PHP 目录，例如 `D:\phpstudy_pro\Extensions\php\php7.4.33nts`。目录内应有 `php.exe`、`php-cgi.exe`、`php7.dll`、`php.ini`。
3. 先停止 phpStudy 服务和会重新拉起 PHP 的管理程序。关闭面板窗口不一定停服务。脚本不会自动停服务、强杀进程或自动启动服务。
4. 以管理员身份运行 `Install.cmd`，输入当前 PHP 目录。管理员权限用于检查服务进程路径和处理目录权限。请为临时候选目录及保留备份预留约两份现有 PHP 目录大小的额外空间。
5. 显示“安装及配置/扩展启动检查通过”后，保存备份/记录路径，再启动服务并检查网站、API、数据库、Session 与上传。

脚本校验固定的 ZIP SHA-256、内部逐文件哈希、版本和架构，完整保留旧目录作为同级 `.before-php7433-port-...` 备份。原 `php.ini`、自装扩展、自定义文件和 ACL 复制到候选目录；同次构建的核心与内置扩展放回原 PHP 路径。安装工具包目录不是网站的运行目录。

目标进程尚未退出、进程路径不可读、现有配置有启动警告、目录有符号链接/联接或外部扫描 INI 等情况会阻止自动替换。替换后配置/扩展检查失败会尝试自动恢复。第三方扩展能加载不等于其全部行为兼容。

**行为区别：** 官方 7.4 源码补丁在 OOM 时直接退出当前工作进程，Session 上传进度回调停用，普通上传保留。INI 的 `session.upload_progress.enabled=1` 不会重新启用该回调。该包没有 `memory_hard_limit_percent`；只新增 `max_multipart_body_parts`，不写也使用内置默认值。参见[版本说明](../README.md)。

### 回滚

先停服务，以管理员身份运行 `Rollback.cmd` 并输入相同 PHP 目录。它恢复安装前的整个目录快照，并将回滚前目录完整保留到同级 `.after-php7433-port-...`。安装后改过的配置不会自动合并到旧配置，可从保留目录人工取回。回滚成功后再启动服务。不要提前删除备份或安装记录。

在脚本目录中也可以执行：

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-Php7433Port.ps1 -PhpDir 'D:\phpstudy_pro\Extensions\php\php7.4.33nts' -CheckOnly
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-Php7433Port.ps1 -PhpDir 'D:\phpstudy_pro\Extensions\php\php7.4.33nts'
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Rollback-Php7433Port.ps1 -PhpDir 'D:\phpstudy_pro\Extensions\php\php7.4.33nts'
```

从 Git 检出脚本时，需将原运行包 ZIP 放在脚本旁，或增加 `-ArchivePath <ZIP路径>`。`ExecutionPolicy Bypass` 仅针对该进程，不永久修改执行策略或绕过组织策略。

意外中断时保持服务停止，按同级 `.php7433-port-install-...json` 的 `backup_dir` 恢复；回滚脚本可用 `-ReceiptPath` 指定记录。遗留 `.php7433-port.lock` 时，先确认没有安装/回滚脚本运行，再清理该锁文件，切勿删除备份。

版本号仍是 7.4.33，构建日期更新。安装目录的 `UNOFFICIAL-BACKPORT-MANIFEST.json` 与 `UNOFFICIAL-BACKPORT-SHA256.json` 记录构建和文件哈希。单个 INI 项存在不代表完整安装或安全认证。

## English

The automatic installer accepts **existing PHP 7.4.33 / Windows x64 / NTS / VC15 only**. It does not automatically upgrade another 7.4.x release or replace PHP 7.3. Use the standalone runtime in a separate test directory when evaluating an upgrade, with explicit configuration/add-on migration.

1. Download the [installer kit](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.4.33-php2shell-20261023-rc1/phpStudy-PHP-7.4.33-nts-VC15-x64-unofficial-backport-install-kit-20261023.zip), verify its SHA-256 and extract outside the active PHP directory.
2. Confirm the site's PHP path (for example `D:\phpstudy_pro\Extensions\php\php7.4.33nts`) contains `php.exe`, `php-cgi.exe`, `php7.dll` and `php.ini`.
3. Stop phpStudy services and any worker supervisor. Closing the GUI may leave services running. The scripts do not control services or kill existing workers.
4. Run `Install.cmd` as Administrator and enter the PHP directory. Allow about twice the current directory size in extra disk space.
5. After success, retain the backup/receipt paths, restart services and validate your application.

The script validates archive/per-file hashes and target metadata, preserves configuration/add-ons/custom files/ACLs, keeps the original directory as a sibling `.before-php7433-port-...` backup and activates the matched replacement at the original path. Active/unverifiable processes, startup warnings, linked directories and external INI scanning block replacement. Failed post-activation checks trigger a recovery attempt. Extension loading is not comprehensive compatibility validation.

**Upstream 7.4 behavior:** OOM exits the current worker; the Session upload-progress callback is disabled even if its INI flag is enabled. Ordinary uploads remain supported. `memory_hard_limit_percent` is absent. `max_multipart_body_parts` uses its built-in default when omitted. See the [version documentation](../README.md).

To roll back, stop services and run `Rollback.cmd` as Administrator with the same directory. It restores the full original snapshot and retains the replaced installation under `.after-php7433-port-...`, including later configuration edits, which are not automatically merged. Restart services after success. Keep backups and receipts.

The PowerShell examples above support preflight and rollback. Add `-ArchivePath` if the original runtime ZIP is not next to scripts from a Git checkout. Execution-policy bypass is process-local and cannot override organization policy. For interruption recovery, keep services stopped and use the receipt's `backup_dir` or pass `-ReceiptPath`. Remove a stale lock only after confirming no script is running; keep the backup.

Version remains 7.4.33. Build/file metadata is in `UNOFFICIAL-BACKPORT-MANIFEST.json` and `UNOFFICIAL-BACKPORT-SHA256.json`. Directive presence is not a full installation or security certification. Script prompts are currently Chinese; the guide is bilingual.
