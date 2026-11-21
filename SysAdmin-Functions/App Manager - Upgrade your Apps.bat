<# :
@cls
@echo off
title Winget Auto Upgrade Manager v2.5

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
# LOI POWERSHELL CUA BAN BAT DAU TU DAY
# =========================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Danh sach luu cac App ID nguoi dung chon bo qua tam thoi trong phien lam viec
$script:IgnoredAppIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

# ------------------------------------------------------------------------------
# [FLAG: UI_BANNER] - Hien thi tieu de chuong trinh
# ------------------------------------------------------------------------------
function Show-HeaderBanner {
    param (
        [string]$SubTitle = "WINGET AUTO UPGRADE MANAGER v2.5"
    )
    Clear-Host
    Write-Host "==========================================================================================================" -ForegroundColor Cyan
    Write-Host ("{0,68}" -f $SubTitle) -ForegroundColor Yellow
    Write-Host "              Copyright (c) 2026 Trung Nguyen (trungnm.work@gmail.com). All rights reserved.              " -ForegroundColor Yellow
    Write-Host "                        Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor Yellow
    Write-Host "==========================================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ------------------------------------------------------------------------------
# [FLAG: CHECK_PREREQUISITES] - Kiem tra moi truong Winget
# ------------------------------------------------------------------------------
function Test-WingetEnvironment {
    if (-not (Get-Command "winget" -ErrorAction SilentlyContinue)) {
        Write-Host "[LOI] Khong tim thay Winget tren he thong. Vui long cai dat App Installer!" -ForegroundColor Red
        return $false
    }
    return $true
}

# ------------------------------------------------------------------------------
# [FLAG: FORMAT_HELPER] - Rut gon chuoi hien thi de khong bi vo cot tren Console
# ------------------------------------------------------------------------------
function Format-TruncatedText {
    param (
        [string]$Text,
        [int]$MaxLength
    )
    if ([string]::IsNullOrEmpty($Text)) { return "" }
    if ($Text.Length -le $MaxLength) { return $Text }
    return $Text.Substring(0, $MaxLength - 3) + "..."
}

# ------------------------------------------------------------------------------
# [FLAG: READ_MAIN_INPUT] - Doc va phan tich cu phap nhap tai menu chinh
# ------------------------------------------------------------------------------
function Read-MainMenuInput {
    param (
        [bool]$HasApps = $true,
        [string]$WarningMessage = ""
    )

    Write-Host ""
    Write-Host "HUONG DAN THAO TAC:" -ForegroundColor Cyan
    if ($HasApps) {
        Write-Host "  [STT]      : Nhap so thu tu de cap nhat phan mem tuong ung (VD: 1, 2, 15...)" -ForegroundColor White
        Write-Host "  [all]      : Cap nhat TAT CA phan mem dang hien thi" -ForegroundColor White
        Write-Host "  [s + STT]  : Bo qua phan mem khong muon update (VD: go 's2' de bo qua muc so 2)" -ForegroundColor Yellow
    }
    Write-Host "  [p]        : Quan ly danh sach phan mem dang bi khoa (winget pin list / remove)" -ForegroundColor Magenta
    Write-Host "  [0]        : Thoat chuong trinh" -ForegroundColor DarkGray
    Write-Host ""

    if (-not [string]::IsNullOrEmpty($WarningMessage)) {
        Write-Host $WarningMessage -ForegroundColor Red
    }

    $rawInput = (Read-Host "Lua chon cua ban").Trim().ToLower()

    if ($rawInput -eq "0") {
        return [PSCustomObject]@{ Action = "Exit"; Value = 0 }
    }
    elseif ($rawInput -eq "p") {
        return [PSCustomObject]@{ Action = "PinManager"; Value = "p" }
    }
    elseif ($rawInput -eq "all" -and $HasApps) {
        return [PSCustomObject]@{ Action = "All"; Value = "all" }
    }
    elseif ($rawInput -match '^[1-9]\d*$' -and $HasApps) {
        return [PSCustomObject]@{ Action = "Upgrade"; Value = [int]$rawInput }
    }
    elseif ($rawInput -match '^s([1-9]\d*)$' -and $HasApps) {
        return [PSCustomObject]@{ Action = "Ignore"; Value = [int]$Matches[1] }
    }

    return [PSCustomObject]@{ Action = "Invalid"; Value = $rawInput }
}

# ------------------------------------------------------------------------------
# [FLAG: READ_PIN_INPUT] - Doc va phan tich cu phap tai menu quan ly khoa
# ------------------------------------------------------------------------------
function Read-PinMenuInput {
    param (
        [string]$WarningMessage = ""
    )

    Write-Host ""
    Write-Host "HUONG DAN MO KHOA PHAN MEM (UNPIN):" -ForegroundColor Magenta
    Write-Host "  [STT]      : Nhap so thu tu (STT) de MO KHOA phan mem tuong ung (VD: 1, 2...)" -ForegroundColor White
    Write-Host "  [all]      : Go 'all' de MO KHOA TAT CA phan mem trong danh sach" -ForegroundColor Cyan
    Write-Host "  [0]        : Nhap '0' de quay lai menu cap nhat chinh" -ForegroundColor DarkGray
    Write-Host ""

    if (-not [string]::IsNullOrEmpty($WarningMessage)) {
        Write-Host $WarningMessage -ForegroundColor Red
    }

    $rawInput = (Read-Host "Nhap STT hoac 'all' de mo khoa").Trim().ToLower()

    if ($rawInput -eq "0") {
        return [PSCustomObject]@{ Action = "Back"; Value = 0 }
    }
    elseif ($rawInput -eq "all") {
        return [PSCustomObject]@{ Action = "UnpinAll"; Value = "all" }
    }
    elseif ($rawInput -match '^[1-9]\d*$') {
        return [PSCustomObject]@{ Action = "Unpin"; Value = [int]$rawInput }
    }

    return [PSCustomObject]@{ Action = "Invalid"; Value = $rawInput }
}

# ------------------------------------------------------------------------------
# [FLAG: PARSE_WINGET_UPGRADES] - Quet danh sach app va loc bo cac app da bo qua
# ------------------------------------------------------------------------------
function Get-WingetUpgradeList {
    Write-Host "[INFO] Dang quet danh sach phan mem co ban cap nhat moi..." -ForegroundColor Cyan

    $rawList = @()

    if (Get-Module -ListAvailable -Name Microsoft.WinGet.Client) {
        try {
            Import-Module Microsoft.WinGet.Client -ErrorAction Stop
            $packages = @(Get-WinGetPackage | Where-Object { $_.IsUpdateAvailable -eq $true })
            foreach ($pkg in $packages) {
                $rawList += [PSCustomObject]@{
                    Name      = $pkg.Name
                    Id        = $pkg.Id
                    Version   = $pkg.InstalledVersion
                    Available = ($pkg.AvailableVersions | Select-Object -First 1)
                }
            }
        }
        catch {
            $rawList = @()
        }
    }

    if ($rawList.Count -eq 0) {
        $rawOutput = winget list --upgrade-available --accept-source-agreements 2>&1 | Out-String
        $lines = $rawOutput -split "`r?`n"

        $headerIndex = -1
        for ($i = 0; $i -lt $lines.Count; $i++) {
            if ($lines[$i] -match 'Name\s+Id\s+Version\s+Available') {
                $headerIndex = $i
                break
            }
        }

        if ($headerIndex -ne -1) {
            $headerLine = $lines[$headerIndex]
            $idStart = $headerLine.IndexOf("Id")
            $verStart = $headerLine.IndexOf("Version")
            $availStart = $headerLine.IndexOf("Available")
            $srcStart = $headerLine.IndexOf("Source")

            for ($i = $headerIndex + 2; $i -lt $lines.Count; $i++) {
                $line = $lines[$i]
                if ([string]::IsNullOrWhiteSpace($line) -or $line -match 'upgrades available\.') {
                    continue
                }
                if ($line.Length -lt $availStart) {
                    continue
                }

                try {
                    $name = $line.Substring(0, $idStart).Trim()
                    $id = $line.Substring($idStart, $verStart - $idStart).Trim()
                    $version = $line.Substring($verStart, $availStart - $verStart).Trim()

                    if ($srcStart -gt $availStart -and $line.Length -ge $srcStart) {
                        $available = $line.Substring($availStart, $srcStart - $availStart).Trim()
                    }
                    else {
                        $available = $line.Substring($availStart).Trim()
                    }

                    if (-not [string]::IsNullOrWhiteSpace($id)) {
                        $rawList += [PSCustomObject]@{
                            Name      = $name
                            Id        = $id
                            Version   = $version
                            Available = $available
                        }
                    }
                }
                catch {
                    continue
                }
            }
        }
    }

    $filteredList = @()
    $stt = 1
    foreach ($item in $rawList) {
        if (-not $script:IgnoredAppIds.Contains($item.Id)) {
            $filteredList += [PSCustomObject]@{
                STT       = $stt
                Name      = $item.Name
                Id        = $item.Id
                Version   = $item.Version
                Available = $item.Available
            }
            $stt++
        }
    }

    return $filteredList
}

# ------------------------------------------------------------------------------
# [FLAG: PARSE_WINGET_PINS] - Lay danh sach phan mem dang bi khoa (winget pin list)
# ------------------------------------------------------------------------------
function Get-WingetPinList {
    Write-Host "[INFO] Dang tai danh sach phan mem dang bi khoa (winget pin list)..." -ForegroundColor Cyan

    $rawOutput = winget pin list --accept-source-agreements 2>&1 | Out-String
    $lines = $rawOutput -split "`r?`n"

    $headerIndex = -1
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match 'Name\s+Id\s+Version') {
            $headerIndex = $i
            break
        }
    }

    if ($headerIndex -eq -1) {
        return @()
    }

    $headerLine = $lines[$headerIndex]
    $idStart = $headerLine.IndexOf("Id")
    $verStart = $headerLine.IndexOf("Version")
    $srcStart = $headerLine.IndexOf("Source")
    $pinTypeStart = $headerLine.IndexOf("Pin type")
    if ($pinTypeStart -eq -1) {
        $pinTypeStart = $headerLine.IndexOf("Pinned")
    }

    $pinList = @()
    $stt = 1

    for ($i = $headerIndex + 2; $i -lt $lines.Count; $i++) {
        $line = $lines[$i]
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line.Length -lt $verStart) { continue }

        try {
            $name = $line.Substring(0, $idStart).Trim()
            $id = $line.Substring($idStart, $verStart - $idStart).Trim()

            if ($srcStart -gt $verStart -and $line.Length -ge $srcStart) {
                $version = $line.Substring($verStart, $srcStart - $verStart).Trim()
            }
            else {
                $version = $line.Substring($verStart).Trim()
            }

            $pinType = "Pinning"
            if ($pinTypeStart -gt 0 -and $line.Length -gt $pinTypeStart) {
                $pinType = $line.Substring($pinTypeStart).Trim()
            }

            if (-not [string]::IsNullOrWhiteSpace($id)) {
                $pinList += [PSCustomObject]@{
                    STT     = $stt
                    Name    = $name
                    Id      = $id
                    Version = $version
                    PinType = $pinType
                }
                $stt++
            }
        }
        catch {
            continue
        }
    }

    return $pinList
}

