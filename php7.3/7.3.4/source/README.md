# Exact source replacements / 精确源码替换

## 中文

`source-changes.json` 记录干净 PHP 7.3.4 源码压缩包哈希、统一补丁哈希和 114 个更改文件的前后 SHA-256；`patched-source/` 是本次构建采用的更改文件，不是完整 PHP 源码发行包。

```powershell
python .\apply_source_patch.py --source C:\lab\php-7.3.4
```

只对独立的、精确版本的干净源码目录使用。脚本先检查所有原文件和替换文件，再写入；已打补丁或不同版本的源码会被拒绝。统一 diff 在 `../patches/`，两种应用方式择一。

## English

`source-changes.json` records the pristine source archive hash, unified-patch hash and before/after SHA-256 values for 114 changed files. `patched-source/` contains the changed build-input files, not a complete PHP source distribution.

Run the command above on a separate pristine PHP 7.3.4 source tree. All original and replacement hashes are checked before writing. Already-patched or different-version source is rejected. The alternative unified patch is in `../patches/`; use one application method only.
