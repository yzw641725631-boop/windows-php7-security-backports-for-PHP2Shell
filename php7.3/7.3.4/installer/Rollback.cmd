@echo off
setlocal
set "PHP734_DISPATCHER=%~dp0Invoke-Php734Installer.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $global:LASTEXITCODE=0; try { & $env:PHP734_DISPATCHER -Operation Rollback; $ok=$?; if (-not $ok -or $LASTEXITCODE -ne 0) { exit 1 }; exit 0 } catch { Write-Host $_ -ForegroundColor Red; exit 1 }"
set "PHP734_ROLLBACK_EXIT=%ERRORLEVEL%"
echo.
if "%PHP734_ROLLBACK_EXIT%"=="0" (echo Verify the explicit success message above before starting services.) else (echo FAILED. Keep services stopped and read the error above.)
pause
exit /b %PHP734_ROLLBACK_EXIT%
