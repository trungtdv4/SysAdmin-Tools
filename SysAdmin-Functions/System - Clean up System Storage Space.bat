<# :
@cls
@echo off
chcp 65001 >nul
title Don Dep He Thong, Temp User - SysAdmin Tools

:: 1. Kiem tra va yeu cau quyen Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: 2. Khoi tao duong dan file .ps1 tam trong thu muc Temp
set "ps1_temp=%temp%\run_ps1_%random%.ps1"

:: 3. Copy toan bo noi dung cua chinh file .bat nay thanh file .ps1
copy /y "%~f0" "%ps1_temp%" >nul

:: 4. Goi PowerShell doc va thuc thi nguyen ban file .ps1 vua tao
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps1_temp%"

:: 5. Xoa file tam sau khi chay xong
del "%ps1_temp%" >nul 2>&1

:: 6. Dung man hinh va thoat Batch
pause
exit /b
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ------------------------------------------------------------------------------
# [FLAG: INIT_ENV] - Khoi tao moi truong va danh sach thu muc don dep
# ------------------------------------------------------------------------------
Write-Host "===================================================================================" -ForegroundColor Cyan
Write-Host "                           CLEAR UP SYSTEM STORAGE SPACE                           " -ForegroundColor Yellow
Write-Host "   Copyright (c) 2026 Trung Nguyen (trungnm.work@gmail.com). All rights reserved.  " -ForegroundColor Yellow
Write-Host "             Licensed under the GNU General Public License v3.0 (GPLv3).           " -ForegroundColor Yellow
Write-Host "===================================================================================" -ForegroundColor Cyan
Write-Host ""

$TargetFolders = @(
    "C:\Windows\Prefetch",
    "C:\Windows\LogFiles",
    "C:\Windows\SoftwareDistribution\Download",
    "C:\Windows\Temp",
    $env:TEMP
)

# ------------------------------------------------------------------------------
# [FLAG: STOP_SERVICES] - Tam dung Windows Update Service
# ------------------------------------------------------------------------------
Write-Host "[+] Dang tam dung dich vu Windows Update (wuauserv)..." -ForegroundColor DarkYellow
try {
    Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
    Write-Host "    -> Da dung dich vu wuauserv thanh cong." -ForegroundColor Green
} catch {
    Write-Host "    -> Khong the dung wuauserv hoac dich vu chua chay." -ForegroundColor Gray
}

Write-Host ""

# ------------------------------------------------------------------------------
# [FLAG: CLEAN_FOLDERS] - Thuc hien don dep du lieu trong cac thu muc Temp
# ------------------------------------------------------------------------------
$TotalDeletedFiles = 0
$TotalDeletedFolders = 0

foreach ($folder in $TargetFolders) {
    Write-Host "[*] Dang xu ly thu muc: $folder" -ForegroundColor Yellow
    if (Test-Path -Path $folder) {
        $items = Get-ChildItem -Path $folder -Recurse -ErrorAction SilentlyContinue

        foreach ($item in $items) {
            try {
                Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
                if ($item.PSIsContainer) {
                    $TotalDeletedFolders++
                } else {
                    $TotalDeletedFiles++
                }
            } catch {
                # Tien trinh dang su dung (File in use) -> Bo qua an toan
            }
        }
        Write-Host "    -> Hoan tat don dep $folder" -ForegroundColor Green
    } else {
        Write-Host "    -> Thu muc khong ton tai, bo qua." -ForegroundColor Gray
    }
}

Write-Host ""

<# Tam khoa lai vi khong phai ai cung muon xoa thung rac
# ------------------------------------------------------------------------------
# [FLAG: CLEAN_RECYCLE_BIN] - Lam sach Thung rac (Recycle Bin)
# ------------------------------------------------------------------------------
Write-Host "[+] Dang tien hanh lam sach Thung rac (Recycle Bin)..." -ForegroundColor Yellow
try {
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Host "    -> Da xoa sach Recycle Bin thanh cong." -ForegroundColor Green
} catch {
    Write-Host "    -> Thung rac rong hoac khong co quyen truy cap." -ForegroundColor Gray
}

Write-Host ""
#>

# ------------------------------------------------------------------------------
# [FLAG: RESTART_SERVICES] - Khoi chay lai Windows Update Service
# ------------------------------------------------------------------------------
Write-Host "[+] Dang khoi chay lai dich vu Windows Update (wuauserv)..." -ForegroundColor DarkYellow
try {
    Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
    Write-Host "    -> Da bat lai dich vu wuauserv thanh cong." -ForegroundColor Green
} catch {
    Write-Host "    -> Khong the khoi chay lai wuauserv." -ForegroundColor Red
}

Write-Host ""

# ------------------------------------------------------------------------------
# [FLAG: SUMMARY_REPORT] - Hien thi bao cao ket qua don dep
# ------------------------------------------------------------------------------
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "                   HOAN TAT DON DEP                     " -ForegroundColor Green
Write-Host "  - Da don dep 5 thu muc he thong                       " -ForegroundColor White
# Write-Host "  - Da xa sach du lieu trong Thung rac (Recycle Bin)" -ForegroundColor White
Write-Host "  - So tep tin da xoa: $TotalDeletedFiles" -ForegroundColor White
Write-Host "  - So thu muc da xoa: $TotalDeletedFolders" -ForegroundColor White
Write-Host "  - Cac tep dang duoc cac ung dung mo da duoc bo qua an toan." -ForegroundColor Gray
Write-Host "========================================================" -ForegroundColor Cyan