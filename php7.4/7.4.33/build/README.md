# Build / 构建

## 中文

从[官方 PHP 7.4.33 源码](https://www.php.net/distributions/php-7.4.33.tar.xz)开始，核对 SHA-256 `924846abf93bc613815c55dd3f5809377813ac62a9ec4eb3778675b82a27b927`。解压到独立目录，然后使用 `source/apply_source_patch.py` 或 `patches/` 中逐字节保留的官方补丁，二选一应用。

工具链：VC15 / MSVC 2017 x64、Windows SDK、PHP Windows SDK（MSYS2），以及 PHP 7.4 VC15 x64 依赖系列。下载来源与哈希见 `../reference/downloads-manifest.json`，其未标注独立验证的依赖仅记录本次下载哈希，不等于上游签名认证。Microsoft 工具链不随仓库分发。

在 CMD 设置实际路径并调用构建入口：

```bat
set "PHP74_SOURCE_DIR=C:\lab\php-7.4.33"
set "PHP74_BUILD_ROOT=C:\php74-build-tools"
set "PHP74_BOOTSTRAP_PHP=C:\php74-original\php.exe"
Build-Windows.cmd configure
Build-Windows.cmd build
```

`PHP74_BUILD_ROOT` 下应有 `toolchain\VC\Tools\MSVC\14.16.27023`、`sdk`、`build\deps`。可通过 `PHP74_VC_ROOT`、`PHP74_WINDOWS_SDK`、`PHP74_WINDOWS_SDK_VERSION`、`PHP74_DEPS_DIR` 覆盖实际安装位置。引导解释器使用可工作的 PHP 7，不使用 PHP 8 执行旧打包脚本。

本次 VC15 19.16.27054 在内联优化时发生 C1001，最终全量重建使用 **`/O2 /Ob0 /d2SSAOptimizer-`**。配置后 `configure_compiler_compatibility.py` 只从生成的 Makefile 删除 `/d2FuncCache1`，不改 PHP 源码。`/Ob0` 禁用内联扩展，不是完整关闭 `/O2` 优化；没有做性能对比。不保证更换工具链后需要相同规避方式。

改变参数后应从干净目录或先 `Build-Windows.cmd clean` 重建。输出位于 `x64\Release`，还需要同次构建的全部内置扩展、依赖 DLL 和许可文件。`stage_runtime.py` / `package_runtime.py` 在本机构建工作区运行，其原路径/工具链记录保留在 `reference/`，公共构建入口不宣称自动下载依赖或字节级可复现。构建日志在 `evidence/`。

## English

Start from [official PHP 7.4.33 source](https://www.php.net/distributions/php-7.4.33.tar.xz) with SHA-256 `924846abf93bc613815c55dd3f5809377813ac62a9ec4eb3778675b82a27b927`. Apply either the hash-checked replacement script or the byte-identical upstream patch, once, to a separate pristine tree.

Prepare VC15/MSVC 2017 x64, a Windows SDK, PHP Windows SDK/MSYS2 and the PHP 7.4 VC15 x64 dependency series. Provenance is recorded in `reference/downloads-manifest.json`; observed download hashes do not imply upstream-signature verification. Microsoft tools are not redistributed.

Set the CMD environment above. The build root contains `toolchain\VC\Tools\MSVC\14.16.27023`, `sdk`, and `build\deps`. Override the documented `PHP74_*` toolchain variables as needed. Use a working PHP 7 CLI for legacy packaging tools.

The recorded VC15 19.16.27054 build required **`/O2 /Ob0 /d2SSAOptimizer-`** to avoid internal compiler errors. The compatibility helper removes `/d2FuncCache1` only from the generated Makefile, not PHP source. `/Ob0` disables inline expansion; `/O2` remains enabled. Performance equivalence is not benchmarked, and other toolchains may need different handling.

Clean before rebuilding with changed flags. Output under `x64\Release` must be staged with same-build extensions and matched dependencies/notices. The historical staging/packaging scripts assume the recorded local workspace; the public build entry does not download dependencies or promise byte-identical binaries. See the reference manifests and evidence logs.
