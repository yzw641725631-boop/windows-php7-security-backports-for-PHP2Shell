#requires -Version 2.0
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

function Test-Blank([string]$Value) {
    if ($null -eq $Value) { return $true }
    $trimmed = $Value.Trim()
    return ($trimmed.Length -eq 0)
}

function Get-LegacyFullPath([string]$Path) {
    $full = [IO.Path]::GetFullPath($Path)
    return $full.TrimEnd('\')
}

function Get-LegacyHash([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $algorithm = [Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $algorithm.ComputeHash($stream)
        $hex = [BitConverter]::ToString($bytes)
        $hex = $hex.Replace('-', '')
        return $hex.ToLowerInvariant()
    }
    finally { $stream.Close(); $algorithm.Clear() }
}

function Assert-LegacyTree([string]$Path) {
    $directory = Get-Item -LiteralPath $Path -Force
    if (-not $directory.PSIsContainer) { throw '路径必须是目录。' }
    $ancestor = $directory
    while ($null -ne $ancestor) {
        if (($ancestor.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw '目录或父目录中含链接/联接，拒绝自动处理。' }
        $ancestor = $ancestor.Parent
    }
    $pending = New-Object 'System.Collections.Generic.Queue[string]'
    $pending.Enqueue($directory.FullName)
    while ($pending.Count -gt 0) {
        $current = $pending.Dequeue()
        foreach ($entry in [IO.Directory]::GetFileSystemEntries($current)) {
            $attributes = [IO.File]::GetAttributes($entry)
            if (($attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw '目录内含链接/联接，拒绝自动处理。' }
            if (($attributes -band [IO.FileAttributes]::Directory) -ne 0) { $pending.Enqueue($entry) }
        }
    }
}

function Get-LegacyRoot([string]$Value) {
    if (Test-Blank $Value) { $Value = Read-Host '请输入原 PHP 7.3.4 目录（例如 D:\phpstudy_pro\Extensions\php\php7.3.4nts）' }
    $clean = $Value.Trim()
    $clean = $clean.Trim('"')
    $resolved = Resolve-Path -LiteralPath $clean
    $root = Get-LegacyFullPath $resolved.ProviderPath
    $volume = [IO.Path]::GetPathRoot($root)
    $volume = $volume.TrimEnd('\')
    if ($root -notmatch '^[A-Za-z]:\\' -or $root -eq $volume) {
        throw '请选择本地磁盘上的 PHP 目录，不能选择磁盘根目录或网络共享。'
    }
    foreach ($name in @('php.exe', 'php-cgi.exe', 'php7.dll', 'php.ini')) {
        if (-not (Test-Path -LiteralPath (Join-Path $root $name) -PathType Leaf)) { throw ('目标目录缺少 ' + $name) }
    }
    Assert-LegacyTree $root
    return $root
}

function Assert-LegacyStopped([string]$Root) {
    $processes = @(Get-WmiObject -Class Win32_Process -Filter "Name = 'php.exe' OR Name = 'php-cgi.exe' OR Name = 'php-win.exe' OR Name = 'phpdbg.exe'")
    $prefix = $Root.TrimEnd('\') + '\'
    $busy = @()
    foreach ($process in $processes) {
        if (Test-Blank $process.ExecutablePath) { throw '无法读取某些 PHP 进程路径。请先停止服务并以管理员身份运行。' }
        if ($process.ExecutablePath.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { $busy += [string]$process.ProcessId }
    }
    if ($busy.Count -gt 0) { throw ('原目录的 PHP 进程仍在运行，PID：' + ($busy -join ', ') + '。请先停止 phpStudy 服务和自动拉起 PHP 的管理程序。') }
}

function New-LegacyContext([string]$Root) {
    $parent = [IO.Path]::GetDirectoryName($Root)
    $leaf = [IO.Path]::GetFileName($Root)
    $guid = [Guid]::NewGuid()
    $random = $guid.ToString('N')
    $id = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + $random.Substring(0, 8)
    # Same lock as the modern installer prevents concurrent cross-version operations.
    $lock = Join-Path $parent ($leaf + '.php734-port.lock')
    $stream = [IO.File]::Open($lock, [IO.FileMode]::CreateNew, [IO.FileAccess]::Write, [IO.FileShare]::None)
    return @{ Root=$Root; Parent=$parent; Leaf=$leaf; Id=$id;
              Work=(Join-Path $parent ('.php734-legacy-work-' + $id)); Lock=$lock; Stream=$stream }
}

function Assert-LegacySibling([string]$Path, [string]$Parent, [string]$Prefix) {
    $full = Get-LegacyFullPath $Path
    $leaf = [IO.Path]::GetFileName($full)
    if ([IO.Path]::GetDirectoryName($full) -ne $Parent -or -not $leaf.StartsWith($Prefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw '备份/恢复目标不在指定 PHP 目录的同级范围内。'
    }
    return $full
}

function Move-LegacyDirectory([string]$Source, [string]$Destination, [string]$GuardRoot) {
    $fullGuard = Get-LegacyFullPath $GuardRoot
    $parent = [IO.Path]::GetDirectoryName($fullGuard)
    $prefix = $parent.TrimEnd('\') + '\'
    $sourceFull = Get-LegacyFullPath $Source
    $destinationFull = Get-LegacyFullPath $Destination
    if (-not $sourceFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase) -or
        -not $destinationFull.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)) { throw '目录移动超出指定 PHP 父目录范围。' }
    Assert-LegacyTree $sourceFull
    if (Test-Path -LiteralPath $destinationFull) { throw '目录移动的目标已存在，拒绝覆盖。' }
    $lastFailure = ''
    for ($attempt = 0; $attempt -lt 12; $attempt++) {
        Assert-LegacyStopped $GuardRoot
        try { [IO.Directory]::Move($sourceFull, $destinationFull); return }
        catch [IO.IOException] { $lastFailure = $_.Exception.Message }
        catch [UnauthorizedAccessException] { $lastFailure = $_.Exception.Message }
        if (Test-Path -LiteralPath $destinationFull) { throw '重试前发现目标目录已存在，停止切换。' }
        if ($attempt -eq 0) { Write-Host '目录暂时被占用，正在等待后重试；不会结束现有 PHP 进程。' -ForegroundColor Yellow }
        Start-Sleep -Milliseconds 250
    }
    throw ('目录切换失败：' + $lastFailure)
}

function Close-LegacyContext($Context) {
    if ($null -eq $Context) { return }
    try {
        if (Test-Path -LiteralPath $Context['Work']) {
            $absolute = Assert-LegacySibling $Context['Work'] $Context['Parent'] '.php734-legacy-work-'
            Assert-LegacyTree $absolute
            Remove-Item -LiteralPath $absolute -Recurse -Force
        }
    } finally {
        $Context['Stream'].Close()
        Remove-Item -LiteralPath $Context['Lock'] -Force
    }
}

function ConvertTo-LegacyArgument([string]$Value) {
    $escaped = [regex]::Replace($Value, '(\\*)"', '$1$1\"')
    $escaped = [regex]::Replace($escaped, '(\\+)$', '$1$1')
    return '"' + $escaped + '"'
}

function Invoke-LegacyPhp([string]$Exe, [string[]]$Arguments, [string]$WorkingDirectory) {
    $quoted = @($Arguments | ForEach-Object { ConvertTo-LegacyArgument $_ }) -join ' '
    $result = [Php734LegacyProcessCapture]::Run($Exe, $quoted, $WorkingDirectory, 30000)
    if ($result.ExitCode -ne 0 -or -not (Test-Blank $result.Error)) {
        $message = $result.Error + $result.Output
        if ($message.Length -gt 1800) { $message = $message.Substring(0, 1800) }
        throw ('PHP 检查失败（退出码 ' + $result.ExitCode + '）：' + $message)
    }
    return $result.Output.Trim()
}

function Initialize-LegacyTools([string]$Directory) {
    $capture = Join-Path $Directory 'Legacy-ProcessCapture.cs'
    $helper = Join-Path $Directory 'legacy-helper.php'
    $hashes = Join-Path $Directory 'legacy-runtime-files.json'
    if ((Get-LegacyHash $capture) -ne '27de400fb64716e0264f2aad5a41507ba9d6afcedbad047572fbfc888c2c65b4' -or
        (Get-LegacyHash $helper) -ne '1ba9f08cc1c7b09a4c25ce3fa800f47845ffa3e2a93199fd19b1f2b8610f1645' -or
        (Get-LegacyHash $hashes) -ne '98b265272e0f48c83e25e3cb64e3973c79888b44d6cd469758f8b8881c2bb49c') { throw '安装助手或运行包清单校验失败，请重新下载完整部署包。' }
    if ($null -eq ('Php734LegacyProcessCapture' -as [type])) { Add-Type -Path $capture }
    return @{ Helper=$helper; Hashes=$hashes }
}

function Decode-LegacyValue([string]$Value) {
    return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($Value))
}

function Test-LegacyPhp([string]$Root, $Tools, [switch]$Configured, [switch]$RequirePort) {
    $exe = Join-Path $Root 'php.exe'
    $version = Invoke-LegacyPhp $exe @('-n', '-v') $Root
    if ($version -notmatch 'PHP 7\.3\.4\s' -or $version -notmatch 'NTS MSVC15.*x64') { throw '仅支持 PHP 7.3.4 / NTS / VC15 / x64，规格不匹配。' }
    $arguments = @('-n', '-f', $Tools['Helper'], '--', 'probe')
    if ($Configured) {
        $arguments = @('-c', (Join-Path $Root 'php.ini'), '-d', 'display_errors=stderr', '-d', 'log_errors=0', '-f', $Tools['Helper'], '--', 'probe')
    }
    $output = Invoke-LegacyPhp $exe $arguments $Root
    if (-not $output.StartsWith('<php734 ') -or $output.Contains('<!')) { throw 'PHP 启动检查出现额外输出，配置没有通过检查。' }
    [xml]$document = $output
    $probe = $document.DocumentElement
    if ($probe.GetAttribute('version') -ne '7.3.4' -or $probe.GetAttribute('bits') -ne '64' -or
        $probe.GetAttribute('zts') -ne '0' -or $probe.GetAttribute('os') -ne 'WINNT' -or $probe.GetAttribute('functional') -ne '1') {
        throw 'PHP 版本、架构或基础执行检查不符。'
    }
    if ($RequirePort -and $probe.GetAttribute('port') -ne '1') { throw '未检测到补丁新增的配置，拒绝替换。' }
    $iniNode = $probe.SelectSingleNode('ini')
    $scannedNode = $probe.SelectSingleNode('scanned')
    $progressNode = $probe.SelectSingleNode('progress')
    $ini = Decode-LegacyValue $iniNode.InnerText
    $scanned = Decode-LegacyValue $scannedNode.InnerText
    if ($Configured) {
        if ((Test-Blank $ini) -or [IO.Path]::GetFullPath($ini) -ne (Join-Path $Root 'php.ini')) { throw '没有加载目标目录中的 php.ini。' }
        if (-not (Test-Blank $scanned)) { throw '检测到外部扫描 INI，请先人工核对配置。' }
    }
    $extensions = @()
    foreach ($node in $probe.SelectNodes('extensions/item')) { $extensions += Decode-LegacyValue $node.InnerText }
    $cgi = Invoke-LegacyPhp (Join-Path $Root 'php-cgi.exe') @('-n', '-v') $Root
    if ($cgi -notmatch '7\.3\.4 \(cgi-fcgi\)') { throw 'PHP CGI 程序检查失败。' }
    return @{ Extensions=$extensions; Progress=(Decode-LegacyValue $progressNode.InnerText) }
}

function Copy-LegacyDirectory([string]$Source, [string]$Destination) {
    [void][IO.Directory]::CreateDirectory($Destination)
    Get-ChildItem -LiteralPath $Source -Force | Copy-Item -Destination $Destination -Recurse -Force
    Set-Acl -LiteralPath $Destination -AclObject (Get-Acl -LiteralPath $Source)
    foreach ($item in Get-ChildItem -LiteralPath $Source -Recurse -Force) {
        $relative = $item.FullName.Substring($Source.Length)
        $relative = $relative.TrimStart('\')
        Set-Acl -LiteralPath (Join-Path $Destination $relative) -AclObject (Get-Acl -LiteralPath $item.FullName)
    }
}

function Save-LegacyReceipt([string]$Path, $Receipt) {
    $temporary = $Path + '.tmp'
    $Receipt | Export-Clixml -Path $temporary -Depth 6
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}
