#requires -Version 5.1
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PhpRoot([string]$Value) {
    if ([string]::IsNullOrWhiteSpace($Value)) {
        $Value = Read-Host '请输入 phpStudy 当前 PHP 7.3.4 目录（其中应有 php.exe 和 php.ini）'
    }
    $resolved = (Resolve-Path -LiteralPath $Value.Trim().Trim('"') -ErrorAction Stop).ProviderPath
    $resolved = [IO.Path]::GetFullPath($resolved).TrimEnd('\')
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) { throw 'PHP 路径必须是已存在的目录。' }
    if ($resolved -eq [IO.Path]::GetPathRoot($resolved).TrimEnd('\')) { throw '不能选择磁盘根目录。' }
    foreach ($name in @('php.exe', 'php-cgi.exe', 'php7.dll', 'php.ini')) {
        if (-not (Test-Path -LiteralPath (Join-Path $resolved $name) -PathType Leaf)) {
            throw "目录中缺少 $name，请确认选择的是 phpStudy 正在使用的 PHP 目录。"
        }
    }
    Assert-NoReparsePoints $resolved
    return $resolved
}

function Assert-NoReparsePoints([string]$Path) {
    $current = Get-Item -LiteralPath $Path -Force
    while ($null -ne $current) {
        if (($current.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "不支持链接或联接目录：$($current.FullName)" }
        $current = $current.Parent
    }
    $links = @(Get-ChildItem -LiteralPath $Path -Recurse -Force | Where-Object {
        ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
    })
    if ($links.Count -ne 0) { throw 'PHP 目录内含符号链接或目录联接；请先人工处理，脚本没有修改原目录。' }
}

function Assert-PhpStopped([string]$Root) {
    # No service or process is stopped by this script. Unknown PHP paths require elevation.
    $items = @(Get-CimInstance -ClassName Win32_Process -Filter "Name = 'php.exe' OR Name = 'php-cgi.exe' OR Name = 'php-win.exe' OR Name = 'phpdbg.exe'")
    $unknown = @($items | Where-Object { [string]::IsNullOrWhiteSpace($_.ExecutablePath) })
    if ($unknown.Count -gt 0) {
        throw '无法读取某些 PHP 进程的程序路径。请停止 phpStudy 服务，并以管理员身份重新运行安装/回滚脚本。'
    }
    $prefix = $Root.TrimEnd('\') + '\'
    $busy = @($items | Where-Object { $_.ExecutablePath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) })
    if ($busy.Count -gt 0) {
        throw "目标目录仍有 PHP 进程运行（PID：$(($busy.ProcessId -join ', '))）。请在 phpStudy 停止服务并退出会自动重启 PHP 的管理程序，然后重试。"
    }
}

function New-OperationContext([string]$Root) {
    $parent = [IO.Path]::GetDirectoryName($Root)
    $leaf = [IO.Path]::GetFileName($Root)
    $id = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $work = Join-Path $parent ('.php734-port-work-' + $id)
    $lock = Join-Path $parent ($leaf + '.php734-port.lock')
    $stream = [IO.File]::Open($lock, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    return [pscustomobject]@{ Root = $Root; Parent = $parent; Leaf = $leaf; Id = $id; Work = $work; Lock = $lock; Stream = $stream }
}

function Close-OperationContext($Context) {
    if ($null -eq $Context) { return }
    try {
        if (Test-Path -LiteralPath $Context.Work) {
            $absolute = [IO.Path]::GetFullPath($Context.Work).TrimEnd('\')
            if ([IO.Path]::GetDirectoryName($absolute) -ne $Context.Parent -or
                -not [IO.Path]::GetFileName($absolute).StartsWith('.php734-port-work-')) {
                throw '拒绝清理范围异常的临时目录。'
            }
            Assert-NoReparsePoints $absolute
            Remove-Item -LiteralPath $absolute -Recurse -Force
        }
    } finally {
        $Context.Stream.Dispose()
        Remove-Item -LiteralPath $Context.Lock -Force
    }
}

function ConvertTo-NativeArgument([string]$Value) {
    # Windows CommandLineToArgvW/CRT quoting, including embedded quotes and trailing slashes.
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-PhpCommand([string]$Exe, [string[]]$Arguments, [string]$WorkingDirectory) {
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $Exe
    $start.Arguments = (($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' ')
    $start.WorkingDirectory = $WorkingDirectory
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = $true
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $start
    try {
        if (-not $process.Start()) { throw '无法启动 PHP。' }
        $outTask = $process.StandardOutput.ReadToEndAsync()
        $errTask = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(30000)) {
            $process.Kill()
            $process.WaitForExit()
            throw 'PHP 启动检查超过 30 秒，已停止本脚本启动的检查进程。'
        }
        $stdout = $outTask.GetAwaiter().GetResult()
        $stderr = $errTask.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0 -or -not [string]::IsNullOrWhiteSpace($stderr)) {
            $message = ($stderr + $stdout)
            if ($message.Length -gt 1600) { $message = $message.Substring(0, 1600) }
            throw "PHP 检查失败（退出码 $($process.ExitCode)）：$message"
        }
        return $stdout
    } finally { $process.Dispose() }
}

function Write-Probe([string]$Work) {
    [void][IO.Directory]::CreateDirectory($Work)
    $path = Join-Path $Work 'check-php734.php'
    $code = @'
<?php
$extensions = array_unique(array_merge(get_loaded_extensions(), get_loaded_extensions(true)));
sort($extensions, SORT_STRING);
echo 'PHP734CHECK:', json_encode(array(
    'version' => PHP_VERSION, 'zts' => PHP_ZTS, 'bits' => PHP_INT_SIZE * 8,
    'os' => PHP_OS, 'ini' => php_ini_loaded_file(),
    'scanned' => php_ini_scanned_files(), 'extensions' => $extensions,
    'hard_limit' => ini_get('memory_hard_limit_percent'),
    'session_progress' => ini_get('session.upload_progress.enabled'),
    'functional' => json_decode(json_encode(array('a' => 42)), true)['a'] === 42
));
'@
    [IO.File]::WriteAllText($path, $code, (New-Object Text.UTF8Encoding($false)))
    return $path
}

function Test-PhpRuntime([string]$Root, [string]$Probe, [switch]$Configured, [switch]$RequirePort) {
    $exe = Join-Path $Root 'php.exe'
    $version = Invoke-PhpCommand $exe @('-n', '-v') $Root
    if ($version -notmatch 'PHP 7\.3\.4\s' -or $version -notmatch 'NTS MSVC15.*x64') {
        throw '此包仅适用于 PHP 7.3.4 / NTS / VC15 / x64；当前 PHP 规格不同，不能自动替换。'
    }
    $arguments = @('-n', '-f', $Probe)
    if ($Configured) { $arguments = @('-c', (Join-Path $Root 'php.ini'), '-d', 'display_errors=stderr', '-d', 'log_errors=0', '-f', $Probe) }
    $output = Invoke-PhpCommand $exe $arguments $Root
    if (-not $output.StartsWith('PHP734CHECK:')) { throw 'PHP 检查出现额外输出或启动警告；没有通过配置检查。' }
    $info = $output.Substring('PHP734CHECK:'.Length) | ConvertFrom-Json
    if ($info.version -ne '7.3.4' -or $info.zts -ne 0 -or $info.bits -ne 64 -or $info.os -ne 'WINNT' -or -not $info.functional) {
        throw 'PHP 版本、架构或基础执行检查不符。'
    }
    if ($RequirePort -and $info.hard_limit -ceq $false) { throw '未检测到本次移植新增的内存硬限制配置。' }
    if ($Configured) {
        if ([IO.Path]::GetFullPath($info.ini) -ne (Join-Path $Root 'php.ini')) { throw 'PHP 没有加载目标目录中的 php.ini。' }
        if ($info.scanned -is [string] -and -not [string]::IsNullOrWhiteSpace($info.scanned)) { throw '检测到额外扫描的 INI 文件；为避免漏迁移配置，请人工核对后部署。' }
    }
    [void](Invoke-PhpCommand (Join-Path $Root 'php-cgi.exe') @('-n', '-v') $Root)
    return $info
}

function Copy-PhpDirectory([string]$Source, [string]$Destination) {
    [void][IO.Directory]::CreateDirectory($Destination)
    Get-ChildItem -LiteralPath $Source -Force | Copy-Item -Destination $Destination -Recurse -Force
    # Retain explicit ACLs as well as PHP configuration and third-party extensions.
    Set-Acl -LiteralPath $Destination -AclObject (Get-Acl -LiteralPath $Source)
    foreach ($item in Get-ChildItem -LiteralPath $Source -Recurse -Force) {
        $relative = $item.FullName.Substring($Source.Length).TrimStart('\')
        Set-Acl -LiteralPath (Join-Path $Destination $relative) -AclObject (Get-Acl -LiteralPath $item.FullName)
    }
}

function Write-Receipt([string]$Path, $Receipt) {
    $json = $Receipt | ConvertTo-Json -Depth 8
    [IO.File]::WriteAllText($Path, $json, (New-Object Text.UTF8Encoding($true)))
}

function Assert-Sibling([string]$Path, [string]$Parent, [string]$Prefix) {
    $full = [IO.Path]::GetFullPath($Path).TrimEnd('\')
    if ([IO.Path]::GetDirectoryName($full) -ne $Parent -or -not [IO.Path]::GetFileName($full).StartsWith($Prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw '备份或恢复目录不在指定 PHP 目录的同级范围内。'
    }
    return $full
}
