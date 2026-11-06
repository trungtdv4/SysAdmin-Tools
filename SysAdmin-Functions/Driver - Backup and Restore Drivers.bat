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
# [FLAG: SELECTIVE_BACKUP] - Quét phần cứng, gộp nhóm và trích xuất theo STT
# ------------------------------------------------------------------------------
function Invoke-ExportDriverByHardwareSelect {
    Show-Banner
    Write-Host "[+] Dang quet va gom nhom danh sach Driver OEM trong he thong..." -ForegroundColor Cyan
    Write-Host ""

    # Hàm nội bộ bóc tách tên từ file .inf (Tránh lỗi CommandNotFoundException)
    function Script:Get-InfDeviceNameInternal {
        param ([string]$InfFilePath)
        if (-not (Test-Path -Path $InfFilePath)) { return $null }
        $lines = Get-Content -Path $InfFilePath -ErrorAction SilentlyContinue
        $inStrings = $false
        foreach ($line in $lines) {
            $trimmed = $line.Trim()
            if ($trimmed -match '^\[Strings.*\]') { $inStrings = $true; continue }
            if ($inStrings -and $trimmed -match '^\[.*\]') { break }
            if ($inStrings -and $trimmed -match 'DeviceDesc\s*=\s*"([^"]+)"') { return $matches[1] }
            if ($inStrings -and $trimmed -match '^\s*[\w\.\%]+\s*=\s*"([^"]+)"') { return $matches[1] }
        }
        return $null
    }

    # Lấy danh sách Driver OEM
    $oemDrivers = Get-WindowsDriver -Online -ErrorAction SilentlyContinue
    if (-not $oemDrivers) {
        Write-Host "[!] Khong tim thay Driver OEM nao trong he thong!" -ForegroundColor Red
        return
    }

    $signedDrivers = Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue

    # Bảng băm (Hashtable) dùng để gộp các thư mục driver trùng tên thiết bị
    $hardwareMap = @{}

    foreach ($drv in $oemDrivers) {
        # Ưu tiên lấy tên hiển thị chuẩn từ Device Manager
        $matchedSigned = $signedDrivers | Where-Object { $_.InfName -eq $drv.Driver } | Select-Object -First 1
        
        if ($matchedSigned -and $matchedSigned.DeviceName) {
            $deviceName = $matchedSigned.DeviceName
        } else {
            $deviceName = Get-InfDeviceNameInternal -InfFilePath $drv.OriginalFileName
            if ([string]::IsNullOrWhiteSpace($deviceName)) {
                $deviceName = "$($drv.ClassName) ($($drv.Driver))"
            }
        }

        $folderPath = Split-Path -Path $drv.OriginalFileName -Parent
        $provider   = if ($drv.ProviderName) { $drv.ProviderName } else { "OEM" }
        $class      = if ($drv.ClassName)    { $drv.ClassName }    else { "Unknown" }

        # Khóa nhận diện gộp nhóm: Tên thiết bị + Nhà sản xuất
        $groupKey = "$deviceName|$provider"

        if (-not $hardwareMap.ContainsKey($groupKey)) {
            $hardwareMap[$groupKey] = [PSCustomObject]@{
                DeviceName  = $deviceName
                Provider    = $provider
                Class       = $class
                FolderPaths = [System.Collections.Generic.HashSet[string]]::new()
            }
        }
        # Thêm thư mục driver vào danh sách của thiết bị đó (tự động loại bỏ thư mục trùng)
        [void]$hardwareMap[$groupKey].FolderPaths.Add($folderPath)
    }

    # Chuyển danh sách đã gộp thành mảng có đánh STT
    $driverList = @()
    $idx = 1
    foreach ($key in ($hardwareMap.Keys | Sort-Object)) {
        $item = $hardwareMap[$key]
        $driverList += [PSCustomObject]@{
            Index       = $idx
            DeviceName  = $item.DeviceName
            Provider    = $item.Provider
            Class       = $item.Class
            FolderPaths = $item.FolderPaths
            FolderCount = $item.FolderPaths.Count
        }
        $idx++
    }

    # Hiển thị Menu bảng gọn gàng (Mỗi thiết bị chỉ xuất hiện 1 dòng)
    Write-Host ("{0,-5} | {1,-42} | {2,-12} | {3,-15} | {4,-7}" -f "STT", "Ten Thiet Bi (Device Manager Name)", "Loai (Class)", "Nha San Xuat", "Folders") -ForegroundColor Yellow
    Write-Host ("-" * 93) -ForegroundColor DarkGray

    foreach ($item in $driverList) {
        $displayName = $item.DeviceName
        if ($displayName.Length -gt 42) { $displayName = $displayName.Substring(0, 39) + "..." }
        
        Write-Host ("[{0,2}]  | {1,-42} | {2,-12} | {3,-15} | [{4} Fdr]" -f $item.Index, $displayName, $item.Class, $item.Provider, $item.FolderCount) -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "[i] Nhap STT thiet bi muon trich xuat (Chon nhieu phan cach bang dau phay, vd: 1,4,7)" -ForegroundColor Cyan
    $selection = Read-Host "Nhap lua chon cua ban"

    if ([string]::IsNullOrWhiteSpace($selection)) {
        Write-Host "[!] Ban chua chon thiet bi nao. Huy thao tac." -ForegroundColor Red
        return
    }

    $selectedIndices = $selection -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' } | ForEach-Object { [int]$_ }
    $targetItems = $driverList | Where-Object { $selectedIndices -contains $_.Index }

    if (-not $targetItems) {
        Write-Host "[!] So thu tu chon khong hop le!" -ForegroundColor Red
        return
    }

    $backupPath = "D:\DriverBackup_Selected"
    if (-not (Test-Path -Path $backupPath)) {
        New-Item -Path $backupPath -ItemType Directory -Force | Out-Null
    }

    Write-Host ""
    Write-Host "[+] Bat dau trich xuat Driver cho $($targetItems.Count) thiet bi vao: $backupPath" -ForegroundColor Cyan
    Write-Host ""

    foreach ($item in $targetItems) {
        Write-Host "[*] Dang sao luu: [$($item.DeviceName)] (Gom $($item.FolderCount) thu muc liên quan)..." -ForegroundColor Yellow
        
        foreach ($folderPath in $item.FolderPaths) {
            $folderLeafName = Split-Path -Path $folderPath -Leaf
            $destDir = Join-Path -Path $backupPath -ChildPath $folderLeafName

            Try {
                Copy-Item -Path $folderPath -Destination $destDir -Recurse -Force
                Write-Host "    -> Copy thanh cong: $folderLeafName" -ForegroundColor Green
            } Catch {
                Write-Host "    -> Loi copy $folderLeafName : $_" -ForegroundColor Red
            }
        }
    }

    Write-Host ""
    Write-Host "[OK] Da trich xuat xong toan bo Driver duoc chon vao: $backupPath" -ForegroundColor Green
}

# ------------------------------------------------------------------------------
# [FLAG: MENU_SYSTEM] - Menu dieu huong va tuong tac
# ------------------------------------------------------------------------------
function Main-Menu {
    do {
        Show-Banner
        Write-Host "   === CHON CHUC NANG ===" -ForegroundColor White
        Write-Host "   1. Backup TOAN BO Drivers (DISM - Toan bo thiet bi)" -ForegroundColor Green
        Write-Host "   2. Restore Drivers        (PnPUtil)" -ForegroundColor Green
        Write-Host "   3. Backup THEO HARDWARE   (Chon thiet bi qua Device Manager STT)" -ForegroundColor Yellow
        Write-Host "   0. Thoat" -ForegroundColor Red
        Write-Host ""
        
        $choice = Read-Host "Nhap lua chon cua ban [0-3]"

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
            '3' {
                Invoke-ExportDriverByHardwareSelect
                Write-Host ""
                Read-Host "Nhan Enter de tro ve Menu..."
            }
            '0' {
                Write-Host "[i] Dang thoat chuong trinh..." -ForegroundColor Cyan
                return
            }
            default {
                Write-Host "[!] Lua chon khong hop le." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    } while ($true)
}

# Kich hoat Menu chinh
Main-Menu