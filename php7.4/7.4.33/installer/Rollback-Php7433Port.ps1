#requires -Version 5.1
[CmdletBinding()]
param([string]$PhpDir, [string]$ReceiptPath)
. (Join-Path $PSScriptRoot 'Php7433-Deployment.Common.ps1')
$context = $null
$currentMoved = $false
$backupRestored = $false
try {
    Write-Host '请先在 phpStudy 停止服务。回滚将恢复安装前的整个 PHP 目录。'
    if ([string]::IsNullOrWhiteSpace($ReceiptPath)) {
        $root = Get-PhpRoot $PhpDir
        $parent = [IO.Path]::GetDirectoryName($root)
        $leaf = [IO.Path]::GetFileName($root)
        $records = @(Get-ChildItem -LiteralPath $parent -File | Where-Object {
            $_.Name.StartsWith($leaf + '.php7433-port-install-') -and $_.Extension -eq '.json'
        } | Sort-Object Name -Descending)
        foreach ($record in $records) {
            $data = Get-Content -LiteralPath $record.FullName -Raw -Encoding UTF8 | ConvertFrom-Json
            if ($data.php_dir -eq $root -and $data.status -eq 'installed') { $ReceiptPath = $record.FullName; break }
        }
        if ([string]::IsNullOrWhiteSpace($ReceiptPath)) { throw '没有找到已成功安装的记录；如需恢复中断的安装，请指定 -ReceiptPath。' }
    }
    $receipt = Get-Content -LiteralPath $ReceiptPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($receipt.format -ne 'php7433-source-port-install-v1' -or $receipt.status -notin @('installed', 'checking', 'prepared')) { throw '安装记录无效或已经回滚。' }
    $root = [IO.Path]::GetFullPath($receipt.php_dir).TrimEnd('\')
    if (-not [string]::IsNullOrWhiteSpace($PhpDir) -and [IO.Path]::GetFullPath($PhpDir.Trim().Trim('"')).TrimEnd('\') -ne $root) { throw '指定的 PHP 目录与安装记录不一致。' }
    $parent = [IO.Path]::GetDirectoryName($root)
    $leaf = [IO.Path]::GetFileName($root)
    $backup = Assert-Sibling $receipt.backup_dir $parent ($leaf + '.before-php7433-port-')
    [void](Get-PhpRoot $backup)
    if (Test-Path -LiteralPath $root) { [void](Get-PhpRoot $root) }
    Assert-PhpStopped $root
    $context = New-OperationContext $root
    $probe = Write-Probe $context.Work
    [void](Test-PhpRuntime $backup $probe)
    $preserved = Assert-Sibling (Join-Path $parent ($leaf + '.after-php7433-port-' + $context.Id)) $parent ($leaf + '.after-php7433-port-')
    Assert-PhpStopped $root
    if (Test-Path -LiteralPath $root) {
        Rename-Item -LiteralPath $root -NewName ([IO.Path]::GetFileName($preserved))
        $currentMoved = $true
    }
    Rename-Item -LiteralPath $backup -NewName $leaf
    $backupRestored = $true
    [void](Test-PhpRuntime $root $probe -Configured)
    $receipt.status = 'rolled-back'
    $receipt.preserved_after_rollback = $(if ($currentMoved) { $preserved } else { $null })
    Write-Receipt $ReceiptPath $receipt
    Write-Host '回滚完成，可在 phpStudy 启动服务。' -ForegroundColor Green
    Write-Host '配置也恢复到安装前的快照。安装后的配置变动，请从保留的目录中人工取回。'
    if ($currentMoved) { Write-Host "回滚前目录完整保留在：$preserved" }
} catch {
    $reason = $_.Exception.Message
    if ($currentMoved -and -not $backupRestored -and -not (Test-Path -LiteralPath $root)) {
        Rename-Item -LiteralPath $preserved -NewName $leaf
    }
    Write-Host "回滚未完成：$reason" -ForegroundColor Red
    Write-Host '请保持服务停止，检查记录中的原目录备份。'
    exit 1
} finally {
    if ($null -ne $context) { Close-OperationContext $context }
}
