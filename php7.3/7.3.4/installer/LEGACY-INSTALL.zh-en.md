# Windows Server 2008 R2 / PowerShell 2.0 installer / 旧系统安装说明

## 中文

这个 v2 部署包修复了旧启动器在 PowerShell 版本不符时仍显示 `Completed` 的问题，并新增按 **PowerShell 2.0 / .NET 2.0 API** 编写的安装与回滚助手。PHP 运行包没有重新编译，仍是原来的 **PHP 7.3.4 / Windows x64 / NTS / VC15**，ZIP SHA-256：

```text
879005e1a853258100e1db88db635dc955046123c4732b14d36b8f50a9a5d730
```

### 在 Server 2008 R2 SP1 上操作

1. 将 **v2 完整部署包**解压到原 PHP 目录之外，助手、清单、PHP 文件和运行包 ZIP 要配套使用。
2. 在 phpStudy 停止服务，并停止会自动重新拉起 PHP 的管理程序。保持原 PHP 进程退出。
3. 右键 **`Install-Legacy.cmd` → 以管理员身份运行**。
4. 输入**正在使用的原 PHP 目录**，例如 `D:\phpstudy_pro\Extensions\php\php7.3.4nts`。不要填写安装工具包目录或新包的临时测试目录。
5. 只有看到 **“安装及配置/扩展启动检查通过”** 才表示安装成功。失败会显示 `FAILED`；不能仅凭窗口退出判断成功。
6. 成功后记下备份与记录路径，再回 phpStudy 启动服务，验证网站/API、数据库、Session、上传与外部接口。

新版 `Install.cmd` 也会按 PowerShell 版本选择助手；在这个旧系统上直接选 `Install-Legacy.cmd` 最明确。不需要为了本次部署升级 PowerShell。脚本仅对当前 PowerShell 进程使用执行策略参数，不永久修改系统执行策略，也不能覆盖组织组策略。

### 检查、备份与回滚

- 校验原运行 ZIP 和全部 **84 个运行文件**，并检查现有 PHP 规格、原 INI 启动及扩展。使用当前可运行的原 PHP 自带 ZIP/JSON 能力解压可信运行包，避免依赖新版 .NET 的 ZIP API。
- 备份旧目录，保留 `php.ini`、自装扩展、自定义文件和 ACL，新版仍放回原路径。只覆盖可信清单中的运行文件。
- 替换后使用原配置检查；失败时尝试自动恢复并保留失败版本。目录短暂被文件扫描等占用时有限重试，不强杀现有 PHP 进程。
- 兼容助手的安装记录为同级 **`.php734-legacy-install-...xml`**，备份目录含 `.before-php734-port-legacy-`。保持服务停止后，运行 **`Rollback-Legacy.cmd`** 恢复。
- 回滚会保留回滚前整个目录，安装后配置变化可从 `.after-php734-port-legacy-...` 人工取回，不自动合并。
- 本兼容回滚助手只处理它创建的 XML 记录；旧 5.1 助手创建的 JSON 记录仍用对应的原回滚工具。若兼容安装后升级了 PowerShell，仍选择 `Rollback-Legacy.cmd`。

在旧 PowerShell 窗口中可显式调用（路径换成实际位置）：

```powershell
# 预检查；仍需先停止目标 PHP 进程
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-Php734Legacy.ps1 -PhpDir 'D:\phpstudy_pro\Extensions\php\php7.3.4nts' -CheckOnly

# 使用已单独解压的新运行包；该目录须仅含原运行包的文件
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\Install-Php734Legacy.ps1 -PhpDir 'D:\phpstudy_pro\Extensions\php\php7.3.4nts' -RuntimeDir 'C:\php734-test'
```

若原 PHP 未编译 ZIP 扩展，可手动解压原运行包，再用 `-RuntimeDir`；仍会按外部固定清单校验文件和拒绝额外文件。该选项不是跳过哈希校验。

### 验证范围

兼容助手按 PowerShell 2.0 语法编写，进程捕获辅助类以 C# 2 语法针对 **.NET 2.0 引用程序集**编译检查成功。本地安装、回滚和启动器失败处理在 **Windows 11 / Windows PowerShell 5.1** 隔离目录验证。当前本机构建宿主无法运行真正的 PowerShell 2.0；**实际 Server 2008 R2 / PowerShell 2.0 的完整安装与业务仍待现场验证**。用户已提供原 PHP 规格及补丁版 CLI 在 Server 2008 R2 SP1 启动的截图，该事实不等于所有扩展与业务兼容。

PHP 引擎仍是原来的非官方移植候选版，没有因安装助手更新而取得独立安全认证；XML 大属性超时、第三方依赖和业务路径限制仍见版本 README。

## English

The v2 kit fixes the old launcher's false `Completed` message after a PowerShell version rejection and adds installation/rollback helpers written for **PowerShell 2.0 / .NET 2.0 APIs**. The PHP runtime is unchanged: **7.3.4 / Windows x64 / NTS / VC15**, with the ZIP hash shown above.

### Installation

Extract the complete v2 kit outside the active PHP directory. Stop phpStudy services and supervisors, run **`Install-Legacy.cmd` as Administrator**, and enter the original active PHP directory. Only the explicit installation/configuration-check success message indicates success; a failure must show `FAILED`. Start services and verify the application after success.

The updated generic launcher selects an entry point based on PowerShell version. The explicit legacy launcher is recommended on Server 2008 R2. No PowerShell upgrade is required by this deployment path. Execution-policy arguments are process-local and cannot override organization policy.

### Integrity and rollback

The helper verifies the unchanged runtime ZIP and all **84 runtime files**, checks target metadata/configuration/extensions, retains a full backup including INI/add-ons/custom files/ACLs and deploys at the same active path. Trusted extraction uses the existing PHP's ZIP/JSON support, avoiding newer .NET ZIP APIs. Only manifest-listed files are overlaid. Failed post-activation checks trigger recovery attempts; short-lived directory locks receive bounded retries without killing existing workers.

Legacy receipts are sibling `.php734-legacy-install-...xml` files and backups contain `.before-php734-port-legacy-`. Stop services and use **`Rollback-Legacy.cmd`** to restore the original snapshot. The current directory is preserved under `.after-php734-port-legacy-...`, including later configuration edits. They are not merged automatically.

The legacy rollback tool handles its own XML receipts. Original 5.1-installer JSON receipts require the original rollback tool. If PowerShell is upgraded after a legacy installation, continue using the explicit legacy rollback launcher.

The PowerShell examples above support preflight and pre-extracted runtime verification. `-RuntimeDir` still validates the fixed external manifest and rejects unlisted files; it does not bypass integrity checks. It can be used if the baseline PHP lacks ZIP support.

### Validation limits

The capture helper compiles with C# 2 against **.NET 2.0 reference assemblies**. Isolated installation/rollback/launcher checks ran on **Windows 11 / Windows PowerShell 5.1**. The local host cannot execute the actual PowerShell 2.0 engine, so **complete Server 2008 R2 / PowerShell 2.0 installation and business validation remains pending**. A user-reported screenshot confirms patched CLI startup on Server 2008 R2 SP1, not complete extension/application compatibility.

The unchanged PHP runtime remains an unofficial source-port candidate. Installer changes do not provide independent security certification or resolve its documented XML timeout, third-party dependency and business-path limitations.
