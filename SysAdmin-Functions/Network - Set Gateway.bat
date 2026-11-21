<# :
@cls
@echo off
title Thay doi Default Gateway and Restart Card Mang

:: 1. Kiem tra va yeu cau quyen Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 2. Khoi tao duong dan file .ps1 tam trong thu muc Temp cua Windows
set "ps1_temp=%temp%\run_ps1_%random%.ps1"

:: 3. Copy toan bo noi dung cua chinh file .bat nay thanh file .ps1
copy /y "%~f0" "%ps1_temp%" >nul

:: 4. Goi PowerShell doc va thuc thi nguyen ban file .ps1 vua tao
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps1_temp%"

:: 5. Xoa file tam sau khi chay xong de don dep he thong
del "%ps1_temp%" >nul 2>&1

:: 6. Dung man hinh va thoat Batch
pause
exit /b
#>

# =========================================================
# LÕI POWERSHELL CỦA BẠN BẮT ĐẦU TỪ ĐÂY
# =========================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------------------
# [FLAG: BANNER_INFO] - Hien thi thong tin ban quyen cong cu
# ------------------------------------------------------------------------------
Write-Host "===================================================================================" -ForegroundColor Cyan
Write-Host "                     THAY DOI DEFAULT GATEWAY & RESTART CARD MANG                  " -ForegroundColor Yellow
Write-Host "   Copyright (c) 2026 Trung Nguyen (trungnm.work@gmail.com). All rights reserved.  " -ForegroundColor Yellow
Write-Host "             Licensed under the GNU General Public License v3.0 (GPLv3).           " -ForegroundColor Yellow
Write-Host "===================================================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------------------
# [FLAG: INPUT_GATEWAY] - Nhan va kiem tra dinh dang IP Default Gateway tu nguoi dung
# ------------------------------------------------------------------------------
$Gateway = ""
while ($true) {
    $inputGw = Read-Host "Nhap dia chi IP Default Gateway moi (VD: 192.168.1.1)"
    $inputGw = $inputGw.Trim()

    $parsedIp = $null
    if ([System.Net.IPAddress]::TryParse($inputGw, [ref]$parsedIp) -and $parsedIp.AddressFamily -eq 'InterNetwork') {
        $Gateway = $parsedIp.ToString()
        break
    } else {
        Write-Host "[!] Dia chi IPv4 khong hop le. Vui long nhap lai!" -ForegroundColor Red
    }
}
Write-Host ""

# ------------------------------------------------------------------------------
# [FLAG: UPDATE_NETWORK_GATEWAY] - Cap nhat Default Gateway va khoi dong lai Card mang
# ------------------------------------------------------------------------------
try {
    # Lay danh sach card mang vat ly dang ket noi (Up)
    $adapters = @(Get-NetAdapter -Physical | Where-Object Status -eq 'Up')

    if ($adapters.Count -eq 0) {
        Write-Host "[!] Khong tim thay Card mang vat ly nao dang hoat dong!" -ForegroundColor Red
    } else {
        foreach ($adapter in $adapters) {
            Write-Host "[*] Dang xu ly Card mang: $($adapter.Name) (Index: $($adapter.ifIndex))..." -ForegroundColor Cyan

            # Xoa cac Default Gateway cu dang ton tai tren Card mang
            Remove-NetRoute -InterfaceIndex $adapter.ifIndex -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue

            # Them Default Gateway moi theo tham so nguoi dung da nhap
            New-NetRoute -InterfaceIndex $adapter.ifIndex -DestinationPrefix "0.0.0.0/0" -NextHop $Gateway | Out-Null
            Write-Host " [+] Da cap nhat Default Gateway moi ($Gateway) cho: $($adapter.Name)" -ForegroundColor Green

            # Restart Card mang de ap dung ngay lap tuc
            Write-Host " [*] Dang khoi dong lai Card mang ($($adapter.Name)) de ap dung cau hinh..." -ForegroundColor Yellow
            Restart-NetAdapter -Name $adapter.Name -Confirm:$false
        }

        # Clear DNS Cache de dong bo mang moi
        Clear-DnsClientCache

        Write-Host ""
        Write-Host "[OK] DA THAY DOI DEFAULT GATEWAY VA LAM MOI CARD MANG THANH CONG!" -ForegroundColor Green
        Write-Host "  - Default Gateway moi: $Gateway" -ForegroundColor Gray
    }
}
catch {
    Write-Host ""
    Write-Host "[ERROR] Da xay ra loi trong qua trinh cau hinh: $_" -ForegroundColor Red
    Write-Host "Luu y: Kiem tra lai dai mang cua IP hien tai xem co cung lop mang voi Gateway moi hay khong." -ForegroundColor Yellow
}