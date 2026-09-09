@echo off
title SysAdmin Tools Runner
cd /d "%~dp0"

:: Executing SysAdmin-Tools.ps1 in local environment
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0SysAdmin-Tools.ps1"

pause