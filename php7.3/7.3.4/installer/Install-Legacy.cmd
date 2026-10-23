@echo off
setlocal
set "PHP734_LEGACY_ENTRY=%~dp0Install-Php734Legacy.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $global:LASTEXITCODE=0; try { & $env:PHP734_LEGACY_ENTRY; $ok=$?; if (-not $ok -or $LASTEXITCODE -ne 0) { exit 1 }; exit 0 } catch { Write-Host $_ -ForegroundColor Red; exit 1 }"
set "PHP734_LEGACY_EXIT=%ERRORLEVEL%"
echo.
if "%PHP734_LEGACY_EXIT%"=="0" (echo Verify the explicit success message above before starting services.) else (echo FAILED. Keep services stopped and read the error above.)
pause
exit /b %PHP734_LEGACY_EXIT%
