@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Rollback-Php7433Port.ps1" %*
set "ROLLBACK_EXIT=%ERRORLEVEL%"
echo.
if "%ROLLBACK_EXIT%"=="0" (echo Completed. See the message above.) else (echo Failed. Keep phpStudy services stopped and read the message above.)
pause
exit /b %ROLLBACK_EXIT%
