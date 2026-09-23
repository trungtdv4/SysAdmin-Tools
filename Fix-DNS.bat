@echo off
setlocal
title Fix DNS - OpenDNS

:: Request Administrator privileges when the file is opened by double-click.
fltmc >nul 2>&1
if errorlevel 1 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

echo Setting DNS servers for active physical network adapters...

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
    "$ErrorActionPreference = 'Stop';" ^
    "$adapters = @(Get-NetAdapter -Physical | Where-Object Status -eq 'Up');" ^
    "if ($adapters.Count -eq 0) { throw 'No active physical network adapter was found.' };" ^
    "foreach ($adapter in $adapters) {" ^
    "    Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @('208.67.222.222', '208.67.220.220');" ^
    "    Write-Host ('DNS updated: ' + $adapter.Name);" ^
    "}"

if errorlevel 1 (
    echo.
    echo DNS update failed. Please verify that Windows supports Get-NetAdapter
    echo and that this script was allowed to run with Administrator privileges.
    pause
    exit /b 1
)

ipconfig.exe /flushdns >nul
echo.
echo DNS updated successfully:
echo   Preferred: 208.67.222.222
echo   Alternate: 208.67.220.220
pause
exit /b 0
