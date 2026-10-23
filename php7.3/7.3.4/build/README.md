# Build / 构建

## 中文

仓库提供精确的源码补丁和可配置的构建入口，**不捆绑 VC、Windows SDK 或依赖工具链，也不承诺 ZIP 或 EXE 字节级可复现**。现有证据验证的是补丁应用得到与构建输入一致的更改文件；它不等于在第二台机器完整重建二进制。

### 准备

1. 下载并核对干净 PHP 7.3.4 源码，按 [版本 README](../README.md) 应用 `source/apply_source_patch.py` 或统一补丁，两者择一。
2. 准备 VC15 / MSVC 2017 x64、Windows SDK、PHP Windows SDK（含 MSYS2），以及与 PHP 7.3 VC15 x64 对应的依赖。来源与本机构建时的文件哈希在 [`reference/toolchain-downloads-manifest.json`](../reference/toolchain-downloads-manifest.json)；其中 `expected_hash_verified=false` 的依赖仅记录了本地下载哈希，不代表上游签名或独立来源验证。
3. 准备可运行的 PHP 7 CLI 作为旧打包脚本的引导解释器；PHP 8 不兼容部分旧脚本语法。这个路径仅用于构建工具，不会更换服务器的 PHP。

构建时的依赖树形如：

```text
C:\php73-build-tools\
  toolchain\VC\Tools\MSVC\14.16.27023\...
  sdk\bin\...
  sdk\msys2\usr\bin\...
  build\deps\include\...
  build\deps\lib\...
  build\deps\bin\...
```

从本目录打开 CMD，按实际路径设置：

```bat
set "PHP73_SOURCE_DIR=C:\lab\php-7.3.4"
set "PHP73_BUILD_ROOT=C:\php73-build-tools"
set "PHP73_BOOTSTRAP_PHP=C:\php73-bootstrap\php.exe"
rem 按安装情况可覆盖 PHP73_VC_ROOT / PHP73_WINDOWS_SDK / PHP73_WINDOWS_SDK_VERSION / PHP73_DEPS_DIR
Build-Windows.cmd configure
Build-Windows.cmd build
```

如 configure 失败，先解决错误再执行 build。构建脚本使用 `/d2SSAOptimizer- /O2 /Ob2`，默认 SDK 版本 `10.0.26100.0`，参数可以按已安装环境覆盖。更换编译参数或工具链时，从干净源码重新配置构建，或先 `Build-Windows.cmd clean`；不要依赖旧对象文件自动重编译。`dist` 调用 PHP 自带的 `build-dist` 目标，可能还需要引导 PHP 的相应扩展和打包工具。

输出通常位于源码的 `x64\Release`。部署还需收集 DLL 的匹配依赖和同次构建的全部内置扩展。**不能只拷贝 `php.exe` 或 `php7.dll` 就宣称得到本仓库的完整运行包。** 历史参考脚本 `reference/original-build-host.cmd.txt` 保留原参数；其中绝对路径是历史记录，不应直接执行。

本次发布仅对公共构建入口的参数检查做检查，没有为发布 README 再完整运行一次 VC15 编译。完整历史构建记录及优化状态在 `evidence/`。新构建应单独记录编译器、依赖、源码哈希和验证结果。

## English

The repository supplies exact source changes and a configurable build entry point. It does **not** bundle Visual C++, the Windows SDK or the dependency toolchain, and does not promise byte-identical EXE/ZIP reproduction. Recorded source reproduction proves that patch application recreates the changed build-input files, not that an independent machine reproduced every binary.

### Prerequisites

1. Obtain and hash-check pristine PHP 7.3.4; apply either the checked replacement script or the unified patch as described in the [version README](../README.md).
2. Prepare VC15/MSVC 2017 x64, a Windows SDK, the PHP Windows SDK with MSYS2, and PHP 7.3 VC15 x64 dependencies. Sources and recorded hashes are in [`reference/toolchain-downloads-manifest.json`](../reference/toolchain-downloads-manifest.json). Entries marked `expected_hash_verified=false` are download observations, not upstream-signature or independent provenance verification.
3. Supply a working PHP 7 CLI for legacy packaging scripts. PHP 8 removed syntax used by some of these tools. This bootstrap interpreter is for build tools, not your web service.

Use the directory layout and CMD environment example above. Override `PHP73_VC_ROOT`, `PHP73_WINDOWS_SDK`, `PHP73_WINDOWS_SDK_VERSION` or `PHP73_DEPS_DIR` as necessary. Configure successfully before building. The default SDK version is `10.0.26100.0`; optimization is `/d2SSAOptimizer- /O2 /Ob2`.

When flags or toolchains change, use a pristine tree or clean before rebuilding. `dist` invokes upstream `build-dist` and may require additional bootstrap extensions/packaging tools. Build output is normally `x64\Release`; a deployable runtime also needs matched dependencies and all selected extensions from the same build. Copying one core binary alone is insufficient.

`reference/original-build-host.cmd.txt` preserves the original build-host settings as historical evidence, not as a portable executable. The public wrapper's argument handling is checked, but a full compiler rebuild was not repeated for this documentation publication. Record fresh toolchain, input hashes and verification for any new build.
