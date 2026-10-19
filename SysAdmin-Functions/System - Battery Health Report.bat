<# :
@cls
@echo off
title BATTERY HEALTH REPORT

:: 1. Kiem tra va yeu cau quyen Administrator (Xoa block nay neu tool khong can quyen Admin)
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 2. Khởi tạo đường dẫn file .ps1 tạm trong thư mục Temp của Windows
set "ps1_temp=%temp%\run_ps1_%random%.ps1"

:: 3. Copy toàn bộ nội dung của chính file .bat này thành file .ps1
copy /y "%~f0" "%ps1_temp%" >nul

:: 4. Gọi PowerShell đọc và thực thi nguyên bản file .ps1 vừa tạo
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps1_temp%"

:: 5. Xóa file tạm sau khi chạy xong để dọn dẹp hệ thống
del "%ps1_temp%" >nul 2>&1

:: 6. Dừng màn hình và thoát Batch
pause
exit /b
#>

# =========================================================
# LÕI POWERSHELL CỦA BẠN BẮT ĐẦU TỪ ĐÂY
# =========================================================

# Module File: SysAdmin-Functions/Battery Health Report.ps1
# Description: Generates and opens HTML Battery Health Report via powercfg

Clear-Host
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host "                                       BATTERY HEALTH REPORT                                            " -ForegroundColor Cyan
Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host ""

# Check if physical battery exists
$battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
if (-not $battery) {
    Write-Host "[!] WARNING: No battery detected on this system (Desktop PC / VM)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
    Read-Host | Out-Null
    return
}

$reportPath = Join-Path $env:TEMP "battery-report.html"
Write-Host "[+] Generating battery report using powercfg..." -ForegroundColor Yellow

$process = Start-Process -FilePath "powercfg.exe" -ArgumentList "/batteryreport /output `"$reportPath`"" -Wait -NoNewWindow -PassThru

if ($process.ExitCode -eq 0 -and (Test-Path $reportPath)) {
    Write-Host "[V] Battery report successfully generated!" -ForegroundColor Green
    Write-Host "    Location: $reportPath" -ForegroundColor White
    Write-Host ""
    Write-Host "[+] Opening report in default web browser..." -ForegroundColor Yellow
    
    Start-Process -FilePath $reportPath
} else {
    Write-Host "[!] Error: Failed to generate battery report." -ForegroundColor Red
}

Write-Host ""
Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
Read-Host | Out-Null