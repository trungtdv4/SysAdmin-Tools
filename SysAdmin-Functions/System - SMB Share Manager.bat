<# :
@cls
@echo off
chcp 65001 >nul
title System - SMB Share Manager

:: 1. Kiem tra quyen Administrator bang fltmc (An toan 100% moi ban Windows)
fltmc >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c \"\"%~f0\"\"' -Verb RunAs"
    exit /b
)

:: 2. Khoi tao duong dan file .ps1 tam trong thu muc Temp
set "ps1_temp=%temp%\run_ps1_%random%.ps1"
copy /y "%~f0" "%ps1_temp%" >nul

:: 3. Goi PowerShell thuc thi
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps1_temp%"
del "%ps1_temp%" >nul 2>&1
exit /b
#>

# =========================================================
# LOI POWERSHELL CUA BAN BAT DAU TU DAY
# =========================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Ep nap Module SMB & Khoi tao CIM Provider de tranh crash tren may moi
try {
    Import-Module SmbShare -ErrorAction SilentlyContinue
} catch {}

function Show-Header {
    Clear-Host
    Write-Host "===================================================================================" -ForegroundColor Cyan
    Write-Host "                              System - SMB Share   " -ForegroundColor Yellow
    Write-Host "   Copyright (c) 2026 Trung Nguyen (trungnm.work@gmail.com). All rights reserved.   " -ForegroundColor Yellow
    Write-Host "             Licensed under the GNU General Public License v3.0 (GPLv3).   " -ForegroundColor Yellow
    Write-Host "===================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ------------------------------------------------------------------------------
# [FLAG: CHECK_SMB_SIGNING] - Kiem tra trang thai SMB Signing hien tai
# ------------------------------------------------------------------------------
function Get-SMBSigningStatus {
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

# ------------------------------------------------------------------------------
# [FLAG: TOGGLE_SMB_SIGNING] - Bat/Tat SMB Signing
# ------------------------------------------------------------------------------
function Set-SMBSigningState {
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
            Write-Host "[i] Khac phuc ma loi 0xc05d0003 khi truy cap thu muc chia se / NAS / Server cu." -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host "[!] Loi khi thay doi thiet lap SMB Signing: $_" -ForegroundColor Red
    }
}

# ------------------------------------------------------------------------------
# [FLAG: SUBMENU_SMB_SIGNING] - Menu con 1: Disable or Enable SMB Signing
# ------------------------------------------------------------------------------
function Menu-SMBSigning {
    while ($true) {
        Show-Header
        Write-Host ">>> MENU CON 1: DISABLE OR ENABLE SMB SIGNING <<<" -ForegroundColor Green
        Write-Host ""
        
        Get-SMBSigningStatus
        Write-Host ""
        
        Write-Host " Vui long chon thao tac:" -ForegroundColor White
        Write-Host "   [1] Enable SMB Signing  (Bat yeu cau xac thuc chu ky so - Bao mat cao)" -ForegroundColor Cyan
        Write-Host "   [2] Disable SMB Signing (Tat yeu cau xac thuc chu ky so - Fix loi 0xc05d0003)" -ForegroundColor Yellow
        Write-Host "   [0] Quay lai Menu chinh" -ForegroundColor Gray
        Write-Host ""
        
        $choice = Read-Host " Nhap lua chon cua ban [0-2]"
        switch ($choice) {
            "1" {
                Write-Host ""
                Set-SMBSigningState -Enable $true
                Write-Host ""
                Read-Host "Nhan Enter de tiep tuc..."
            }
            "2" {
                Write-Host ""
                Set-SMBSigningState -Enable $false
                Write-Host ""
                Read-Host "Nhan Enter de tiep tuc..."
            }
            "0" {
                return
            }
            default {
                Write-Host "[!] Lua chon khong hop le, vui long chon lai." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# ------------------------------------------------------------------------------
# [FLAG: MAIN_MENU] - Giao dien Menu chinh AdminSystem Tools
# ------------------------------------------------------------------------------
function Menu-Main {
    while ($true) {
        Show-Header
        Write-Host "=== QUAN LY CAU HINH SMB SHARE & BAO MAT SYSTEM ===" -ForegroundColor White
        Write-Host ""
        Write-Host "   [1] Disable or Enable SMB Signing" -ForegroundColor Green
        Write-Host "   [0] Quay lai / Thoat" -ForegroundColor Red
        Write-Host ""
        
        $mainChoice = Read-Host " Nhap lua chon cua ban [0-1]"
        switch ($mainChoice) {
            "1" {
                Menu-SMBSigning
            }
            "0" {
                Write-Host ""
                Write-Host "[*] Da thoat Menu SMB Share." -ForegroundColor Cyan
                Start-Sleep -Milliseconds 500
                return # Tra quyen dieu khien ve cho Master Menu, khong dung exit
            }
            default {
                Write-Host "[!] Lua chon khong hop le, vui long chon lai." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# Chay chuong trinh
Menu-Main