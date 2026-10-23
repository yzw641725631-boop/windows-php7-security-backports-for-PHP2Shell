@echo off
setlocal
cd /d "%~dp0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-Php7433Port.ps1" %*
set "INSTALL_EXIT=%ERRORLEVEL%"
echo.
if "%INSTALL_EXIT%"=="0" (echo Completed. See the message above.) else (echo Failed. Keep phpStudy services stopped and read the message above.)
pause
exit /b %INSTALL_EXIT%
