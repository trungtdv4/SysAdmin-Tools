<# :
@echo off
title RustDesk Direct Installer & Configurator
color 0A

:: Kiem tra va tu dong xin quyen Administrator
net session >nul 2>&1 || (
    echo Dang yeu cau quyen Administrator...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Thuc thi chinh file BAT nay duoi dang script PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-Expression ([System.IO.File]::ReadAllText('%~f0'))"
echo.
echo Nhan phim bat ky de thoat...
pause >nul
exit /b
#>


# ==============================================================================
# Script Name: RustDesk (Self-Host Server).ps1
# Author     : Copyright (c) 2026 Trung Nguyen (trungnm.work@gmail.com). All rights reserved.
# ==============================================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "===================================================" -ForegroundColor Cyan
Write-Host "   RUSTDESK AUTOMATED INSTALLER & CONFIGURATION    " -ForegroundColor Cyan
Write-Host "===================================================" -ForegroundColor Cyan

# 1. KHAI BÁO CẤU HÌNH SERVER, KEY VÀ MẬT KHẨU CỐ ĐỊNH
$ServerIP          = "115.73.216.231"
$ServerKey         = "05sFW4xyJ6gDMwQ99HCPHVoj5ALXzWj2p1kUttraEz0="
# $PermanentPassword = "MatKhauCoDinhCuaBan123" # Thay doi mat khau mong muon tại day

# 2. TẢI FILE CÀI ĐẶT TỪ GITHUB RELEASES (BỎ QUA WINGET)
$DownloadUrl   = "https://github.com/rustdesk/rustdesk/releases/download/1.5.1/rustdesk-1.5.1-x86_64.exe"
$InstallerPath = "$env:TEMP\rustdesk-1.5.1-x86_64.exe"

Write-Host "`n[1/5] Dang tai file cai dat RustDesk moi nhat tu GitHub..." -ForegroundColor Yellow
Try {
    Invoke-WebRequest -Uri $DownloadUrl -OutFile $InstallerPath -UseBasicParsing
    Write-Host "   -> Tai file thanh cong!" -ForegroundColor Green
} Catch {
    Write-Host "Loi: Khong the tai file cai dat tu GitHub. Kiem tra lai ket noi Internet!" -ForegroundColor Red
    Exit
}

# 3. CÀI ĐẶT ẨN RUSTDESK (ĐÃ BỎ -WAIT ĐỂ TRÁNH TREO TIẾN TRÌNH)
Write-Host "`n[2/5] Dang thuc hien cai dat ngam (Silent Install)..." -ForegroundColor Yellow
Start-Process -FilePath $InstallerPath -ArgumentList "--silent-install"
# Cho cho den khi rustdesk.exe xuat hien trong Program Files (Toi da 30 giay)
$Timeout = 30
While (!(Test-Path "$env:ProgramFiles\RustDesk\rustdesk.exe") -and ($Timeout -gt 0)) {
    Start-Sleep -Seconds 2
    $Timeout -= 2
}
Start-Sleep -Seconds 3 # Cho Service khoi tao hoa nhap he thong
Write-Host "   -> Cai dat hoan tat!" -ForegroundColor Green

# 4. TẠO THƯ MỤC VÀ NẠP CẤU HÌNH SERVER/KEY (RustDesk2.toml)
Write-Host "`n[3/5] Dang tao file cau hinh Server va Key..." -ForegroundColor Yellow
$ConfigDirUser   = "$env:APPDATA\RustDesk\config"
$ConfigDirSystem = "$env:ProgramData\RustDesk\config"

If (!(Test-Path $ConfigDirUser))   { New-Item -ItemType Directory -Force -Path $ConfigDirUser | Out-Null }
If (!(Test-Path $ConfigDirSystem)) { New-Item -ItemType Directory -Force -Path $ConfigDirSystem | Out-Null }

$ConfigContent = @"
[options]
custom-rendezvous-server = '$ServerIP'
key = '$ServerKey'
api-server = ''
"@

Set-Content -Path "$ConfigDirUser\RustDesk2.toml" -Value $ConfigContent -Encoding UTF8
Set-Content -Path "$ConfigDirSystem\RustDesk2.toml" -Value $ConfigContent -Encoding UTF8

<#
# 5. THIẾT LẬP MẬT KHẨU CỐ ĐỊNH (PERMANENT PASSWORD)
Write-Host "`n[4/5] Dang thiet lap Mat khau co dinh..." -ForegroundColor Yellow
$RustDeskExe = "$env:ProgramFiles\RustDesk\rustdesk.exe"

If (Test-Path $RustDeskExe) {
    Start-Process -FilePath $RustDeskExe -ArgumentList "--password $PermanentPassword" -Wait -WindowStyle Hidden
    Write-Host "   -> Da thiet lap mat khau co dinh!" -ForegroundColor Green
} Else {
    Write-Host "Canh bao: Khong tim thay rustdesk.exe de dat mat khau!" -ForegroundColor Red
}
#>

# 6. DỌN DẸP VÀ KHỞI ĐỘNG LẠI DỊCH VỤ RUSTDESK
Write-Host "`n[5/5] Dang dion dep file temp va restart dich vu RustDesk..." -ForegroundColor Yellow
If (Test-Path $InstallerPath) { Remove-Item $InstallerPath -Force }
Restart-Service -Name "rustdesk" -ErrorAction SilentlyContinue

Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host " HOAN TAT! Da cai dat ngam tu GitHub va nap cau hinh thanh cong." -ForegroundColor Green
Write-Host "======================================================================" -ForegroundColor Green