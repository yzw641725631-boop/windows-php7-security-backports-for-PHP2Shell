@echo off
setlocal
if /i "%~1"=="configure" goto check_environment
if /i "%~1"=="build" goto check_environment
if /i "%~1"=="clean" goto check_environment
if /i "%~1"=="dist" goto check_environment
echo Usage: Build-Windows.cmd configure ^| build ^| clean ^| dist
echo Set PHP73_SOURCE_DIR, PHP73_BUILD_ROOT and PHP73_BOOTSTRAP_PHP first.
exit /b 2

:check_environment
if not defined PHP73_SOURCE_DIR (
    echo Missing PHP73_SOURCE_DIR. See build\README.md.
    exit /b 2
)
if not defined PHP73_BUILD_ROOT (
    echo Missing PHP73_BUILD_ROOT. See build\README.md.
    exit /b 2
)
if not defined PHP73_BOOTSTRAP_PHP (
    echo Missing PHP73_BOOTSTRAP_PHP. Use a working PHP 7 CLI for legacy packaging tools.
    exit /b 2
)
if not defined PHP73_VC_ROOT set "PHP73_VC_ROOT=%PHP73_BUILD_ROOT%\toolchain\VC\Tools\MSVC\14.16.27023"
if not defined PHP73_WINDOWS_SDK set "PHP73_WINDOWS_SDK=C:\Program Files (x86)\Windows Kits\10"
if not defined PHP73_WINDOWS_SDK_VERSION set "PHP73_WINDOWS_SDK_VERSION=10.0.26100.0"
if not defined PHP73_DEPS_DIR set "PHP73_DEPS_DIR=%PHP73_BUILD_ROOT%\build\deps"
if not exist "%PHP73_SOURCE_DIR%\buildconf.bat" (
    echo Source directory must contain the patched PHP 7.3.4 Windows source tree.
    exit /b 2
)
if not exist "%PHP73_BOOTSTRAP_PHP%" (
    echo Bootstrap PHP executable does not exist.
    exit /b 2
)
if not exist "%PHP73_VC_ROOT%\bin\Hostx64\x64\cl.exe" (
    echo VC15 x64 compiler not found. Set PHP73_VC_ROOT to your installed toolset.
    exit /b 2
)
if not exist "%PHP73_DEPS_DIR%\include" (
    echo Legacy VC15 x64 dependency include directory not found.
    exit /b 2
)
if not exist "%PHP73_WINDOWS_SDK%\Include\%PHP73_WINDOWS_SDK_VERSION%\ucrt" (
    echo Windows SDK not found. Set PHP73_WINDOWS_SDK and PHP73_WINDOWS_SDK_VERSION.
    exit /b 2
)
set "PATH=%PHP73_VC_ROOT%\bin\Hostx64\x64;%PHP73_WINDOWS_SDK%\bin\%PHP73_WINDOWS_SDK_VERSION%\x64;%PHP73_BUILD_ROOT%\sdk\bin;%PHP73_BUILD_ROOT%\sdk\msys2\usr\bin;%PATH%"
set "INCLUDE=%PHP73_VC_ROOT%\include;%PHP73_VC_ROOT%\atlmfc\include;%PHP73_WINDOWS_SDK%\Include\%PHP73_WINDOWS_SDK_VERSION%\ucrt;%PHP73_WINDOWS_SDK%\Include\%PHP73_WINDOWS_SDK_VERSION%\shared;%PHP73_WINDOWS_SDK%\Include\%PHP73_WINDOWS_SDK_VERSION%\um;%PHP73_WINDOWS_SDK%\Include\%PHP73_WINDOWS_SDK_VERSION%\winrt"
set "LIB=%PHP73_VC_ROOT%\lib\x64;%PHP73_VC_ROOT%\atlmfc\lib\x64;%PHP73_WINDOWS_SDK%\Lib\%PHP73_WINDOWS_SDK_VERSION%\ucrt\x64;%PHP73_WINDOWS_SDK%\Lib\%PHP73_WINDOWS_SDK_VERSION%\um\x64"
set "PHP_SDK_VS=vc15"
set "PHP_SDK_ARCH=x64"
set "PHP_SDK_OS_ARCH=x64"
set "PHP_SDK_ROOT_PATH=%PHP73_BUILD_ROOT%\sdk"
set "PHP_SDK_BIN_PATH=%PHP73_BUILD_ROOT%\sdk\bin"
set "PHP_SDK_MSYS2_PATH=%PHP73_BUILD_ROOT%\sdk\msys2\usr\bin"
set "PHP_SDK_PHP_CMD=%PHP73_BOOTSTRAP_PHP%"
if not defined PHP_SDK_VC_TOOLSET_VER set "PHP_SDK_VC_TOOLSET_VER=14.16.27054"
set "VCToolsInstallDir=%PHP73_VC_ROOT%\"
set "WindowsSdkDir=%PHP73_WINDOWS_SDK%\"
set "WindowsSDKVersion=%PHP73_WINDOWS_SDK_VERSION%\"
rem Same optimization/compiler workaround as the published candidate.
set "_CL_=/d2SSAOptimizer- /O2 /Ob2"
pushd "%PHP73_SOURCE_DIR%"
if errorlevel 1 exit /b 2
if /i "%~1"=="configure" goto configure
if /i "%~1"=="clean" goto clean
if /i "%~1"=="dist" goto dist
nmake /nologo
goto finish

:configure
call buildconf.bat
if errorlevel 1 goto finish
call configure.bat --enable-snapshot-build --enable-debug-pack --disable-zts --enable-com-dotnet=shared --without-analyzer --without-oci8-12c --without-pdo-oci --with-mp=4 --with-php-build="%PHP73_DEPS_DIR%"
goto finish

:clean
nmake /nologo clean
goto finish

:dist
nmake /nologo build-dist

:finish
set "PHP73_BUILD_EXIT=%ERRORLEVEL%"
popd
exit /b %PHP73_BUILD_EXIT%
