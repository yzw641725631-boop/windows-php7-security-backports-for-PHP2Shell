# phpStudy installation and rollback / 安装与回滚

**v3 修复说明：** 修复旧版助手在 PowerShell 2.0 上的 `LiteralPath` 参数错误；请完整更新安装包，仅把旧 v2 的 `Install.cmd` 换成 `Install-Legacy.cmd` 不能消除此错误。`Install.cmd` 仍会自动分流。PHP 运行包未改变。

**v3 correction:** fixes the legacy helper's `LiteralPath` parameter failure. Update the complete kit; changing only the entry point in an old v2 kit does not fix it. `Install.cmd` still dispatches automatically. PHP runtime bytes are unchanged.

## 中文

**v3 安装器更新：** `Install.cmd` / `Rollback.cmd` 现在通过错误处理包装器启动，并核对脚本退出码，修复版本要求失败仍显示 `Completed` 的问题。PowerShell 低于 5.1 时自动选择 2.0 兼容助手；Server 2008 R2 SP1 用户可直接运行 **`Install-Legacy.cmd`**，回滚使用 **`Rollback-Legacy.cmd`**。完整步骤和验证限制见 [旧系统双语说明](LEGACY-INSTALL.zh-en.md)。PHP 运行包字节保持不变。

适用 **Windows x64 / PHP 7.3.4 / NTS / VC15**。这是完整 PHP 运行目录的替换安装，不是 phpStudy 插件，也不是把安装工具包目录选成网站的 PHP 路径。

### 安装

1. 下载 [`dist/` 中的双语安装包](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.3.4-php2shell-20261023-rc3/phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-v3-20261023.zip)，按 [SHA256SUMS.txt](../dist/SHA256SUMS.txt) 校验。把它完整解压到目标 PHP 目录之外；无需手工解压里面的运行包 ZIP。
2. 在 phpStudy 确认站点实际使用的 PHP 目录，例如 `D:\phpstudy_pro\Extensions\php\php7.3.4nts`；里面应有 `php.exe`、`php-cgi.exe`、`php7.dll`、`php.ini`。保留约两份现有 PHP 目录大小的额外磁盘空间。
3. **先停止 phpStudy 服务**。退出窗口不一定停止后台工作进程。若进程被守护程序重新启动，应先停止对应管理服务。脚本不自动停止或启动服务，也不强杀进程。
4. 右键 `Install.cmd` → 以管理员身份运行，输入当前 PHP 目录。管理员权限用于读取服务进程路径和处理安装目录权限。
5. 看到“安装及配置/扩展启动检查通过”后，保存屏幕显示的备份/记录路径，在 phpStudy 启动服务，再验证网站、ThinkPHP API、数据库、Session、上传。

安装包 ZIP 解压后的 `Install.cmd` 可直接使用。若从 Git 检出 `installer/` 运行，需要先把 `dist/` 中的**原始运行包 ZIP**复制到脚本旁，或用 `-ArchivePath` 显式指定它。

脚本校验运行包固定 SHA-256、逐文件哈希和目标规格，保留原 `php.ini`、自装扩展、自定义文件与 ACL。旧目录改名为同级 `php7.3.4nts.before-php734-port-时间编号`，新版放回原 `php7.3.4nts` 路径。安装工具包目录只存工具与 ZIP，不参与网站运行。不要提前删除旧目录备份。

替换后会用原 INI 检查启动、已加载扩展是否保留、Session 上传进度配置和新增配置是否存在。检查失败会尝试自动恢复，并保留失败版本。存在链接/联接目录、外部扫描 INI、无法读取路径的 PHP 进程等情况时拒绝自动替换。此检查不覆盖所有第三方扩展行为或全部业务功能。

### 回滚

先停服务，以管理员身份运行 `Rollback.cmd`，输入相同 PHP 目录。它默认寻找最近一次成功安装的记录，恢复安装前整个 PHP 目录，保留当前目录为同级 `.after-php734-port-...`。安装后修改过的配置保留在这个目录，需要时人工取回，不会自动合并到旧配置。成功后再启动服务。

PowerShell 5.1 示例（在脚本目录运行，替换示例路径）：

```powershell
# 只预检查 / Preflight only
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-Php734Port.ps1 -PhpDir 'D:\phpstudy_pro\Extensions\php\php7.3.4nts' -ArchivePath 'C:\Downloads\php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip' -CheckOnly

# 安装 / Install
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-Php734Port.ps1 -PhpDir 'D:\phpstudy_pro\Extensions\php\php7.3.4nts' -ArchivePath 'C:\Downloads\php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip'

# 回滚 / Roll back
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Rollback-Php734Port.ps1 -PhpDir 'D:\phpstudy_pro\Extensions\php\php7.3.4nts'
```

`ExecutionPolicy Bypass` 仅针对这个进程，不永久修改执行策略，也不能覆盖组织策略。意外中断时，保持服务停止，依据同级 `.php734-port-install-...json` 中的 `backup_dir` 恢复。可通过 `-ReceiptPath <记录路径>` 指定中断的记录。若遗留 `.php734-port.lock`，确认没有安装/回滚任务运行后再删除锁；不要删除备份。

### 检查网站实际加载的版本

版本号仍为 7.3.4。可临时在网站中运行下面的只读检查，完成后删除文件：

