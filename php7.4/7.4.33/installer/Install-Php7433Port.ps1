#requires -Version 5.1
[CmdletBinding()]
param([string]$PhpDir, [string]$ArchivePath, [switch]$CheckOnly)
. (Join-Path $PSScriptRoot 'Php7433-Deployment.Common.ps1')

$archiveName = 'php-7.4.33-nts-Win32-VC15-x64-unofficial-upstream-backport-20261023.zip'
$expectedSha = 'd4cda957de94520e476854fe3a72188de764f94defd795d3a8d39d5c5bfcbd83'
$context = $null
$receipt = $null
$receiptPath = $null
$oldMoved = $false
$candidateActive = $false
try {
    Write-Host 'PHP 7.4.33 非官方源码补丁版：Windows x64 / NTS / VC15'
    Write-Host '请先在 phpStudy 停止服务。脚本不会自动停止或启动服务器服务。'
    Write-Host '官方 7.4 补丁：OOM 时退出当前工作进程；Session 上传进度回调停用；普通上传保留。'
    $root = Get-PhpRoot $PhpDir
    $kitRoot = [IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\')
    if ($kitRoot -eq $root -or $kitRoot.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)) {
        throw '请把安装包解压到 PHP 目录外，再运行脚本。'
    }
    if (-not [string]::IsNullOrWhiteSpace($env:PHP_INI_SCAN_DIR)) { throw '当前环境设置了 PHP_INI_SCAN_DIR；请先人工核对外部配置，脚本没有替换 PHP。' }
    Assert-PhpStopped $root
    if ([string]::IsNullOrWhiteSpace($ArchivePath)) { $ArchivePath = Join-Path $PSScriptRoot $archiveName }
    $archive = (Resolve-Path -LiteralPath $ArchivePath).ProviderPath
    if ((Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedSha) {
        throw '运行包 SHA-256 不匹配。请使用同一部署包内的原始 ZIP，不要混用其他版本。'
    }
    $context = New-OperationContext $root
    $probe = Write-Probe $context.Work
    $before = Test-PhpRuntime $root $probe -Configured
    $iniBefore = (Get-FileHash -LiteralPath (Join-Path $root 'php.ini') -Algorithm SHA256).Hash
    $unpacked = Join-Path $context.Work 'unpacked'
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [IO.Compression.ZipFile]::OpenRead($archive)
    try {
        foreach ($entry in $zip.Entries) {
            $name = $entry.FullName.Replace('\', '/')
            if ($name.StartsWith('/') -or $name.Contains(':') -or $name -match '(^|/)\.\.?(/|$)') { throw 'ZIP 内含异常路径，拒绝解压。' }
        }
    } finally { $zip.Dispose() }
    [IO.Compression.ZipFile]::ExtractToDirectory($archive, $unpacked)
    $hashFile = Join-Path $unpacked 'UNOFFICIAL-BACKPORT-SHA256.json'
    $hashes = Get-Content -LiteralPath $hashFile -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($property in $hashes.PSObject.Properties) {
        $relative = $property.Name.Replace('/', '\')
        $file = [IO.Path]::GetFullPath((Join-Path $unpacked $relative))
        if (-not $file.StartsWith($unpacked + '\', [StringComparison]::OrdinalIgnoreCase) -or
            (Get-FileHash -LiteralPath $file -Algorithm SHA256).Hash.ToLowerInvariant() -ne $property.Value) {
            throw "运行包内部文件校验失败：$($property.Name)"
        }
    }
    [void](Test-PhpRuntime $unpacked $probe -RequirePort)
    if ($CheckOnly) {
        Write-Host '预检查通过；未替换 PHP、未创建备份、未重启服务。' -ForegroundColor Green
    } else {
        $candidate = Join-Path $context.Work 'candidate'
        Copy-PhpDirectory $root $candidate
        Get-ChildItem -LiteralPath $unpacked -Force | Copy-Item -Destination $candidate -Recurse -Force
        [void](Test-PhpRuntime $candidate $probe -RequirePort)
        if ((Get-FileHash -LiteralPath (Join-Path $candidate 'php.ini') -Algorithm SHA256).Hash -ne $iniBefore) { throw '配置文件复制校验失败。' }
        $backup = Assert-Sibling (Join-Path $context.Parent ($context.Leaf + '.before-php7433-port-' + $context.Id)) $context.Parent ($context.Leaf + '.before-php7433-port-')
        $receiptPath = Join-Path $context.Parent ($context.Leaf + '.php7433-port-install-' + $context.Id + '.json')
        $receipt = [ordered]@{
            format = 'php7433-source-port-install-v1'; status = 'prepared'; created = (Get-Date).ToString('o')
            php_dir = $root; backup_dir = $backup; archive_sha256 = $expectedSha; php_ini_sha256 = $iniBefore
            previous_extensions = @($before.extensions); installed_extensions = @(); preserved_after_rollback = $null
        }
        Write-Receipt $receiptPath $receipt
        Assert-PhpStopped $root
        Rename-Item -LiteralPath $root -NewName ([IO.Path]::GetFileName($backup))
        $oldMoved = $true
        Move-Item -LiteralPath $candidate -Destination $root
        $candidateActive = $true
        $receipt.status = 'checking'
        Write-Receipt $receiptPath $receipt
        $after = Test-PhpRuntime $root $probe -Configured -RequirePort
        foreach ($extension in $before.extensions) {
            if ($after.extensions -notcontains $extension) { throw "替换后缺少原已加载扩展：$extension" }
        }
        if ($before.session_progress -ne $after.session_progress) { throw 'Session 上传进度的配置发生变化。' }
        if ((Get-FileHash -LiteralPath (Join-Path $root 'php.ini') -Algorithm SHA256).Hash -ne $iniBefore) { throw '原 php.ini 校验不一致。' }
        $receipt.installed_extensions = @($after.extensions)
        $receipt.status = 'installed'
        Write-Receipt $receiptPath $receipt
        Write-Host '安装及配置/扩展启动检查通过。现在可回到 phpStudy 启动服务。' -ForegroundColor Green
        Write-Host "完整原目录备份：$backup"
        Write-Host "安装记录：$receiptPath"
        Write-Host '请检查网站/API、数据库、Session 和上传功能。php -v 仍显示 7.4.33；移植记录见 UNOFFICIAL-BACKPORT-MANIFEST.json。'
    }
} catch {
    $reason = $_.Exception.Message
    if ($oldMoved) {
        try {
            Assert-PhpStopped $root
            if ($candidateActive) {
                $failed = Assert-Sibling (Join-Path $context.Parent ($context.Leaf + '.failed-php7433-port-' + $context.Id)) $context.Parent ($context.Leaf + '.failed-php7433-port-')
                Rename-Item -LiteralPath $root -NewName ([IO.Path]::GetFileName($failed))
                $receipt.preserved_after_rollback = $failed
            }
            Rename-Item -LiteralPath $receipt.backup_dir -NewName $context.Leaf
            $receipt.status = 'failed-rolled-back'
            Write-Receipt $receiptPath $receipt
            Write-Host '检查未通过，原 PHP 目录已自动恢复。' -ForegroundColor Yellow
        } catch {
            Write-Host "自动恢复未完成：$($_.Exception.Message)" -ForegroundColor Red
            Write-Host "请保持服务停止；按安装记录手工恢复原目录：$receiptPath" -ForegroundColor Red
        }
    }
    Write-Host "安装未完成：$reason" -ForegroundColor Red
    exit 1
} finally {
    if ($null -ne $context) { Close-OperationContext $context }
}
