#requires -Version 2.0
[CmdletBinding()]
param([string]$PhpDir, [string]$ReceiptPath)
$legacyDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
. (Join-Path $legacyDirectory 'Php734-Legacy.Common.ps1')
$context = $null
$currentMoved = $false
$restored = $false
try {
    Write-Host '请先停止 phpStudy 服务。本工具恢复 PowerShell 2.0 兼容安装助手创建的完整备份。'
    if (Test-Blank $ReceiptPath) {
        $root = Get-LegacyRoot $PhpDir
        $parent = [IO.Path]::GetDirectoryName($root)
        $leaf = [IO.Path]::GetFileName($root)
        $records = @(Get-ChildItem -LiteralPath $parent -Force | Where-Object {
            -not $_.PSIsContainer -and $_.Name.StartsWith($leaf + '.php734-legacy-install-') -and $_.Extension -eq '.xml'
        } | Sort-Object Name -Descending)
        foreach ($file in $records) {
            $record = Import-Clixml -Path $file.FullName
            if ($record['Format'] -eq 'php734-legacy-install-v1' -and $record['PhpDir'] -eq $root -and $record['Status'] -eq 'installed') {
                $ReceiptPath = $file.FullName
                break
            }
        }
        if (Test-Blank $ReceiptPath) { throw '没有找到本兼容助手的成功安装记录；旧版 5.1 助手的 JSON 记录请用对应工具回滚。' }
    }
    $receipt = Import-Clixml -Path $ReceiptPath
    if ($receipt['Format'] -ne 'php734-legacy-install-v1' -or @('installed', 'checking', 'prepared') -notcontains $receipt['Status']) { throw '记录无效或已回滚。' }
    $root = Get-LegacyFullPath $receipt['PhpDir']
    if (-not (Test-Blank $PhpDir)) {
        $requested = $PhpDir.Trim()
        $requested = $requested.Trim('"')
        $requested = Get-LegacyFullPath $requested
        if ($requested -ne $root) { throw '目标 PHP 路径与安装记录不一致。' }
    }
    $parent = [IO.Path]::GetDirectoryName($root)
    $leaf = [IO.Path]::GetFileName($root)
    $backup = Assert-LegacySibling $receipt['BackupDir'] $parent ($leaf + '.before-php734-port-legacy-')
    [void](Get-LegacyRoot $backup)
    if (Test-Path -LiteralPath $root) { [void](Get-LegacyRoot $root) }
    Assert-LegacyStopped $root
    $tools = Initialize-LegacyTools $legacyDirectory
    $context = New-LegacyContext $root
    [void](Test-LegacyPhp $backup $tools)
    $preserved = Assert-LegacySibling (Join-Path $parent ($leaf + '.after-php734-port-legacy-' + $context['Id'])) $parent ($leaf + '.after-php734-port-legacy-')
    Assert-LegacyStopped $root
    if (Test-Path -LiteralPath $root) {
        Move-LegacyDirectory $root $preserved $root
        $currentMoved = $true
    }
    Move-LegacyDirectory $backup $root $root
    $restored = $true
    [void](Test-LegacyPhp $root $tools -Configured)
    $receipt['Status'] = 'rolled-back'
    if ($currentMoved) { $receipt['PreservedAfterRollback'] = $preserved }
    Save-LegacyReceipt $ReceiptPath $receipt
    Write-Host '回滚完成，可在 phpStudy 启动服务。' -ForegroundColor Green
    if ($currentMoved) { Write-Host ('回滚前目录保留在：' + $preserved) }
    Write-Host '配置恢复到安装前快照，安装后的配置改动可从保留目录人工取回。'
} catch {
    $reason = $_.Exception.Message
    if ($currentMoved -and -not $restored -and -not (Test-Path -LiteralPath $root)) { Move-LegacyDirectory $preserved $root $root }
    Write-Host ('回滚未完成：' + $reason) -ForegroundColor Red
    Write-Host '请保持服务停止并保留备份。'
    exit 1
} finally { if ($null -ne $context) { Close-LegacyContext $context } }
exit 0
