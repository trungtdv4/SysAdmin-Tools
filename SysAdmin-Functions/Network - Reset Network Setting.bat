<# :
@cls
@echo off
title Network - Reset Network Setting

:: 1. Kiem tra va yeu cau quyen Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 2. Khoi tao duong dan file .ps1 tam trong thu muc Temp
set "ps1_temp=%temp%\run_ps1_%random%.ps1"

:: 3. Copy toan bo noi dung file .bat nay thanh file .ps1
copy /y "%~f0" "%ps1_temp%" >nul

:: 4. Goi PowerShell doc va thuc thi file .ps1
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps1_temp%"

:: 5. Xoa file tam sau khi chay xong
del "%ps1_temp%" >nul 2>&1

:: 6. Dung man hinh va thoat
pause
exit /b
#>

# =========================================================
# MA NGUON POWERSHELL - RESET NETWORK SETTINGS
# =========================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "===================================================================================" -ForegroundColor Cyan
Write-Host "                              RESET NETWORK SETTINGS   " -ForegroundColor Yellow
Write-Host "   Copyright (c) 2026 Trung Nguyen (trungnm.work@gmail.com). All rights reserved.   " -ForegroundColor Yellow
Write-Host "             Licensed under the GNU General Public License v3.0 (GPLv3).   " -ForegroundColor Yellow
Write-Host "===================================================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------------------
# [FLAG: RELEASE_IP] - Giai phong dia chi IP hien tai
# ------------------------------------------------------------------------------
Write-Host "[1/6] Dang giai phong dia chi IP hien tai (ipconfig /release)..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "ipconfig.exe" -ArgumentList "/release" -NoNewWindow -Wait
    Write-Host "[OK] Da giai phong IP thanh cong." -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Loi khi giai phong IP: $_" -ForegroundColor Red
}
Start-Sleep -Seconds 1

# ------------------------------------------------------------------------------
# [FLAG: DELETE_ARP] - Xoa bang cache ARP (IP to MAC mapping)
# ------------------------------------------------------------------------------
Write-Host "[2/6] Dang xoa ARP Cache (netsh interface ip delete arpcache)..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "netsh.exe" -ArgumentList "interface ip delete arpcache" -NoNewWindow -Wait
    Write-Host "[OK] Da xoa ARP cache thanh cong." -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Loi khi xoa ARP cache: $_" -ForegroundColor Red
}
Start-Sleep -Seconds 1

# ------------------------------------------------------------------------------
# [FLAG: FLUSH_DNS] - Xoa cache DNS Resolver
# ------------------------------------------------------------------------------
Write-Host "[3/6] Dang xoa cache DNS (ipconfig /flushdns)..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "ipconfig.exe" -ArgumentList "/flushdns" -NoNewWindow -Wait
    Write-Host "[OK] Da xoa cache DNS thanh cong." -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Loi khi xoa cache DNS: $_" -ForegroundColor Red
}
Start-Sleep -Seconds 1

# ------------------------------------------------------------------------------
# [FLAG: RESET_WINSOCK] - Dat lai Winsock Catalog ve mac dinh
# ------------------------------------------------------------------------------
Write-Host "[4/6] Dang reset Winsock Catalog (netsh winsock reset)..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "netsh.exe" -ArgumentList "winsock reset" -NoNewWindow -Wait
    Write-Host "[OK] Da reset Winsock Catalog thanh cong." -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Loi khi reset Winsock: $_" -ForegroundColor Red
}
Start-Sleep -Seconds 1

# ------------------------------------------------------------------------------
# [FLAG: RESET_TCPIP] - Dat lai giao thuc TCP/IP stack
# ------------------------------------------------------------------------------
Write-Host "[5/6] Dang reset TCP/IP Stack (netsh int ip reset)..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "netsh.exe" -ArgumentList "int ip reset" -NoNewWindow -Wait
    Write-Host "[OK] Da reset TCP/IP stack thanh cong." -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Loi khi reset TCP/IP: $_" -ForegroundColor Red
}
Start-Sleep -Seconds 1

# ------------------------------------------------------------------------------
# [FLAG: RENEW_IP] - Xin cap lai IP moi tu DHCP
# ------------------------------------------------------------------------------
Write-Host "[6/6] Dang xin cap dia chi IP moi (ipconfig /renew)..." -ForegroundColor Cyan
try {
    Start-Process -FilePath "ipconfig.exe" -ArgumentList "/renew" -NoNewWindow -Wait
    Write-Host "[OK] Da xin cap IP moi thanh cong." -ForegroundColor Green
} catch {
    Write-Host "[ERROR] Loi khi xin cap IP: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  HOAN THANH! Ban nen khoi dong lai may tinh de dat hieu qua tot nhat." -ForegroundColor Yellow
Write-Host "======================================================================" -ForegroundColor Cyan