```php
<?php
header('Content-Type: text/plain; charset=utf-8');
echo 'PHP: ', PHP_VERSION, "\nBinary: ", PHP_BINARY,
     "\nINI: ", php_ini_loaded_file(), "\n";
$all = ini_get_all(null, false);
foreach (['memory_hard_limit_percent', 'max_multipart_body_parts'] as $name) {
    echo $name, ': ', array_key_exists($name, $all)
        ? var_export($all[$name], true) : 'NOT SUPPORTED', "\n";
}
```

程序路径应指向目标 `php7.3.4nts\php-cgi.exe`。未显式设置时第一项可能为 `NULL`，第二项为 `'-1'`；这个检查只能识别新增配置存在，完整文件一致性由安装时的哈希校验确认。

### 上传问题

这两项新增 INI 使用默认策略，不需要为了正常上传单独添加。文件字节数仍受 Nginx、PHP 上传限制和业务配置影响。Nginx 413 通常是请求体限制；大文件 500 需要错误日志诊断，可能涉及内存超限、超时、业务代码或本移植路径。不要用这些状态码认定防护成功。

### 验证限制

脚本在 Windows 11 / Windows PowerShell 5.1 的隔离目录中完成了 12 项检查。Windows Server 2019、phpStudy 服务管理、实际 ThinkPHP 应用与所有大文件路径尚未完成独立实机验证。

## English

**v3 installer update:** launchers now catch invocation errors and inspect script exit codes, fixing the false `Completed` message after a version rejection. PowerShell versions below 5.1 select the 2.0-compatible entry point; Server 2008 R2 SP1 users can explicitly run **`Install-Legacy.cmd`** and **`Rollback-Legacy.cmd`**. See the [legacy bilingual guide](LEGACY-INSTALL.zh-en.md), including the actual-engine validation limits. PHP runtime bytes are unchanged.

### Target and install

This is a complete runtime-directory replacement for **Windows x64 / PHP 7.3.4 / NTS / VC15**, not a phpStudy plugin. The extracted installer folder is not the directory your websites should execute.

1. Download the [bilingual installer ZIP](https://github.com/yzw641725631-boop/windows-php7-security-backports-for-PHP2Shell/releases/download/php-7.3.4-php2shell-20261023-rc3/phpStudy-PHP-7.3.4-nts-VC15-x64-unofficial-port-install-kit-v3-20261023.zip), verify [SHA256SUMS.txt](../dist/SHA256SUMS.txt), and extract it outside the target PHP directory. Leave the inner runtime ZIP intact.
2. Confirm the site's active PHP directory, such as `D:\phpstudy_pro\Extensions\php\php7.3.4nts`. It must contain `php.exe`, `php-cgi.exe`, `php7.dll` and `php.ini`. Allow about twice the current PHP directory size in additional free disk space.
3. **Stop phpStudy services first.** Closing its window may leave workers running. Stop any supervising service that respawns workers. The scripts neither control services nor kill existing workers.
4. Run `Install.cmd` as Administrator and enter the active PHP directory. Interactive messages are currently Chinese.
5. After the success message, record the backup/receipt paths, restart services and validate the website, APIs, database, Session and uploads.

The self-contained kit already includes its runtime ZIP. When using the scripts from a Git checkout, copy the original ZIP from `dist/` next to the scripts, or pass `-ArchivePath` as in the PowerShell examples above.

The installer checks fixed archive and per-file hashes, target version and architecture. It retains `php.ini`, add-ons, custom files and ACLs, renames the original directory to a sibling `.before-php734-port-...` backup, and activates the candidate at the original path. phpStudy therefore keeps the same PHP path. Post-activation startup/extension/configuration checks trigger automatic recovery attempts on failure. Linked directories, externally scanned INI files and unverifiable PHP process paths block automatic installation. These checks are not a complete third-party-extension or application test.

### Rollback and interruption recovery

Stop services, run `Rollback.cmd` as Administrator, and enter the same directory. It restores the latest successful installation's original-directory snapshot and keeps the current installation in a sibling `.after-php734-port-...` folder. Post-install configuration edits are retained there, not merged automatically. Restart services after success.

The PowerShell examples above support preflight, explicit archive paths and rollback. `ExecutionPolicy Bypass` is process-local and does not bypass organization policy. For an interrupted operation, keep services stopped and use the installation receipt's `backup_dir`; `-ReceiptPath` selects a receipt explicitly. Remove a stale `.php734-port.lock` only after confirming no installation/rollback task is running. Keep backups.

### Runtime verification and upload errors

The PHP snippet above checks the version, executable/configuration paths and the presence of both added directives. Run it temporarily in the actual website and delete it afterward. `NULL` for `memory_hard_limit_percent` and `'-1'` for `max_multipart_body_parts` are normal when omitted. Directive presence is not a complete runtime hash verification or security certification.

Default settings do not directly limit uploaded file bytes. Nginx, PHP upload directives and application rules still apply. HTTP 413 often indicates a request-body limit; HTTP 500 requires logs and can reflect memory exhaustion, timeouts, application errors or a source-port defect. Neither status proves exploitation was prevented.

The scripts' twelve isolated checks ran on Windows 11 / Windows PowerShell 5.1. Windows Server 2019, phpStudy service management, target ThinkPHP applications and all large-upload paths have not undergone complete independent validation.
