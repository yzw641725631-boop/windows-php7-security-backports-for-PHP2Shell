<?php
/* Installer helper for trusted local PHP 7.3.4 only. No networking or shell use. */
function fail_install($message) {
    fwrite(STDERR, $message . "\n");
    exit(1);
}
function normalized_file($root, $relative) {
    $relative = str_replace('\\', '/', $relative);
    if ($relative === '' || $relative[0] === '/' || strpos($relative, ':') !== false ||
        preg_match('~(^|/)\.{1,2}(/|$)~', $relative) || strpos($relative, "\0") !== false) {
        fail_install('Unsafe archive or manifest path');
    }
    return $root . DIRECTORY_SEPARATOR . str_replace('/', DIRECTORY_SEPARATOR, $relative);
}
function verify_files($root, $manifest, $allowExtra = false) {
    $map = json_decode(file_get_contents($manifest), true);
    if (!is_array($map) || count($map) < 3) {
        fail_install('Invalid trusted runtime manifest');
    }
    foreach ($map as $relative => $expected) {
        $file = normalized_file($root, $relative);
        if (!is_file($file) || !is_string($expected) || !preg_match('/^[a-f0-9]{64}$/D', $expected) ||
            hash_file('sha256', $file) !== $expected) {
            fail_install('Runtime file verification failed: ' . $relative);
        }
    }
    if (!$allowExtra) {
        $prefix = rtrim($root, '/\\') . DIRECTORY_SEPARATOR;
        $files = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($root, FilesystemIterator::SKIP_DOTS));
        foreach ($files as $file) {
            if (!$file->isFile()) {
                continue;
            }
            $relative = str_replace('\\', '/', substr($file->getPathname(), strlen($prefix)));
            if (!array_key_exists($relative, $map)) {
                fail_install('Unlisted file in runtime directory: ' . $relative);
            }
        }
    }
    return count($map);
}
$mode = isset($argv[1]) ? $argv[1] : '';
if ($mode === 'extract') {
    if (count($argv) !== 5 || !class_exists('ZipArchive')) {
        fail_install('The existing PHP needs ZipArchive for automatic extraction; use -RuntimeDir for a verified extracted runtime instead');
    }
    $zip = new ZipArchive();
    if ($zip->open($argv[2]) !== true) {
        fail_install('Unable to open runtime ZIP');
    }
    for ($i = 0; $i < $zip->numFiles; $i++) {
        normalized_file($argv[3], $zip->getNameIndex($i));
    }
    if (!is_dir($argv[3]) && !mkdir($argv[3], 0777, true)) {
        fail_install('Unable to create extraction directory');
    }
    if (!$zip->extractTo($argv[3])) {
        fail_install('Unable to extract runtime ZIP');
    }
    $zip->close();
    $count = verify_files($argv[3], $argv[4]);
    echo 'PHP734VERIFY:', $count;
    exit(0);
}
if ($mode === 'overlay') {
    if (count($argv) !== 5) {
        fail_install('Invalid overlay arguments');
    }
    $count = verify_files($argv[2], $argv[4]);
    $map = json_decode(file_get_contents($argv[4]), true);
    foreach ($map as $relative => $expected) {
        $source = normalized_file($argv[2], $relative);
        $destination = normalized_file($argv[3], $relative);
        if (!is_dir(dirname($destination)) && !mkdir(dirname($destination), 0777, true)) {
            fail_install('Unable to create candidate subdirectory');
        }
        if (!copy($source, $destination)) {
            fail_install('Unable to copy candidate runtime file: ' . $relative);
        }
    }
    verify_files($argv[3], $argv[4], true);
    echo 'PHP734VERIFY:', $count;
    exit(0);
}
if ($mode === 'verify' || $mode === 'verify-merged') {
    if (count($argv) !== 4) {
        fail_install('Invalid verifier arguments');
    }
    echo 'PHP734VERIFY:', verify_files($argv[2], $argv[3], $mode === 'verify-merged');
    exit(0);
}
if ($mode === 'probe') {
    $directives = ini_get_all(null, false);
    $extensions = array_unique(array_merge(get_loaded_extensions(), get_loaded_extensions(true)));
    sort($extensions, SORT_STRING);
    $ok = json_decode(json_encode(array('a' => 42)), true);
    echo '<php734 version="', PHP_VERSION, '" bits="', PHP_INT_SIZE * 8,
         '" zts="', PHP_ZTS, '" os="', PHP_OS, '" functional="', $ok['a'] === 42 ? '1' : '0',
         '" port="', array_key_exists('memory_hard_limit_percent', $directives) ? '1' : '0', '">';
    /* Base64 keeps stdout ASCII even on old consoles with a different code page. */
    echo '<ini>', base64_encode((string) php_ini_loaded_file()), '</ini>',
         '<scanned>', base64_encode((string) php_ini_scanned_files()), '</scanned>',
         '<progress>', base64_encode((string) ini_get('session.upload_progress.enabled')), '</progress>',
         '<extensions>';
    foreach ($extensions as $extension) {
        echo '<item>', base64_encode($extension), '</item>';
    }
    echo '</extensions></php734>';
    exit(0);
}
fail_install('Unknown installer helper mode');
