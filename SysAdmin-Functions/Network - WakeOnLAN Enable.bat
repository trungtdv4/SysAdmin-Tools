<# :
@cls
@echo off
title Kich hoat Wake-on-LAN (WoL) - Windows

:: Kiem tra va yeu cau quyen Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Copy file bat hien tai thanh file ps1 vao thu muc Temp de PowerShell doc nguyen ban 100%
set "ps1_temp=%temp%\wol_config_%random%.ps1"
copy /y "%~f0" "%ps1_temp%" >nul

:: Thuc thi file bang bo doc mac dinh cua PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps1_temp%"

:: Don dep file tam sau khi chay xong
del "%ps1_temp%" >nul 2>&1
pause
exit /b
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   DANG CAU HINH CAC TINH NANG WAKE-ON-LAN (WoL)..." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Tat Fast Startup (Windows Fast Boot)
try {
    Write-Host "[1/4] Dang tat Fast Startup (Khoi dong nhanh)... " -NoNewline
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power" -Name "HiberbootEnabled" -Value 0 -ErrorAction Stop
    Write-Host "[Thanh cong]" -ForegroundColor Green
} catch {
    Write-Host "[That bai]" -ForegroundColor Red
}

# 2. Mo Port Wake-on-LAN tren Windows Firewall (UDP 7 & 9)
try {
    Write-Host "[2/4] Dang cau hinh Windows Firewall (Cong UDP 7, 9)... " -NoNewline
    $ruleName = "Wake-On-LAN (UDP-In)"
    if (Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue) {
        Remove-NetFirewallRule -DisplayName $ruleName
    }
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -Protocol UDP -LocalPort 7,9 -Action Allow | Out-Null
    Write-Host "[Thanh cong]" -ForegroundColor Green
} catch {
    Write-Host "[That bai]" -ForegroundColor Red
}

# 3. Cau hinh Thuoc tinh Nang cao tren Card Mang (Advanced Adapter Settings)
Write-Host "[3/4] Dang cau hinh cai dat nang cao tren Card mang..." -ForegroundColor Yellow

$physicalAdapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" }
if (-not $physicalAdapters) {
    $physicalAdapters = Get-NetAdapter -Physical
}

foreach ($adapter in $physicalAdapters) {
    Write-Host "   -> Dang xu ly Card mang: $($adapter.Name) ($($adapter.InterfaceDescription))" -ForegroundColor Cyan
    
    # Bat Magic Packet
    try {
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "*Wake on Magic Packet*" -DisplayValue "Enabled" -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -RegistryKeyword "*WakeOnMagicPacket" -RegistryValue "1" -ErrorAction SilentlyContinue
    } catch {}

    # Bat Wake on Pattern Match
    try {
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "*Wake on Pattern Match*" -DisplayValue "Enabled" -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -RegistryKeyword "*WakeOnPattern" -RegistryValue "1" -ErrorAction SilentlyContinue
    } catch {}

    # Tat Energy Efficient Ethernet / Green Ethernet
    try {
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -DisplayName "*Energy Efficient Ethernet*" -DisplayValue "Disabled" -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $adapter.Name -RegistryKeyword "*EEE" -RegistryValue "0" -ErrorAction SilentlyContinue
    } catch {}
}

# 4. Cau hinh Power Management (Quan ly nguon dien qua WMI)
Write-Host "[4/4] Dang cau hinh Quan ly Nguon dien (Power Management)..." -ForegroundColor Yellow

try {
    $nics = Get-WmiObject -Class Win32_NetworkAdapter | Where-Object { $_.PNPDeviceID -ne $null -and $_.PhysicalAdapter -eq $true }
    foreach ($nic in $nics) {
        $nicPower = Get-WmiObject -Query "SELECT * FROM MSPower_DeviceEnableWakeUp WHERE InstanceName LIKE '%$($nic.PNPDeviceID)%'" -Namespace "root\wmi" -ErrorAction SilentlyContinue
        if ($nicPower) {
            $nicPower.EnableWakeUp = $true
            $null = $nicPower.Put()
        }

        $nicMagic = Get-WmiObject -Query "SELECT * FROM MSPower_DeviceWakeUpEnableMagicPacketOnly WHERE InstanceName LIKE '%$($nic.PNPDeviceID)%'" -Namespace "root\wmi" -ErrorAction SilentlyContinue
        if ($nicMagic) {
            $nicMagic.EnableWakeUpMagicPacketOnly = $true
            $null = $nicMagic.Put()
        }
    }
    Write-Host "   -> Cau hinh Power Management hoan tat." -ForegroundColor Green
} catch {
    Write-Host "   -> Khong the ghi nhan thong so WMI Power Management." -ForegroundColor Red
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "   HOAN TAT CAU HINH WAKE-ON-LAN TREN WINDOWS!" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "LUU Y: Vui long dam bao ban da bat cac tuy chon WoL trong BIOS/UEFI:" -ForegroundColor Yellow
Write-Host " - Enable ""Wake on LAN"" / ""Resume by PCI-E Device"" / ""Power On By PCIE""."
Write-Host " - Disable ""ErP/EuP Ready"" hoac ""Deep Sleep""."
Write-Host ""