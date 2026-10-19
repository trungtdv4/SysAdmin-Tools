<# :
@cls
@echo off
title Adjust Date and Time Vietnamese

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


# Module: Adjust Date & Time Vietnamese.ps1
# Description: Set SE Asia Standard Time, sync Windows Time Service, and set dd/MM/yyyy date format
# Author     : Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.

Clear-Host
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host "                                 ADJUST DATE & TIME VIETNAMESE (GMT+7)                                  " -ForegroundColor Cyan
Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------------------
# 1. SET TIMEZONE TO VIETNAM (SE ASIA STANDARD TIME - GMT+7)
# ------------------------------------------------------------------------------
Write-Host "[1/3] Setting Time Zone to (UTC+07:00) Bangkok, Hanoi, Jakarta..." -ForegroundColor Yellow

try {
    Set-TimeZone -Id "SE Asia Standard Time" -ErrorAction Stop
    $currentTimeZone = (Get-TimeZone).DisplayName
    Write-Host "  [V] Time Zone successfully set to: $currentTimeZone" -ForegroundColor Green
} catch {
    Write-Host "  [!] Failed to set Time Zone: $_" -ForegroundColor Red
}

Write-Host ""

# ------------------------------------------------------------------------------
# 2. FORCE RESYNC SYSTEM TIME WITH NETWORK TIME PROTOCOL (NTP)
# ------------------------------------------------------------------------------
Write-Host "[2/3] Synchronizing system clock with Time Server..." -ForegroundColor Yellow

try {
    # Ensure Windows Time service (w32time) is running
    $timeService = Get-Service -Name "w32time" -ErrorAction SilentlyContinue
    if ($timeService.Status -ne "Running") {
        Start-Service -Name "w32time" -ErrorAction SilentlyContinue
    }

    # Resync system clock
    $resyncResult = w32tm /resync /force 2>&1
    if ($LASTEXITCODE -eq 0 -or $resyncResult -match "successfully") {
        Write-Host "  [V] System time synchronized successfully!" -ForegroundColor Green
        Write-Host "      Current Local Time: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor White
    } else {
        Write-Host "  [!] Resync notice: $resyncResult" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [!] Error triggering time resync: $_" -ForegroundColor Red
}

Write-Host ""

# ------------------------------------------------------------------------------
# 3. SET DATE FORMAT TO VIETNAMESE STANDARD (dd/MM/yyyy)
# ------------------------------------------------------------------------------
Write-Host "[3/3] Setting Short Date Format to 'dd/MM/yyyy'..." -ForegroundColor Yellow

try {
    # Update Current User Registry Regional Settings
    $regPath = "HKCU:\Control Panel\International"
    Set-ItemProperty -Path $regPath -Name "sShortDate" -Value "dd/MM/yyyy" -ErrorAction Stop
    Set-ItemProperty -Path $regPath -Name "sDate" -Value "/" -ErrorAction Stop

    Write-Host "  [V] Registry updated! Short Date format set to: dd/MM/yyyy" -ForegroundColor Green
    Write-Host "      Note: Some open applications may require a restart to reflect the new date format." -ForegroundColor DarkGray
} catch {
    Write-Host "  [!] Failed to update Regional Date format in Registry: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "[V] Date & Time adjustment process completed!" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
Read-Host | Out-Null