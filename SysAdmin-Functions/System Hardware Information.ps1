# Module File: SysAdmin-Functions/System Hardware Information.ps1
# Description: Fetches detailed CPU, RAM, Disk, VGA, and Network/Wi-Fi specifications

Clear-Host
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "               SYSTEM HARDWARE INFORMATION              " -ForegroundColor Cyan
Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[+] Fetching hardware specifications, please wait..." -ForegroundColor Yellow

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
Write-Host ""
Write-Host "====================================================" -ForegroundColor DarkGray
Write-Host " 1. SYSTEM MODEL & SERIAL NUMBER" -ForegroundColor Yellow
Write-Host "  - Manufacturer   : $($computerSystem.Manufacturer)" -ForegroundColor White
Write-Host "  - Model Name     : $($computerSystem.Model)" -ForegroundColor White
Write-Host "  - Serial Number  : $($bios.SerialNumber)" -ForegroundColor White

Write-Host ""
Write-Host " 2. PROCESSOR (CPU)" -ForegroundColor Yellow
Write-Host "  - CPU Model      : $cpuName" -ForegroundColor White
Write-Host "  - Cores / Threads: $cpuCores Cores / $cpuThreads Threads" -ForegroundColor White
Write-Host "  - Base Clock     : $cpuMaxGhz GHz" -ForegroundColor White

Write-Host ""
Write-Host " 3. SYSTEM MEMORY (RAM)" -ForegroundColor Yellow
Write-Host "  - Capacity       : $ramTotalGB GB" -ForegroundColor White

Write-Host ""
Write-Host " 4. STORAGE DISKS" -ForegroundColor Yellow
foreach ($disk in $disks) {
    $diskSizeGB = [math]::Round($disk.Size / 1GB, 2)
    Write-Host "  - Disk Model     : $($disk.Model) ($diskSizeGB GB)" -ForegroundColor White
}

Write-Host ""
Write-Host " 5. GRAPHICS CARDS (VGA)" -ForegroundColor Yellow
foreach ($gpu in $gpus) {
    Write-Host "  - GPU Model      : $($gpu.Name)" -ForegroundColor White
}

Write-Host ""
Write-Host " 6. NETWORK ADAPTERS & WI-FI SUPPORTS" -ForegroundColor Yellow
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