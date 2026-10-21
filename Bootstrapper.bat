@echo off
title SysAdmin Tools Runner
cd /d "%~dp0"

:: Kiem tra va yeu cau quyen Administrator neu chua co
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo [!] Notice: Administrator privileges required. Requesting elevation...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -WorkingDirectory '%~dp0' -Verb RunAs"
    exit /b
)

:: Executing SysAdmin-Tools.ps1 in local environment
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SysAdmin-Tools.ps1"

pause