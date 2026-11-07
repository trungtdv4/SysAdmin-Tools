# ==============================================================================
# Script Name: RustDesk (Self-Host Server)
# ==============================================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host "==================================================================================" -ForegroundColor Cyan
Write-Host "                    RUSTDESK AUTOMATED INSTALLER & CONFIGURATION                  " -ForegroundColor Cyan
Write-Host "  Copyright (c) 2026 Trung Nguyen (trungnm.work@gmail.com). All rights reserved.  " -ForegroundColor Cyan
Write-Host "==================================================================================" -ForegroundColor Cyan

# 1. KHAI BÁO CẤU HÌNH SERVER, KEY VÀ MẬT KHẨU CỐ ĐỊNH
$ServerIP          = "115.73.216.231"
$ServerKey         = "05sFW4xyJ6gDMwQ99HCPHVoj5ALXzWj2p1kUttraEz0="
# $PermanentPassword = "YourPasswordHere" # Thay doi mat khau mong muon tại day

<#
#-------------------------------------------------------------------------------------------------------
# Nếu dùng cách cài bằng WinGet thì bỏ BƯỚC 2 và 3 ở dưới
# Hiện tại không thể cài bằng WinGet được vì RustDesk đã bị tháo khỏi WinGet do có vấn đề về bảo mật.
#-------------------------------------------------------------------------------------------------------
# 2. CÀI ĐẶT RUSTDESK BẰNG WINGET (SILENT INSTALL)
Write-Host "`nDang tai va cai dat RustDesk qua WinGet (Silent)..." -ForegroundColor Yellow
winget install --id RustDesk.RustDesk -e --silent --accept-package-agreements --accept-source-agreements
#>

# 2. TẢI FILE CÀI ĐẶT TỪ GITHUB RELEASES (BỎ QUA WINGET)
$DownloadUrl   = "https://github.com/rustdesk/rustdesk/releases/download/1.5.1/rustdesk-1.5.1-x86_64.exe" #Doi ten file va duong dan khi co version moi.
$InstallerPath = "$env:TEMP\rustdesk-1.5.1-x86_64.exe" #Doi ten file giong hang tren.

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

# 4. NẠP IP SERVER VÀ KEY BẰNG CÚ PHÁP CLI NATIVE CỦA RUSTDESK 1.5.1 TRỞ LÊN.
Write-Host "`n[3/5] Dang nap IP Server va Key qua lenh CLI --config..." -ForegroundColor Yellow
$RustDeskExe = "$env:ProgramFiles\RustDesk\rustdesk.exe"

If (Test-Path $RustDeskExe) {
    # Cú pháp CLI chuẩn chính thức của RustDesk 1.5.1
    $ConfigArg = "--config host=$ServerIP,key=$ServerKey"
    Start-Process -FilePath $RustDeskExe -ArgumentList $ConfigArg -Wait -WindowStyle Hidden
    Write-Host "   -> Da nap Server va Key qua CLI thanh cong!" -ForegroundColor Green
} Else {
    Write-Host "Loi: Khong tim thấy rustdesk.exe de nap config!" -ForegroundColor Red
}

<#
# 5. THIẾT LẬP MẬT KHẨU CỐ ĐỊNH (PERMANENT PASSWORD)
Write-Host "`n[4/5] Dang thiet lap Mat khau co dinh..." -ForegroundColor Yellow
If (Test-Path $RustDeskExe) {
    Start-Process -FilePath $RustDeskExe -ArgumentList "--password $PermanentPassword" -Wait -WindowStyle Hidden
    Write-Host "   -> Da thiet lap mat khau co dinh!" -ForegroundColor Green
}
#>

# 6. DỌN DẸP, RESTART SERVICE VÀ LẤY RUSTDESK ID
Write-Host "`n[5/5] Dang don dep file temp va khoi chay lai Service RustDesk..." -ForegroundColor Yellow
If (Test-Path $InstallerPath) { Remove-Item $InstallerPath -Force }
Restart-Service -Name "rustdesk" -ErrorAction SilentlyContinue

# Gọi lệnh lấy ID của RustDesk
$RustDeskID = & "$RustDeskExe" --get-id

Write-Host "`n======================================================================" -ForegroundColor Green
Write-Host " HOAN TAT! IP Server, Key va Mat khau co dinh da duoc nap thanh cong." -ForegroundColor Green
Write-Host " RustDesk ID cua may nay: $RustDeskID" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Green