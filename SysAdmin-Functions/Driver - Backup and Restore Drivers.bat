<# :
@cls
@echo off
chcp 65001 >nul
title Driver - Backup and Restore Drivers

:: 1. Kiem tra va yeu cau quyen Administrator
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
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# ------------------------------------------------------------------------------
# [FLAG: BANNER] - Hien thi thong tin cong cu
# ------------------------------------------------------------------------------
function Show-Banner {
    Clear-Host
    Write-Host "=======================================================================================" -ForegroundColor Cyan
    Write-Host "                       DRIVER - BACKUP & RESTORE DRIVERS                               " -ForegroundColor Yellow
    Write-Host "   Copyright (c) 2026 Trung Nguyen (trungnm.work@gmail.com). All rights reserved.       " -ForegroundColor Yellow
    Write-Host "             Licensed under the GNU General Public License v3.0 (GPLv3).               " -ForegroundColor Yellow
    Write-Host "=======================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ------------------------------------------------------------------------------
# [FLAG: BACKUP_DRIVER] - Sao luu Driver bang DISM
# ------------------------------------------------------------------------------
function Invoke-DriverBackup {
    Show-Banner
    $backupPath = "D:\DriverBackup"

    Write-Host "[+] Bat dau quy trinh sao luu Driver..." -ForegroundColor Cyan
    
    # Kiem tra va tao thu muc neu chua ton tai
    if (-not (Test-Path -Path $backupPath)) {
        Try {
            New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
            Write-Host "[i] Da tao thanh cong thu muc: $backupPath" -ForegroundColor Green
        } Catch {
            Write-Host "[!] Loi: Khong the tao thu muc $backupPath. Chi tiet: $_" -ForegroundColor Red
            return
        }
    } else {
        Write-Host "[i] Thu muc luu tru da san sang: $backupPath" -ForegroundColor Gray
    }

    Write-Host "[*] Dang thuc hien xuat Driver OEM bang DISM. Vui long cho..." -ForegroundColor Yellow
    Write-Host ""

    Try {
        $dismArgs = "/online /export-driver /destination:`"$backupPath`""
        $process = Start-Process -FilePath "dism.exe" -ArgumentList $dismArgs -Wait -NoNewWindow -PassThru

        if ($process.ExitCode -eq 0) {
            Write-Host ""
            Write-Host "[OK] Sao luu Driver thanh cong! Toan bo file .inf da luu tai: $backupPath" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "[!] DISM ket thuc voi ma loi: $($process.ExitCode)" -ForegroundColor Red
        }
    } Catch {
        Write-Host "[!] Loi trong qua trinh thuc thi DISM: $_" -ForegroundColor Red
    }
}

# ------------------------------------------------------------------------------
# [FLAG: RESTORE_DRIVER] - Khoi phuc Driver bang PnPUtil
# ------------------------------------------------------------------------------
function Invoke-DriverRestore {
    Show-Banner
    Write-Host "[+] Bat dau quy trinh khoi phuc Driver..." -ForegroundColor Cyan

    $defaultPath = "D:\DriverBackup"
    $inputPath = Read-Host "Nhap duong dan thu muc chua Driver backup [Nhan Enter de dung mac dinh: $defaultPath]"

    if ([string]::IsNullOrWhiteSpace($inputPath)) {
        $restorePath = $defaultPath
    } else {
        $restorePath = $inputPath.Trim('"')
    }

    if (-not (Test-Path -Path $restorePath)) {
        Write-Host "[!] Loi: Thu muc '$restorePath' khong ton tai tren he thong!" -ForegroundColor Red
        return
    }

    Write-Host "[i] Thu muc nguon: $restorePath" -ForegroundColor Green
    Write-Host "[*] Dang quet va nap cai dat Driver bang PnPUtil..." -ForegroundColor Yellow
    Write-Host ""

    Try {
        $pnputilArgs = "/add-driver `"$restorePath\*.inf`" /subdirs /install"
        $process = Start-Process -FilePath "pnputil.exe" -ArgumentList $pnputilArgs -Wait -NoNewWindow -PassThru

        if ($process.ExitCode -eq 0 -or $process.ExitCode -eq 3010) {
            Write-Host ""
            Write-Host "[OK] Khoi phuc va kich hoat Driver thanh cong!" -ForegroundColor Green
            if ($process.ExitCode -eq 3010) {
                Write-Host "[i] Luu y: Mot so thiet bi yeu cau khoi dong lai Windows de hoan tat." -ForegroundColor Yellow
            }
        } else {
            Write-Host ""
            Write-Host "[!] PnPUtil ket thuc voi ma loi: $($process.ExitCode)" -ForegroundColor Red
        }
    } Catch {
        Write-Host "[!] Loi trong qua trinh thuc thi PnPUtil: $_" -ForegroundColor Red
    }
}

# ------------------------------------------------------------------------------
# [FLAG: MENU_SYSTEM] - Menu dieu huong va tuong tac
# ------------------------------------------------------------------------------
function Main-Menu {
    do {
        Show-Banner
        Write-Host "   === CHON CHUC NANG ===" -ForegroundColor White
        Write-Host "   1. Backup Drivers  (Cong cu: DISM)" -ForegroundColor Green
        Write-Host "   2. Restore Drivers (Cong cu: PnPUtil)" -ForegroundColor Green
        Write-Host "   0. Thoat" -ForegroundColor Red
        Write-Host ""
        
        $choice = Read-Host "Nhap lua chon cua ban [0-2]"

        switch ($choice) {
            '1' {
                Invoke-DriverBackup
                Write-Host ""
                Read-Host "Nhan Enter de tro ve Menu..."
            }
            '2' {
                Invoke-DriverRestore
                Write-Host ""
                Read-Host "Nhan Enter de tro ve Menu..."
            }
            '0' {
                Write-Host "[i] Dang thoat chuong trinh..." -ForegroundColor Cyan
                return
            }
            default {
                Write-Host "[!] Lua chon khong hop le. Vui long chon tu 0 den 2." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

# Kich hoat Menu chinh
Main-Menu