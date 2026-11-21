<# :
@cls
@echo off
title IP Manager (Set IP, Gateway, DNS, IPv6)

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
# LÕI POWERSHELL CỦA BẠN BẮT ĐẦU TỪ ĐÂY
# =========================================================
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$ErrorActionPreference = 'Stop'

# ------------------------------------------------------------------------------
# [FLAG: BANNER_INFO] - Hien thi thong tin ban quyen cong cu
# ------------------------------------------------------------------------------
function Show-Banner {
    Clear-Host
    Write-Host "===================================================================================" -ForegroundColor Cyan
    Write-Host "                  CONG CU CAU HINH CARD MANG WINDOWS (ADMIN TOOLS)                  " -ForegroundColor Yellow
    Write-Host "   Copyright (c) 2026 Trung Nguyen (trungnm.work@gmail.com). All rights reserved.  " -ForegroundColor Yellow
    Write-Host "             Licensed under the GNU General Public License v3.0 (GPLv3).           " -ForegroundColor Yellow
    Write-Host "===================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ------------------------------------------------------------------------------
# [FLAG: HELPER_NETWORK_UTILS] - Cac ham ho tro kiem tra IP, Subnet Mask va thong tin Card
# ------------------------------------------------------------------------------
function Test-ValidIPv4 {
    param ([string]$IpString)
    $parsedIp = $null
    if ([System.Net.IPAddress]::TryParse($IpString, [ref]$parsedIp) -and $parsedIp.AddressFamily -eq 'InterNetwork') {
        return $true
    }
    return $false
}

function Convert-MaskToPrefix {
    param ([string]$MaskInput)
    # Neu nguoi dung nhap dang CIDR (VD: 24)
    if ($MaskInput -match '^\d{1,2}$') {
        $cidr = [int]$MaskInput
        if ($cidr -ge 1 -and $cidr -le 32) {
            return $cidr
        }
        return $null
    }
    # Neu nguoi dung nhap dang Subnet Mask (VD: 255.255.255.0)
    if (Test-ValidIPv4 -IpString $MaskInput) {
        $octets = $MaskInput.Split('.')
        $binaryStr = ($octets | ForEach-Object { [Convert]::ToString([int]$_, 2).PadLeft(8, '0') }) -join ''
        if ($binaryStr -match '^1+0*$') {
            return ($binaryStr.TrimEnd('0')).Length
        }
    }
    return $null
}

function Convert-PrefixToMask {
    param ([int]$PrefixLength)
    if ($PrefixLength -lt 0 -or $PrefixLength -gt 32) { return "" }
    $binaryStr = ('1' * $PrefixLength).PadRight(32, '0')
    $octets = for ($i = 0; $i -lt 32; $i += 8) {
        [Convert]::ToInt32($binaryStr.Substring($i, 8), 2)
    }
    return ($octets -join '.')
}

function Get-AdapterCurrentDetails {
    param ([int]$InterfaceIndex, [string]$AdapterName)

    $ipInterface = Get-NetIPInterface -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $dhcpMode = if ($ipInterface) { $ipInterface.Dhcp } else { "Unknown" }

    $ipv4Obj = Get-NetIPAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
               Where-Object { $_.IPAddress -notlike '169.254.*' } | Select-Object -First 1

    $currentIp = if ($ipv4Obj) { $ipv4Obj.IPAddress } else { "" }
    $currentPrefix = if ($ipv4Obj) { [int]$ipv4Obj.PrefixLength } else { 24 }
    $currentMask = if ($ipv4Obj) { Convert-PrefixToMask -PrefixLength $currentPrefix } else { "255.255.255.0" }

    $routeObj = Get-NetRoute -InterfaceIndex $InterfaceIndex -DestinationPrefix "0.0.0.0/0" -ErrorAction SilentlyContinue |
                Sort-Object RouteMetric | Select-Object -First 1
    $currentGw = if ($routeObj) { $routeObj.NextHop } else { "" }

    $dnsObj = Get-DnsClientServerAddress -InterfaceIndex $InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
    $currentDnsList = if ($dnsObj -and $dnsObj.ServerAddresses.Count -gt 0) { @($dnsObj.ServerAddresses) } else { @() }

    $ipv6Binding = Get-NetAdapterBinding -Name $AdapterName -ComponentID ms_tcpip6 -ErrorAction SilentlyContinue
    $ipv6Enabled = if ($ipv6Binding) { $ipv6Binding.Enabled } else { $false }

    return [PSCustomObject]@{
        DhcpMode    = $dhcpMode
        IPAddress   = $currentIp
        Prefix      = $currentPrefix
        SubnetMask  = $currentMask
        Gateway     = $currentGw
        DnsList     = $currentDnsList
        IPv6Enabled = $ipv6Enabled
    }
}

# ------------------------------------------------------------------------------
# [FLAG: SELECT_NETWORK_ADAPTER] - Quet danh sach Card mang va cho phep chon
# ------------------------------------------------------------------------------
function Select-NetworkAdapter {
    while ($true) {
        Show-Banner
        Write-Host "[*] Dang quet danh sach Card mang tren he thong..." -ForegroundColor Cyan
        Write-Host ""

        $adapters = @(Get-NetAdapter | Sort-Object -Property Status, Name)
        if ($adapters.Count -eq 0) {
            Write-Host "[!] Khong tim thay Card mang nao tren may!" -ForegroundColor Red
            return $null
        }

        for ($i = 0; $i -lt $adapters.Count; $i++) {
            $ad = $adapters[$i]
            $info = Get-AdapterCurrentDetails -InterfaceIndex $ad.ifIndex -AdapterName $ad.Name
            $statusColor = if ($ad.Status -eq 'Up') { 'Green' } else { 'DarkGray' }
            $ipDisplay = if ($info.IPAddress) { "$($info.IPAddress)/$($info.Prefix)" } else { "Chua co IP" }
            $gwDisplay = if ($info.Gateway) { $info.Gateway } else { "Empty" }
            $ipv6Text = if ($info.IPv6Enabled) { "Enable" } else { "Disable" }

            Write-Host (" [{0}] {1}" -f ($i + 1), $ad.Name) -ForegroundColor White -NoNewline
            Write-Host (" ({0}) - {1}" -f $ad.Status, $ad.InterfaceDescription) -ForegroundColor $statusColor
            Write-Host ("     Mode: {0} | IP: {1} | GW: {2} | IPv6: {3}" -f $info.DhcpMode, $ipDisplay, $gwDisplay, $ipv6Text) -ForegroundColor Gray
        }

        Write-Host ""
        Write-Host " [0] Thoat chuong trinh" -ForegroundColor DarkYellow
        Write-Host ""

        $choice = Read-Host "Nhap so thu tu Card mang muon cau hinh (1 - $($adapters.Count))"
        if ($choice -eq '0') { return $null }

        if ($choice -match '^\d+$') {
            $idx = [int]$choice - 1
            if ($idx -ge 0 -and $idx -lt $adapters.Count) {
                return $adapters[$idx]
            }
        }
        Write-Host "[!] Lua chon khong hop le. Nhan Enter de chon lai..." -ForegroundColor Red
        Read-Host | Out-Null
    }
}

# ------------------------------------------------------------------------------
# [FLAG: FUNC_SET_DHCP] - Chuc nang 1: Thiet lap IP dong (DHCP) va DNS tu dong
# ------------------------------------------------------------------------------
function Set-AdapterDHCP {
    param ($Adapter)
    try {
        Write-Host ""
        Write-Host "[*] Dang chuyen Card '$($Adapter.Name)' sang che do IP dong (DHCP)..." -ForegroundColor Cyan

        Remove-NetRoute -InterfaceIndex $Adapter.ifIndex -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
        Set-NetIPInterface -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 -Dhcp Enabled
        Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ResetServerAddresses

        Write-Host "[*] Dang khoi dong lai Card mang de nhan IP tu DHCP Server..." -ForegroundColor Yellow
        Restart-NetAdapter -Name $Adapter.Name -Confirm:$false
        Clear-DnsClientCache

        Write-Host "[OK] Da chuyen sang IP dong (DHCP) va DNS tu dong thanh cong!" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Loi khi thiet lap DHCP: $_" -ForegroundColor Red
    }
}

# ------------------------------------------------------------------------------
# [FLAG: FUNC_SET_STATIC] - Chuc nang 2: Cau hinh IP tinh, Subnet, Gateway, DNS
# ------------------------------------------------------------------------------
function Set-AdapterStaticConfig {
    param ($Adapter)
    $current = Get-AdapterCurrentDetails -InterfaceIndex $Adapter.ifIndex -AdapterName $Adapter.Name

    Write-Host ""
    Write-Host "===================================================================================" -ForegroundColor DarkCyan
    Write-Host " HUONG DAN NHAP THONG SO:" -ForegroundColor Yellow
    Write-Host " - Nhan [Enter] (bo trong) o bat ky o nao ban KHONG muon thay doi." -ForegroundColor Gray
    Write-Host " - He thong se tu dong giu nguyen thong so cu cua Card mang (hoac gia tri mac dinh)." -ForegroundColor Gray
    Write-Host " - Nhieu DNS thi nhap cach nhau bang dau phay ',' (VD: 8.8.8.8, 1.1.1.1)." -ForegroundColor Gray
    Write-Host "===================================================================================" -ForegroundColor DarkCyan
    Write-Host ""

    # 1. Nhap IP tinh
    $ipChanged = $false
    $finalIp = $current.IPAddress
    while ($true) {
        $dispIp = if ($current.IPAddress) { $current.IPAddress } else { "Chua co" }
        $inIp = (Read-Host "1. Nhap dia chi IPv4 tinh [Hien tai: $dispIp]").Trim()
        if ([string]::IsNullOrEmpty($inIp)) {
            if ([string]::IsNullOrEmpty($finalIp)) {
                Write-Host "[!] Card mang hien chua co dia chi IPv4. Bat buoc phai nhap IP!" -ForegroundColor Red
                continue
            }
            Write-Host "   -> Bo qua: Giu nguyen IP ($finalIp)" -ForegroundColor DarkGray
            break
        }
        if (Test-ValidIPv4 -IpString $inIp) {
            $finalIp = $inIp
            $ipChanged = $true
            break
        }
        Write-Host "[!] Dia chi IPv4 khong hop le. Vui long nhap lai!" -ForegroundColor Red
    }

    # 2. Nhap Subnet Mask
    $maskChanged = $false
    $finalPrefix = $current.Prefix
    while ($true) {
        $dispMask = "$($current.SubnetMask) (/$($current.Prefix))"
        $inMask = (Read-Host "2. Nhap Subnet Mask hoac CIDR [Hien tai: $dispMask]").Trim()
        if ([string]::IsNullOrEmpty($inMask)) {
            $finalMaskStr = Convert-PrefixToMask -PrefixLength $finalPrefix
            Write-Host "   -> Bo qua: Giu nguyen Subnet Mask ($finalMaskStr /$finalPrefix)" -ForegroundColor DarkGray
            break
        }
        $parsedPrefix = Convert-MaskToPrefix -MaskInput $inMask
        if ($null -ne $parsedPrefix) {
            $finalPrefix = $parsedPrefix
            $maskChanged = $true
            break
        }
        Write-Host "[!] Subnet Mask khong hop le (VD: 255.255.255.0 hoac 24). Vui long nhap lai!" -ForegroundColor Red
    }

    # 3. Nhap Default Gateway
    $gwChanged = $false
    $finalGw = $current.Gateway
    while ($true) {
        $dispGw = if ($current.Gateway) { $current.Gateway } else { "Empty" }
        $inGw = (Read-Host "3. Nhap Default Gateway [Hien tai: $dispGw]").Trim()
        if ([string]::IsNullOrEmpty($inGw)) {
            $gwText = if ($finalGw) { $finalGw } else { "Khong dat" }
            Write-Host "   -> Bo qua: Giu nguyen Default Gateway ($gwText)" -ForegroundColor DarkGray
            break
        }
        if (Test-ValidIPv4 -IpString $inGw) {
            $finalGw = $inGw
            $gwChanged = $true
            break
        }
        Write-Host "[!] Dia chi Gateway khong hop le. Vui long nhap lai!" -ForegroundColor Red
    }

    # 4. Nhap DNS (cach nhau bang dau phay)
    $dnsChanged = $false
    $finalDns = $current.DnsList
    while ($true) {
        $dispDns = if ($current.DnsList.Count -gt 0) { $current.DnsList -join ", " } else { "Auto / Empty" }
        $inDns = (Read-Host "4. Nhap DNS Server (cach nhau dau phay) [Hien tai: $dispDns]").Trim()
        if ([string]::IsNullOrEmpty($inDns)) {
            Write-Host "   -> Bo qua: Giu nguyen cau hinh DNS ($dispDns)" -ForegroundColor DarkGray
            break
        }
        $rawList = $inDns.Split(',') | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne "" }
        $allValid = $true
        foreach ($d in $rawList) {
            if (-not (Test-ValidIPv4 -IpString $d)) {
                $allValid = $false
                Write-Host "[!] DNS '$d' khong phai la IPv4 hop le!" -ForegroundColor Red
                break
            }
        }
        if ($allValid -and $rawList.Count -gt 0) {
            $finalDns = @($rawList)
            $dnsChanged = $true
            break
        }
    }

    # Kiem tra neu khong co thong so nao thay doi
    if (-not ($ipChanged -or $maskChanged -or $gwChanged -or $dnsChanged)) {
        Write-Host ""
        Write-Host "[!] Ban da bo qua tat ca thong so. Khong co thay doi nao duoc ap dung." -ForegroundColor Yellow
        return
    }

    # Thuc thi ap dung cau hinh
    try {
        Write-Host ""
        Write-Host "[*] Dang ap dung cau hinh mang moi cho '$($Adapter.Name)'..." -ForegroundColor Cyan

        # Truong hop chi doi Gateway ma card dang o che do Static -> chi can cap nhat Route (nhanh, khong mat IP)
        if (-not $ipChanged -and -not $maskChanged -and $gwChanged -and $current.DhcpMode -eq 'Disabled') {
            Remove-NetRoute -InterfaceIndex $Adapter.ifIndex -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
            New-NetRoute -InterfaceIndex $Adapter.ifIndex -DestinationPrefix "0.0.0.0/0" -NextHop $finalGw | Out-Null
            Write-Host " [+] Da cap nhat Default Gateway moi: $finalGw" -ForegroundColor Green
        }
        # Truong hop co doi IP/Subnet hoac chuyen tu DHCP sang co dinh Gateway
        elseif ($ipChanged -or $maskChanged -or ($gwChanged -and $current.DhcpMode -eq 'Enabled')) {
            Remove-NetRoute -InterfaceIndex $Adapter.ifIndex -DestinationPrefix "0.0.0.0/0" -Confirm:$false -ErrorAction SilentlyContinue
            Get-NetIPAddress -InterfaceIndex $Adapter.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
                Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

            $ipParams = @{
                InterfaceIndex = $Adapter.ifIndex
                IPAddress      = $finalIp
                PrefixLength   = $finalPrefix
            }
            if (-not [string]::IsNullOrEmpty($finalGw)) {
                $ipParams['DefaultGateway'] = $finalGw
            }
            New-NetIPAddress @ipParams | Out-Null
            Write-Host " [+] Da thiet lap IPv4: $finalIp/$finalPrefix | Gateway: $finalGw" -ForegroundColor Green
        }

        # Cap nhat DNS neu co thay doi
        if ($dnsChanged) {
            Set-DnsClientServerAddress -InterfaceIndex $Adapter.ifIndex -ServerAddresses $finalDns
            Write-Host " [+] Da cap nhat DNS Server: $($finalDns -join ', ')" -ForegroundColor Green
        }

        Write-Host "[*] Dang khoi dong lai Card mang ($($Adapter.Name)) de dong bo cau hinh..." -ForegroundColor Yellow
        Restart-NetAdapter -Name $Adapter.Name -Confirm:$false
        Clear-DnsClientCache

        Write-Host ""
        Write-Host "[OK] CAU HINH MANG THANH CONG!" -ForegroundColor Green
    }
    catch {
        Write-Host ""
        Write-Host "[ERROR] Loi khi ap dung cau hinh tinh: $_" -ForegroundColor Red
        Write-Host "Luu y: Kiem tra lai Gateway co nam cung lop mang (Subnet) voi IP tinh hay khong." -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------------------------
# [FLAG: FUNC_TOGGLE_IPV6] - Chuc nang 3: Enable hoac Disable giao thuc IPv6 tren Card mang
# ------------------------------------------------------------------------------
function Set-AdapterIPv6State {
    param ($Adapter)
    $current = Get-AdapterCurrentDetails -InterfaceIndex $Adapter.ifIndex -AdapterName $Adapter.Name
    $stateStr = if ($current.IPv6Enabled) { "DANG BAT (Enabled)" } else { "DANG TAT (Disabled)" }

    Write-Host ""
    Write-Host "[*] Trang thai IPv6 hien tai tren '$($Adapter.Name)': $stateStr" -ForegroundColor Cyan
    Write-Host " [1] Bat IPv6 (Enable)" -ForegroundColor Green
    Write-Host " [2] Tat IPv6 (Disable)" -ForegroundColor Yellow
    Write-Host " [0] Quay lai" -ForegroundColor Gray
    Write-Host ""

    $subChoice = (Read-Host "Chon thao tac IPv6 (0 - 2)").Trim()
    try {
        if ($subChoice -eq '1') {
            Enable-NetAdapterBinding -Name $Adapter.Name -ComponentID ms_tcpip6
            Write-Host "[*] Dang khoi dong lai Card mang..." -ForegroundColor Yellow
            Restart-NetAdapter -Name $Adapter.Name -Confirm:$false
            Write-Host "[OK] Da BAT (Enable) IPv6 thanh cong!" -ForegroundColor Green
        }
        elseif ($subChoice -eq '2') {
            Disable-NetAdapterBinding -Name $Adapter.Name -ComponentID ms_tcpip6
            Write-Host "[*] Dang khoi dong lai Card mang..." -ForegroundColor Yellow
            Restart-NetAdapter -Name $Adapter.Name -Confirm:$false
            Write-Host "[OK] Da TAT (Disable) IPv6 thanh cong!" -ForegroundColor Green
        }
    }
    catch {
        Write-Host "[ERROR] Loi khi thay doi trang thai IPv6: $_" -ForegroundColor Red
    }
}

# ------------------------------------------------------------------------------
# [FLAG: MAIN_CONTROLLER] - Vong lap dieu khien chinh cua chuong trinh
# ------------------------------------------------------------------------------
while ($true) {
    $selectedAdapter = Select-NetworkAdapter
    if ($null -eq $selectedAdapter) {
        Write-Host ""
        Write-Host "[*] Da thoat chuong trinh." -ForegroundColor Cyan
        break
    }

    while ($true) {
        Show-Banner
        $details = Get-AdapterCurrentDetails -InterfaceIndex $selectedAdapter.ifIndex -AdapterName $selectedAdapter.Name
        $dnsDisplay = if ($details.DnsList.Count -gt 0) { $details.DnsList -join ", " } else { "Auto / Empty" }
        $ipv6Display = if ($details.IPv6Enabled) { "Bat (Enabled)" } else { "Tat (Disabled)" }

        Write-Host "CARD MANG DANG CHON: $($selectedAdapter.Name) ($($selectedAdapter.InterfaceDescription))" -ForegroundColor Green
        Write-Host "-----------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " - Che do IP       : $($details.DhcpMode)" -ForegroundColor Gray
        Write-Host " - IPv4 / Subnet   : $($details.IPAddress) / $($details.SubnetMask) (/$($details.Prefix))" -ForegroundColor Gray
        Write-Host " - Default Gateway : $(if ($details.Gateway) { $details.Gateway } else { 'Empty' })" -ForegroundColor Gray
        Write-Host " - DNS Server      : $dnsDisplay" -ForegroundColor Gray
        Write-Host " - Trang thai IPv6 : $ipv6Display" -ForegroundColor Gray
        Write-Host "-----------------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "CHON CHUC NANG CAU HINH:" -ForegroundColor Yellow
        Write-Host " [1] Set IP dong (DHCP & DNS tu dong)" -ForegroundColor White
        Write-Host " [2] Set IP tinh (IP, Subnet Mask, Gateway, DNS - Nhan Enter de bo qua)" -ForegroundColor White
        Write-Host " [3] Bat / Tat IPv6 (Enable / Disable IPv6)" -ForegroundColor White
        Write-Host " [4] Chon lai Card mang khac" -ForegroundColor Cyan
        Write-Host " [0] Thoat chuong trinh" -ForegroundColor DarkYellow
        Write-Host ""

        $menuChoice = (Read-Host "Nhap lua chon cua ban (0 - 4)").Trim()

        switch ($menuChoice) {
            '1' {
                Set-AdapterDHCP -Adapter $selectedAdapter
                Write-Host ""
                Read-Host "Nhan Enter de tiep tuc..." | Out-Null
            }
            '2' {
                Set-AdapterStaticConfig -Adapter $selectedAdapter
                Write-Host ""
                Read-Host "Nhan Enter de tiep tuc..." | Out-Null
            }
            '3' {
                Set-AdapterIPv6State -Adapter $selectedAdapter
                Write-Host ""
                Read-Host "Nhan Enter de tiep tuc..." | Out-Null
            }
            '4' {
                break
            }
            '0' {
                Write-Host ""
                Write-Host "[*] Da thoat chuong trinh." -ForegroundColor Cyan
                exit 0
            }
            default {
                Write-Host "[!] Lua chon khong hop le!" -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }

        if ($menuChoice -eq '4') { break }
    }
}