# ------------------------------------------------------------------------------
# [FLAG: WINGET_PIN_MANAGER] - Giao dien xem danh sach khoa va go khoa phan mem
# ------------------------------------------------------------------------------
function Invoke-WingetPinManager {
    $pinnedApps = @()
    $needPinRefresh = $true
    $hasPinChanged = $false
    $pinWarning = ""

    while ($true) {
        Show-HeaderBanner -SubTitle "WINGET PIN MANAGER - QUAN LY KHOA CAP NHAT"

        if ($needPinRefresh) {
            $pinnedApps = @(Get-WingetPinList)
            $needPinRefresh = $false
        }

        if ($pinnedApps.Count -eq 0) {
            Write-Host ""
            Write-Host "[INFO] Hien tai khong co phan mem nao dang bi khoa (Pin) tren he thong." -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Nhan Enter de quay lai menu chinh"
            return $hasPinChanged
        }

        Write-Host ""
        Write-Host "DANH SACH PHAN MEM DANG BI KHOA CAP NHAT (WINGET PIN LIST):" -ForegroundColor Magenta

        # Them | Out-Host de ep PowerShell in bang danh sach ngay lap tuc ra man hinh
        $pinnedApps | Format-Table -Property `
            @{Label = "STT"; Expression = { $_.STT }; Width = 4; Alignment = "Left" },
            @{Label = "Ten Phan Mem"; Expression = { Format-TruncatedText -Text $_.Name -MaxLength 28 }; Width = 29; Alignment = "Left" },
            @{Label = "App ID"; Expression = { Format-TruncatedText -Text $_.Id -MaxLength 34 }; Width = 35; Alignment = "Left" },
            @{Label = "Phien Ban"; Expression = { Format-TruncatedText -Text $_.Version -MaxLength 15 }; Width = 16; Alignment = "Left" },
            @{Label = "Loai Khoa"; Expression = { Format-TruncatedText -Text $_.PinType -MaxLength 14 }; Width = 15; Alignment = "Left" } | Out-Host

        $pinChoice = Read-PinMenuInput -WarningMessage $pinWarning
        $pinWarning = ""

        # Nhap sai cu phap -> Xoa man hinh va in lai bang cache ngay lap tuc
        if ($pinChoice.Action -eq "Invalid") {
            $pinWarning = "[CANH BAO] Lua chon '$($pinChoice.Value)' khong hop le! Vui long nhap lai."
            continue
        }

        # Quay lai menu chinh
        if ($pinChoice.Action -eq "Back") {
            return $hasPinChanged
        }

        # Go khoa tat ca
        if ($pinChoice.Action -eq "UnpinAll") {
            Write-Host ""
            Write-Host "[RUN] Dang mo khoa TAT CA phan mem (winget pin reset --force)..." -ForegroundColor Cyan
            winget pin reset --force --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                $script:IgnoredAppIds.Clear()
                Write-Host "[OK] Da mo khoa toan bo phan mem thanh cong!" -ForegroundColor Green
            }
            else {
                Write-Host "[CANH BAO] Dang thu mo khoa lan luot tung phan mem..." -ForegroundColor Yellow
                foreach ($pApp in $pinnedApps) {
                    winget pin remove --id "$($pApp.Id)" --exact --accept-source-agreements
                    [void]$script:IgnoredAppIds.Remove($pApp.Id)
                }
            }
            $hasPinChanged = $true
            $needPinRefresh = $true
            Write-Host ""
            Read-Host "Nhan Enter de tai lai danh sach khoa"
            continue
        }

        # Go khoa 1 phan mem theo STT
        if ($pinChoice.Action -eq "Unpin") {
            $selectedPin = $pinnedApps | Where-Object { $_.STT -eq $pinChoice.Value } | Select-Object -First 1
            if ($null -eq $selectedPin) {
                $pinWarning = "[CANH BAO] Khong tim thay STT '$($pinChoice.Value)' trong danh sach! Vui long nhap lai."
                continue
            }

            Write-Host ""
            Write-Host "[RUN] Dang mo khoa [$($selectedPin.STT)] $($selectedPin.Name) (ID: $($selectedPin.Id))..." -ForegroundColor Cyan
            winget pin remove --id "$($selectedPin.Id)" --exact --accept-source-agreements

            if ($LASTEXITCODE -eq 0) {
                [void]$script:IgnoredAppIds.Remove($selectedPin.Id)
                $hasPinChanged = $true
                $needPinRefresh = $true
                Write-Host "[OK] Da mo khoa thanh cong cho '$($selectedPin.Name)'!" -ForegroundColor Green
            }
            else {
                Write-Host "[CANH BAO] Khong the tu dong mo khoa (co the do App ID bi cat ngan)." -ForegroundColor Red
                $manualPinId = Read-Host "Nhap chinh xac App ID de mo khoa (hoac nhan Enter de bo qua)"
                if (-not [string]::IsNullOrWhiteSpace($manualPinId)) {
                    $manualPinId = $manualPinId.Trim()
                    winget pin remove --id "$manualPinId" --exact --accept-source-agreements
                    if ($LASTEXITCODE -eq 0) {
                        [void]$script:IgnoredAppIds.Remove($manualPinId)
                        $hasPinChanged = $true
                        $needPinRefresh = $true
                        Write-Host "[OK] Da mo khoa thanh cong cho ID: $manualPinId!" -ForegroundColor Green
                    }
                    else {
                        Write-Host "[LOI] Van khong the mo khoa ID '$manualPinId'." -ForegroundColor Red
                    }
                }
            }
            Write-Host ""
            Read-Host "Nhan Enter de tai lai danh sach khoa"
            continue
        }
    }
}

# ------------------------------------------------------------------------------
# [FLAG: UPGRADE_SINGLE_APP] - Xu ly cap nhat 1 app va fallback nhap ID thu cong
# ------------------------------------------------------------------------------
function Invoke-SingleAppUpgrade {
    param (
        [PSCustomObject]$App
    )

    Write-Host ""
    Write-Host "[RUN] Dang cap nhat [$($App.STT)] $($App.Name) ($($App.Version) -> $($App.Available))..." -ForegroundColor Cyan

    winget upgrade --id "$($App.Id)" --exact --include-unknown --accept-package-agreements --accept-source-agreements
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        Write-Host ""
        Write-Host "[CANH BAO] Winget khong the tu dong cap nhat phan mem nay (Ma loi: $exitCode)." -ForegroundColor Red
        Write-Host "Nguyen nhan co the do App ID bi cat ngan tren bang hien thi hoac yeu cau xac minh ID chinh xac." -ForegroundColor Yellow
        
        $manualId = Read-Host "Vui long nhap chinh xac ID app de thu lai (hoac nhan Enter de bo qua)"
        if (-not [string]::IsNullOrWhiteSpace($manualId)) {
            $manualId = $manualId.Trim()
            Write-Host "[RUN] Dang thu cap nhat lai voi ID thu cong: $manualId ..." -ForegroundColor Cyan
            winget upgrade --id "$manualId" --exact --include-unknown --accept-package-agreements --accept-source-agreements
            
            if ($LASTEXITCODE -eq 0) {
                Write-Host "[OK] Cap nhat thanh cong phan mem voi ID: $manualId!" -ForegroundColor Green
            }
            else {
                Write-Host "[LOI] Van khong the cap nhat phan mem '$manualId'." -ForegroundColor Red
            }
        }
        else {
            Write-Host "[INFO] Da bo qua cap nhat phan mem nay." -ForegroundColor DarkGray
        }
    }
    else {
        Write-Host "[OK] Da cap nhat thanh cong $($App.Name)!" -ForegroundColor Green
    }
}

# ------------------------------------------------------------------------------
# [FLAG: IGNORE_APP_HANDLER] - Xu ly bo qua tam thoi hoac khoa vinh vien (Pin)
# ------------------------------------------------------------------------------
function Invoke-IgnoreApp {
    param (
        [PSCustomObject]$App
    )

    $warnMsg = ""
    while ($true) {
        Show-HeaderBanner -SubTitle "TUY CHON BO QUA PHAN MEM"
        Write-Host "Phan mem dang chon: $($App.Name) (ID: $($App.Id))" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  [1] Chi bo qua tam thoi trong phien lam viec nay" -ForegroundColor White
        Write-Host "  [2] Khoa cap nhat vinh vien (winget pin add)" -ForegroundColor White
        Write-Host "  [0] Huy thao tac va quay lai" -ForegroundColor DarkGray
        Write-Host ""

        if (-not [string]::IsNullOrEmpty($warnMsg)) {
            Write-Host $warnMsg -ForegroundColor Red
            $warnMsg = ""
        }

        $choice = (Read-Host "Chon che do bo qua (0/1/2)").Trim()

        if ($choice -eq "1") {
            [void]$script:IgnoredAppIds.Add($App.Id)
            Write-Host "[OK] Da an '$($App.Name)' khoi danh sach phien hien tai." -ForegroundColor Green
            Start-Sleep -Milliseconds 600
            return $true
        }
        elseif ($choice -eq "2") {
            winget pin add --id "$($App.Id)" --exact --accept-source-agreements
            if ($LASTEXITCODE -eq 0) {
                [void]$script:IgnoredAppIds.Add($App.Id)
                Write-Host "[OK] Da khoa cap nhat vinh vien cho '$($App.Name)' bang Winget Pin!" -ForegroundColor Green
            }
            else {
                Write-Host "[LOI] Khong the Pin phan mem nay (co the do App ID bi rut gon). An tam thoi trong phien." -ForegroundColor Red
                [void]$script:IgnoredAppIds.Add($App.Id)
            }
            Start-Sleep -Seconds 1
            return $true
        }
        elseif ($choice -eq "0") {
            return $false
        }
        else {
            $warnMsg = "[CANH BAO] Lua chon '$choice' khong hop le! Vui long nhap 0, 1 hoac 2."
        }
    }
}

# ------------------------------------------------------------------------------
# [FLAG: INVOKE_WINGET_UPGRADE_MANAGER] - Vong lap menu chinh co cache danh sach
# ------------------------------------------------------------------------------
function Invoke-WingetUpgradeManager {
    if (-not (Test-WingetEnvironment)) { return }

    $apps = @()
    $needRefresh = $true
    $menuWarning = ""

    while ($true) {
        Show-HeaderBanner

        if ($script:IgnoredAppIds.Count -gt 0) {
            Write-Host "[INFO] Dang an $($script:IgnoredAppIds.Count) phan mem bi bo qua trong phien nay." -ForegroundColor DarkYellow
        }

        if ($needRefresh) {
            $apps = @(Get-WingetUpgradeList)
            $needRefresh = $false
        }

        if ($apps.Count -eq 0) {
            Write-Host ""
            Write-Host "[OK] Khong con phan mem nao can cap nhat trong danh sach hien thi!" -ForegroundColor Green
            
            $emptyChoice = Read-MainMenuInput -HasApps $false -WarningMessage $menuWarning
            $menuWarning = ""

            if ($emptyChoice.Action -eq "PinManager") {
                $changed = Invoke-WingetPinManager
                if ($changed) { $needRefresh = $true }
                continue
            }
            elseif ($emptyChoice.Action -eq "Exit") {
                Write-Host ""
                Write-Host "[INFO] Da thoat Winget Auto Upgrade Manager." -ForegroundColor Cyan
                break
            }
            else {
                $menuWarning = "[CANH BAO] Lua chon '$($emptyChoice.Value)' khong hop le! Vui long nhap 'p' hoac '0'."
                continue
            }
        }

        Write-Host ""
        Write-Host "DANH SACH PHAN MEM CO BAN CAP NHAT MOI:" -ForegroundColor Yellow

        $apps | Format-Table -Property `
            @{Label = "STT"; Expression = { $_.STT }; Width = 4; Alignment = "Left" },
            @{Label = "Ten Phan Mem"; Expression = { Format-TruncatedText -Text $_.Name -MaxLength 28 }; Width = 29; Alignment = "Left" },
            @{Label = "App ID"; Expression = { Format-TruncatedText -Text $_.Id -MaxLength 32 }; Width = 33; Alignment = "Left" },
            @{Label = "Hien Tai"; Expression = { Format-TruncatedText -Text $_.Version -MaxLength 15 }; Width = 16; Alignment = "Left" },
            @{Label = "Ban Moi"; Expression = { Format-TruncatedText -Text $_.Available -MaxLength 15 }; Width = 16; Alignment = "Left" }

        $inputResult = Read-MainMenuInput -HasApps $true -WarningMessage $menuWarning
        $menuWarning = ""

        # 0. Nhap sai cu phap -> Xoa man hinh va ve lai bang cache ngay lap tuc
        if ($inputResult.Action -eq "Invalid") {
            $menuWarning = "[CANH BAO] Lua chon '$($inputResult.Value)' khong hop le! Vui long nhap lai."
            continue
        }

        # 1. Thoat vong lap khi nhap 0
        if ($inputResult.Action -eq "Exit") {
            Write-Host ""
            Write-Host "[INFO] Da thoat Winget Auto Upgrade Manager." -ForegroundColor Cyan
            break
        }

        # 2. Mo giao dien quan ly khoa (Pin Manager) khi nhap p
        if ($inputResult.Action -eq "PinManager") {
            $changed = Invoke-WingetPinManager
            if ($changed) { $needRefresh = $true }
            continue
        }

        # 3. Bo qua phan mem (s + STT) -> Doi chieu truc tiep STT trong bang
        if ($inputResult.Action -eq "Ignore") {
            $targetApp = $apps | Where-Object { $_.STT -eq $inputResult.Value } | Select-Object -First 1
            if ($null -eq $targetApp) {
                $menuWarning = "[CANH BAO] Khong tim thay STT '$($inputResult.Value)' trong danh sach! Vui long nhap lai."
                continue
            }

            $isIgnored = Invoke-IgnoreApp -App $targetApp
            if ($isIgnored) {
                $newApps = @()
                $newStt = 1
                foreach ($item in $apps) {
                    if (-not $script:IgnoredAppIds.Contains($item.Id)) {
                        $item.STT = $newStt
                        $newApps += $item
                        $newStt++
                    }
                }
                $apps = $newApps
            }
            continue
        }

        # 4. Upgrade All (chi chay tren danh sach cac app chua bi bo qua)
        if ($inputResult.Action -eq "All") {
            Write-Host ""
            if ($script:IgnoredAppIds.Count -eq 0) {
                Write-Host "[RUN] Dang tien hanh cap nhat TOAN BO phan mem..." -ForegroundColor Cyan
                winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
            }
            else {
                Write-Host "[RUN] Dang cap nhat toan bo $($apps.Count) phan mem (bo qua cac app da an)..." -ForegroundColor Cyan
                foreach ($app in $apps) {
                    Invoke-SingleAppUpgrade -App $app
                }
            }
            $needRefresh = $true
            Write-Host ""
            Read-Host "Nhan Enter de tai lai danh sach va quay ve menu"
            continue
        }

        # 5. Upgrade 1 app theo STT -> Doi chieu truc tiep STT trong bang
        if ($inputResult.Action -eq "Upgrade") {
            $selectedApp = $apps | Where-Object { $_.STT -eq $inputResult.Value } | Select-Object -First 1
            if ($null -eq $selectedApp) {
                $menuWarning = "[CANH BAO] Khong tim thay STT '$($inputResult.Value)' trong danh sach! Vui long nhap lai."
                continue
            }

            Invoke-SingleAppUpgrade -App $selectedApp
            $needRefresh = $true
            Write-Host ""
            Read-Host "Nhan Enter de cap nhat lai danh sach va quay ve menu"
            continue
        }
    }
}

# ------------------------------------------------------------------------------
# [FLAG: MAIN_EXECUTION] - Khoi chay chuong trinh
# ------------------------------------------------------------------------------
try {
    Invoke-WingetUpgradeManager
}
catch {
    Write-Host "[LOI HE THONG] $($_.Exception.Message)" -ForegroundColor Red
}