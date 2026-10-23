#requires -Version 2.0
[CmdletBinding()]
param([ValidateSet('Install', 'Rollback')][string]$Operation = 'Install')
$ErrorActionPreference = 'Stop'
try {
    $directory = Split-Path -Parent $MyInvocation.MyCommand.Path
    if ($PSVersionTable.PSVersion -lt [Version]'5.1') {
        Write-Host '检测到旧版 PowerShell，使用 2.0 兼容安装/回滚助手。'
        $entry = $Operation + '-Php734Legacy.ps1'
    } else {
        $entry = $Operation + '-Php734Port.ps1'
    }
    $global:LASTEXITCODE = 0
    & (Join-Path $directory $entry)
    $invocationSucceeded = $?
    if (-not $invocationSucceeded -or $LASTEXITCODE -ne 0) { exit 1 }
} catch {
    Write-Host ('操作失败：' + $_.Exception.Message) -ForegroundColor Red
    exit 1
}
exit 0
