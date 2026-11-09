<# :
@cls
@echo off
title System - SMB Share Manager

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
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Ep nap Module SMB trong im lang, tranh crash tren may moi
try {
    Import-Module SmbShare -ErrorAction SilentlyContinue
} catch {}

function Show-ASTSmbHeader {
    Clear-Host
    Write-Host "===================================================================================" -ForegroundColor Cyan
    Write-Host "                             System - SMB Share Manager   " -ForegroundColor Yellow
    Write-Host "   Copyright (c) 2026 Trung Nguyen (trungnm.work@gmail.com). All rights reserved.   " -ForegroundColor Yellow
    Write-Host "             Licensed under the GNU General Public License v3.0 (GPLv3).   " -ForegroundColor Yellow
    Write-Host "===================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Get-ASTSmbStatus {
    Write-Host "[*] Dang kiem tra cau hinh SMB Client hien tai..." -ForegroundColor Cyan
    try {
        $smbConfig = Get-SmbClientConfiguration -ErrorAction Stop
        Write-Host "-------------------------------------------------------------------" -ForegroundColor Gray
        Write-Host "  - RequireSecuritySignature (Bat buoc chu ky so) : " -NoNewline
        if ($smbConfig.RequireSecuritySignature) {
            Write-Host "ENABLED (True)" -ForegroundColor Green
        } else {
            Write-Host "DISABLED (False)" -ForegroundColor Red
        }
        
        Write-Host "  - EnableSecuritySignature  (Cho phep chu ky so)  : " -NoNewline
        if ($smbConfig.EnableSecuritySignature) {
            Write-Host "ENABLED (True)" -ForegroundColor Green
        } else {
            Write-Host "DISABLED (False)" -ForegroundColor Red
        }

        Write-Host "  - EnableInsecureGuestLogons(Cho phep Guest logon) : " -NoNewline
        if ($smbConfig.EnableInsecureGuestLogons) {
            Write-Host "ENABLED (True)" -ForegroundColor Yellow
        } else {
            Write-Host "DISABLED (False)" -ForegroundColor Gray
        }
        Write-Host "-------------------------------------------------------------------" -ForegroundColor Gray
    }
    catch {
        Write-Host "[!] Khong the lay thong tin SMB Client (Dich vu WinRM/CIM chua san sang): $_" -ForegroundColor Red
    }
}

function Set-ASTSmbState {
    param (
        [bool]$Enable
    )
    
    try {
        if ($Enable) {
            Write-Host "[*] Dang thuc hien BAT (Enable) SMB Signing..." -ForegroundColor Yellow
            Set-SmbClientConfiguration -RequireSecuritySignature $True -Force -ErrorAction Stop
            Write-Host "[✓] Da BAT thanh cong SMB Signing (RequireSecuritySignature = True)." -ForegroundColor Green
        } else {
            Write-Host "[*] Dang thuc hien TAT (Disable) SMB Signing..." -ForegroundColor Yellow
            Set-SmbClientConfiguration -RequireSecuritySignature $False -Force -ErrorAction Stop
            Write-Host "[✓] Da TAT thanh cong SMB Signing (RequireSecuritySignature = False)." -ForegroundColor Green
            Write-Host "[i] Khac phuc ma loi 0xc05d0003 khi truy cap NAS / Server cu." -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "[!] Loi khi thay doi thiet lap SMB Signing: $_" -ForegroundColor Red
    }
}

function Start-ASTSmbMenu {
    while ($true) {
        Show-ASTSmbHeader
        Write-Host ">>> MENU CON 1: DISABLE OR ENABLE SMB SIGNING <<<" -ForegroundColor Green
        Write-Host ""
        
        Get-ASTSmbStatus
        Write-Host ""
        
        Write-Host " Vui long chon thao tac:" -ForegroundColor White
        Write-Host "   [1] Enable SMB Signing  (Bat yeu cau xac thuc chu ky so - Bao mat cao)" -ForegroundColor Cyan
        Write-Host "   [2] Disable SMB Signing (Tat yeu cau chu ky so - Fix loi 0xc05d0003)" -ForegroundColor Yellow
        Write-Host "   [0] Quay lai Menu chinh" -ForegroundColor Gray
        Write-Host ""
        
        $choice = Read-Host " Nhap lua chon cua ban [0-2]"
        switch ($choice) {
            "1" {
                Write-Host ""
                Set-ASTSmbState -Enable $true
                Write-Host ""
                Read-Host "Nhan Enter de tiep tuc..."
            }
            "2" {
                Write-Host ""
                Set-ASTSmbState -Enable $false
                Write-Host ""
                Read-Host "Nhan Enter de tiep tuc..."
            }
            "0" {
                Write-Host ""
                Write-Host "[*] Dang dong tac vu SMB..." -ForegroundColor Cyan
                Start-Sleep -Milliseconds 500
                return # Tra luong an toan ve lai cho Master Menu
            }
            default {
                Write-Host "[!] Lua chon khong hop le, vui long chon lai." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Kich hoat Menu
Start-ASTSmbMenu