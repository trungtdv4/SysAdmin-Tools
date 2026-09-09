# Module File: SysAdmin-Functions/Battery Health Report.ps1
# Description: Generates and opens HTML Battery Health Report via powercfg

Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "           LAPTOP BATTERY HEALTH REPORT             " -ForegroundColor Cyan
Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor DarkGray
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Check if physical battery exists
$battery = Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue
if (-not $battery) {
    Write-Host "[!] WARNING: No battery detected on this system (Desktop PC / VM)." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
    Read-Host | Out-Null
    return
}

$reportPath = Join-Path $env:TEMP "battery-report.html"
Write-Host "[+] Generating battery report using powercfg..." -ForegroundColor Yellow

$process = Start-Process -FilePath "powercfg.exe" -ArgumentList "/batteryreport /output `"$reportPath`"" -Wait -NoNewWindow -PassThru

if ($process.ExitCode -eq 0 -and (Test-Path $reportPath)) {
    Write-Host "[V] Battery report successfully generated!" -ForegroundColor Green
    Write-Host "    Location: $reportPath" -ForegroundColor White
    Write-Host ""
    Write-Host "[+] Opening report in default web browser..." -ForegroundColor Yellow
    
    Start-Process -FilePath $reportPath
} else {
    Write-Host "[!] Error: Failed to generate battery report." -ForegroundColor Red
}

Write-Host ""
Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
Read-Host | Out-Null