# Module File: SysAdmin-Functions/System Hardware Information.ps1
# Description: Fetches detailed CPU, RAM, Disk, VGA, and Network/Wi-Fi specifications

Clear-Host
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host "                                      SYSTEM HARDWARE INFORMATION                                       " -ForegroundColor Cyan
Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[+] Fetching hardware specifications, please wait..." -ForegroundColor Yellow

# ------------------------------------------------------------------------------
# [FLAG: DETECT_OS_INFO] - Phat hien He dieu hanh, Ban Build & Kien truc Chip
# ------------------------------------------------------------------------------
function Get-OSDetailedInformation {
    Write-Host " 1. Detecting Operating System Details..." -ForegroundColor Yellow
    
    try {
        $os = Get-CimInstance -ClassName Win32_OperatingSystem -ErrorAction Stop
        
        # 1. Lay ten He dieu hanh
        $osName = $os.Caption.Replace("Microsoft ", "").Trim()
        
        # 2. Lay Kien truc OS (x64 / x86 / ARM64)
        $osArch = $os.OSArchitecture
        if ([string]::IsNullOrWhiteSpace($osArch)) {
            $osArch = $env:PROCESSOR_ARCHITECTURE
        }

        # 3. Tra cuu Ban Build va DisplayVersion (e.g. 22H2, 23H2, 24H2, 26H2)
        $buildNumber = $os.BuildNumber
        $displayVersion = "N/A"
        
        $regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        if (Test-Path $regPath) {
            $regProps = Get-ItemProperty -Path $regPath -ErrorAction SilentlyContinue
            if ($regProps.DisplayVersion) {
                $displayVersion = $regProps.DisplayVersion
            } elseif ($regProps.ReleaseId) {
                $displayVersion = $regProps.ReleaseId
            }
        }

        # Format chuoi hien thi
        Write-Host "  - Operating System : $osName" -ForegroundColor White
        Write-Host "  - Version / Build  : $displayVersion (Build $buildNumber)" -ForegroundColor White
        Write-Host "  - Architecture     : $osArch" -ForegroundColor White
    } catch {
        Write-Host "  [!] Unable to retrieve OS Information: $_" -ForegroundColor Red
    }
}

# Model & Serial
$computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem
$bios = Get-CimInstance -ClassName Win32_BIOS

# CPU Details
$cpu = Get-CimInstance -ClassName Win32_Processor
$cpuName = $cpu.Name.Trim()
$cpuCores = $cpu.NumberOfCores
$cpuThreads = $cpu.NumberOfLogicalProcessors
$cpuMaxGhz = [math]::Round($cpu.MaxClockSpeed / 1000, 2)

# RAM
$ramTotalBytes = (Get-CimInstance -ClassName Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum
$ramTotalGB = [math]::Round($ramTotalBytes / 1GB, 2)

# Storage
$disks = Get-CimInstance -ClassName Win32_DiskDrive

# VGA
$gpus = Get-CimInstance -ClassName Win32_VideoController

# Network
$netAdapters = Get-NetAdapter -ErrorAction SilentlyContinue | Where-Object { $_.Status -eq "Up" -or $_.PhysicalMediaType -match "802.11|Native 802.11|Ethernet" }
$wifiInterfaces = netsh wlan show interfaces 2>$null

# Display Output

Write-Host "====================================================" -ForegroundColor DarkGray

# Goi ham lay thong tin OS
Get-OSDetailedInformation

Write-Host ""
Write-Host " 2. SYSTEM MODEL & SERIAL NUMBER" -ForegroundColor Yellow
Write-Host "  - Manufacturer   : $($computerSystem.Manufacturer)" -ForegroundColor White
Write-Host "  - Model Name     : $($computerSystem.Model)" -ForegroundColor White
Write-Host "  - Serial Number  : $($bios.SerialNumber)" -ForegroundColor White

Write-Host ""
Write-Host " 3. PROCESSOR (CPU)" -ForegroundColor Yellow
Write-Host "  - CPU Model      : $cpuName" -ForegroundColor White
Write-Host "  - Cores / Threads: $cpuCores Cores / $cpuThreads Threads" -ForegroundColor White
Write-Host "  - Base Clock     : $cpuMaxGhz GHz" -ForegroundColor White

Write-Host ""
Write-Host " 4. SYSTEM MEMORY (RAM)" -ForegroundColor Yellow
Write-Host "  - Capacity       : $ramTotalGB GB" -ForegroundColor White

Write-Host ""
Write-Host " 5. STORAGE DISKS" -ForegroundColor Yellow
foreach ($disk in $disks) {
    $diskSizeGB = [math]::Round($disk.Size / 1GB, 2)
    Write-Host "  - Disk Model     : $($disk.Model) ($diskSizeGB GB)" -ForegroundColor White
}

Write-Host ""
Write-Host " 6. GRAPHICS CARDS (VGA)" -ForegroundColor Yellow
foreach ($gpu in $gpus) {
    Write-Host "  - GPU Model      : $($gpu.Name)" -ForegroundColor White
}

Write-Host ""
Write-Host " 7. NETWORK ADAPTERS & WI-FI SUPPORTS" -ForegroundColor Yellow
foreach ($net in $netAdapters) {
    Write-Host "  - Adapter Name   : $($net.InterfaceDescription)" -ForegroundColor White
    Write-Host "    Link Speed     : $($net.LinkSpeed)" -ForegroundColor Gray
}

if ($wifiInterfaces -match "Radio types supported|Các loại đài phát được hỗ trợ") {
    $wifiTypes = ($wifiInterfaces | Select-String -Pattern "Radio types supported|Các loại đài phát được hỗ trợ").Line.Split(":")[-1].Trim()
    Write-Host "  - Wi-Fi Standards : $wifiTypes" -ForegroundColor Green
}
Write-Host "====================================================" -ForegroundColor DarkGray

Write-Host ""
Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
Read-Host | Out-Null