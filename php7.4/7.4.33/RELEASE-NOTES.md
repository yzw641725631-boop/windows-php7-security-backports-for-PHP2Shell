# PHP 7.4.33 Windows x64 NTS VC15 — Unofficial upstream-backport build

## 中文

**PHP 7.4.33 / Windows x64 / NTS / VC15**，从干净官方源码完整应用 PHP 团队 7.4 专用提交 `712e60f9edfd03f0960fc4fc3c2c375f42b90aa2` 后重新编译。

源码补丁来自 PHP 官方；这些 Windows 二进制是本项目的非官方构建，不是 PHP 官方 Windows 安全发行版。

在 **Assets** 中下载：

- `php-7.4.33-nts-Win32-VC15-x64-unofficial-upstream-backport-20261023.zip`：完整编译运行包，无用户 `php.ini`。
- `phpStudy-PHP-7.4.33-nts-VC15-x64-unofficial-backport-install-kit-20261023.zip`：同一个运行包加安装、备份、回滚脚本和中英说明。
- `SHA256SUMS.txt`：文件 SHA-256 校验清单。

自动安装仅接受现有 **7.4.33 NTS VC15 x64**，先停 phpStudy 服务，再以管理员身份运行 `Install.cmd`。脚本保留配置、扩展及旧目录备份。其他 7.4.x 的升级需单独迁移验证。GitHub 自动生成的 Source code 不是独立的编译运行包。

**与 7.3.4 包的区别：OOM 会退出当前工作进程；Session 上传进度回调停用，普通上传保留；没有 `memory_hard_limit_percent`。** 进程补充依赖 phpStudy / FastCGI 管理器。

17 个源码文件与官方补丁一致；本机核心/扩展、普通上传、原生 FastCGI、22 个 OOM 退出场景、260 MiB 流式上传和 12 项隔离安装检查通过。构建使用 `/O2 /Ob0 /d2SSAOptimizer-` 并移除生成 Makefile 中的 `/d2FuncCache1`，没有改写 PHP 源码绕过编译。内联被禁用，性能尚未对比。

仍为预发布候选构建：没有独立安全审计、完整利用回归或 Windows Server 2019 / 实际 ThinkPHP 项目验证；大文件本机检查未经过 Nginx/业务端点，不代表原应用的 500 已解决。历史依赖与第三方扩展不获全面兼容或安全保证。更多细节见 `php7.4/7.4.33/README.md`。

## English

**PHP 7.4.33 / Windows x64 / NTS / VC15**, rebuilt from pristine source with the exact upstream 7.4 commit `712e60f9edfd03f0960fc4fc3c2c375f42b90aa2`.

The source fix is from PHP upstream; these Windows binaries are unofficial project builds, not official PHP Windows security releases.

Download the compiled runtime ZIP, phpStudy installer kit or `SHA256SUMS.txt` under **Assets**. The installer includes the same runtime plus backup/rollback scripts and bilingual documentation. GitHub's automatic Source code archives are repository snapshots.

Automatic installation targets **existing 7.4.33 NTS VC15 x64 only**. Stop services first and run `Install.cmd` as Administrator. Configuration/add-ons and a full original backup are retained. Other 7.4.x upgrades need separate migration validation.

**Unlike the 7.3.4 port, this exact upstream 7.4 mitigation exits the current worker on OOM and disables Session upload progress while retaining ordinary uploads. `memory_hard_limit_percent` is absent.** Worker replacement depends on the process manager.

The 17 changed source files match upstream. Local core/extension, ordinary HTTP/native FastCGI uploads, 22 OOM exits, a 260 MiB streamed upload and 12 isolated installer checks passed. Compiler compatibility required `/O2 /Ob0 /d2SSAOptimizer-` and removal of `/d2FuncCache1` from the generated Makefile; PHP implementation source is unchanged. Inline expansion is disabled and performance equivalence is not benchmarked.

This prerelease has no independent security audit, complete exploit-regression certification or complete Windows Server 2019/ThinkPHP application validation. The large-upload test bypasses Nginx/business endpoints and does not resolve reported application HTTP 500 errors. Historical dependencies and third-party extensions are not comprehensively certified. See the version README and evidence.
