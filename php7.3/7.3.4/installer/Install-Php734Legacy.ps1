#requires -Version 2.0
[CmdletBinding()]
param([string]$PhpDir, [string]$ArchivePath, [string]$RuntimeDir, [switch]$CheckOnly)
$legacyDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $legacyDirectory 'Php734-Legacy.Common.ps1')
$context = $null
$receipt = $null
$receiptPath = $null
$oldMoved = $false
$candidateActive = $false
try {
    Write-Host 'PHP 7.3.4 非官方源码补丁版：PowerShell 2.0 及以上安装助手'
    Write-Host '请先停止 phpStudy 服务和自动拉起 PHP 的管理程序。脚本不会强杀进程或重启服务。'
    $root = Get-LegacyRoot $PhpDir
    $kit = Get-LegacyFullPath $legacyDirectory
    if ($kit -eq $root -or $kit.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) { throw '请把部署包放在原 PHP 目录之外。' }
    if (-not (Test-Blank $env:PHP_INI_SCAN_DIR)) { throw '当前环境设置了 PHP_INI_SCAN_DIR，请先核对外部配置。' }
    Assert-LegacyStopped $root
    $tools = Initialize-LegacyTools $kit
    $context = New-LegacyContext $root
    [void][IO.Directory]::CreateDirectory($context['Work'])
    $before = Test-LegacyPhp $root $tools -Configured
    $originalIni = Get-LegacyHash (Join-Path $root 'php.ini')
    if (Test-Blank $RuntimeDir) {
        if (Test-Blank $ArchivePath) { $ArchivePath = Join-Path $kit 'php-7.3.4-nts-Win32-VC15-x64-unofficial-source-port-20261022.zip' }
        $archive = (Resolve-Path -LiteralPath $ArchivePath).ProviderPath
        if ((Get-LegacyHash $archive) -ne '879005e1a853258100e1db88db635dc955046123c4732b14d36b8f50a9a5d730') { throw '运行包 ZIP SHA-256 不匹配。' }
        $unpacked = Join-Path $context['Work'] 'unpacked'
        $reply = Invoke-LegacyPhp (Join-Path $root 'php.exe') @('-n', '-f', $tools['Helper'], '--', 'extract', $archive, $unpacked, $tools['Hashes']) $root
    } else {
        $resolvedRuntime = Resolve-Path -LiteralPath $RuntimeDir
        $unpacked = Get-LegacyFullPath $resolvedRuntime.ProviderPath
        if ($unpacked -eq $root -or $unpacked.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase) -or $root.StartsWith($unpacked + '\', [StringComparison]::OrdinalIgnoreCase)) {
            throw '已解压的新运行包必须与原 PHP 目录分开存放。'
        }
        Assert-LegacyTree $unpacked
        $reply = Invoke-LegacyPhp (Join-Path $root 'php.exe') @('-n', '-f', $tools['Helper'], '--', 'verify', $unpacked, $tools['Hashes']) $root
    }
    if ($reply -notmatch '^PHP734VERIFY:\d+$') { throw '运行包文件校验没有完成。' }
    [void](Test-LegacyPhp $unpacked $tools -RequirePort)
    if ($CheckOnly) {
        Write-Host '预检查通过：原 PHP 目录没有替换，服务没有重启。' -ForegroundColor Green
    } else {
        $candidate = Join-Path $context['Work'] 'candidate'
        Copy-LegacyDirectory $root $candidate
        $reply = Invoke-LegacyPhp (Join-Path $root 'php.exe') @('-n', '-f', $tools['Helper'], '--', 'overlay', $unpacked, $candidate, $tools['Hashes']) $root
        if ($reply -notmatch '^PHP734VERIFY:\d+$') { throw '候选运行文件复制校验失败。' }
        if ((Get-LegacyHash (Join-Path $candidate 'php.ini')) -ne $originalIni) { throw '原配置复制校验失败。' }
        $reply = Invoke-LegacyPhp (Join-Path $candidate 'php.exe') @('-n', '-f', $tools['Helper'], '--', 'verify-merged', $candidate, $tools['Hashes']) $candidate
        if ($reply -notmatch '^PHP734VERIFY:\d+$') { throw '候选目录文件校验失败。' }
        [void](Test-LegacyPhp $candidate $tools -RequirePort)
        $backup = Assert-LegacySibling (Join-Path $context['Parent'] ($context['Leaf'] + '.before-php734-port-legacy-' + $context['Id'])) $context['Parent'] ($context['Leaf'] + '.before-php734-port-legacy-')
        $receiptPath = Join-Path $context['Parent'] ($context['Leaf'] + '.php734-legacy-install-' + $context['Id'] + '.xml')
        $receipt = @{ Format='php734-legacy-install-v1'; Status='prepared'; Created=(Get-Date).ToString('o');
                      PhpDir=$root; BackupDir=$backup; OriginalIniSha256=$originalIni;
                      RuntimeZipSha256='879005e1a853258100e1db88db635dc955046123c4732b14d36b8f50a9a5d730';
                      BeforeExtensions=$before['Extensions']; AfterExtensions=@(); PreservedAfterRollback='' }
        Save-LegacyReceipt $receiptPath $receipt
        Assert-LegacyStopped $root
        Move-LegacyDirectory $root $backup $root
        $oldMoved = $true
        Move-LegacyDirectory $candidate $root $root
        $candidateActive = $true
        $receipt['Status'] = 'checking'
        Save-LegacyReceipt $receiptPath $receipt
        $after = Test-LegacyPhp $root $tools -Configured -RequirePort
        foreach ($name in $before['Extensions']) { if ($after['Extensions'] -notcontains $name) { throw ('替换后缺少原已加载扩展：' + $name) } }
        if ($after['Progress'] -ne $before['Progress']) { throw 'Session 上传进度配置发生变化。' }
        if ((Get-LegacyHash (Join-Path $root 'php.ini')) -ne $originalIni) { throw '原 php.ini 哈希不一致。' }
        $receipt['AfterExtensions'] = $after['Extensions']
        $receipt['Status'] = 'installed'
        Save-LegacyReceipt $receiptPath $receipt
        Write-Host '安装及配置/扩展启动检查通过。现在可回到 phpStudy 启动服务。' -ForegroundColor Green
        Write-Host ('原目录完整备份：' + $backup)
        Write-Host ('安装记录：' + $receiptPath)
        Write-Host '请验证网站/API、数据库、Session 和上传。回滚请使用 Rollback-Legacy.cmd。'
    }
} catch {
    $reason = $_.Exception.Message
    if ($oldMoved) {
        try {
            Assert-LegacyStopped $root
            if ($candidateActive) {
                $failed = Assert-LegacySibling (Join-Path $context['Parent'] ($context['Leaf'] + '.failed-php734-port-legacy-' + $context['Id'])) $context['Parent'] ($context['Leaf'] + '.failed-php734-port-legacy-')
                Move-LegacyDirectory $root $failed $root
                $receipt['PreservedAfterRollback'] = $failed
            }
            Move-LegacyDirectory $receipt['BackupDir'] $root $root
            $receipt['Status'] = 'failed-rolled-back'
            Save-LegacyReceipt $receiptPath $receipt
            Write-Host '检查失败，原 PHP 目录已自动恢复。' -ForegroundColor Yellow
        } catch {
            Write-Host ('自动恢复未完成：' + $_.Exception.Message) -ForegroundColor Red
            Write-Host ('请保持服务停止，按安装记录恢复原目录：' + $receiptPath) -ForegroundColor Red
        }
    }
    Write-Host ('安装未完成：' + $reason) -ForegroundColor Red
    exit 1
} finally { if ($null -ne $context) { Close-LegacyContext $context } }
exit 0
