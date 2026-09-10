# Module: Adjust Date & Time Vietnamese.ps1
# Description: Set SE Asia Standard Time, sync Windows Time Service, and set dd/MM/yyyy date format
# Author     : Designed by Trung Nguyen IT. All Rights Reserved.

Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "      ADJUST DATE & TIME VIETNAMESE (GMT+7)        " -ForegroundColor Cyan
Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor DarkGray
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# ------------------------------------------------------------------------------
# 1. SET TIMEZONE TO VIETNAM (SE ASIA STANDARD TIME - GMT+7)
# ------------------------------------------------------------------------------
Write-Host "[1/3] Setting Time Zone to (UTC+07:00) Bangkok, Hanoi, Jakarta..." -ForegroundColor Yellow

try {
    Set-TimeZone -Id "SE Asia Standard Time" -ErrorAction Stop
    $currentTimeZone = (Get-TimeZone).DisplayName
    Write-Host "  [V] Time Zone successfully set to: $currentTimeZone" -ForegroundColor Green
} catch {
    Write-Host "  [!] Failed to set Time Zone: $_" -ForegroundColor Red
}

Write-Host ""

# ------------------------------------------------------------------------------
# 2. FORCE RESYNC SYSTEM TIME WITH NETWORK TIME PROTOCOL (NTP)
# ------------------------------------------------------------------------------
Write-Host "[2/3] Synchronizing system clock with Time Server..." -ForegroundColor Yellow

try {
    # Ensure Windows Time service (w32time) is running
    $timeService = Get-Service -Name "w32time" -ErrorAction SilentlyContinue
    if ($timeService.Status -ne "Running") {
        Start-Service -Name "w32time" -ErrorAction SilentlyContinue
    }

    # Resync system clock
    $resyncResult = w32tm /resync /force 2>&1
    if ($LASTEXITCODE -eq 0 -or $resyncResult -match "successfully") {
        Write-Host "  [V] System time synchronized successfully!" -ForegroundColor Green
        Write-Host "      Current Local Time: $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')" -ForegroundColor White
    } else {
        Write-Host "  [!] Resync notice: $resyncResult" -ForegroundColor Yellow
    }
} catch {
    Write-Host "  [!] Error triggering time resync: $_" -ForegroundColor Red
}

Write-Host ""

# ------------------------------------------------------------------------------
# 3. SET DATE FORMAT TO VIETNAMESE STANDARD (dd/MM/yyyy)
# ------------------------------------------------------------------------------
Write-Host "[3/3] Setting Short Date Format to 'dd/MM/yyyy'..." -ForegroundColor Yellow

try {
    # Update Current User Registry Regional Settings
    $regPath = "HKCU:\Control Panel\International"
    Set-ItemProperty -Path $regPath -Name "sShortDate" -Value "dd/MM/yyyy" -ErrorAction Stop
    Set-ItemProperty -Path $regPath -Name "sDate" -Value "/" -ErrorAction Stop

    Write-Host "  [V] Registry updated! Short Date format set to: dd/MM/yyyy" -ForegroundColor Green
    Write-Host "      Note: Some open applications may require a restart to reflect the new date format." -ForegroundColor DarkGray
} catch {
    Write-Host "  [!] Failed to update Regional Date format in Registry: $_" -ForegroundColor Red
}

Write-Host ""
Write-Host "====================================================" -ForegroundColor Green
Write-Host "[V] Date & Time adjustment process completed!" -ForegroundColor Green
Write-Host "====================================================" -ForegroundColor Green
Write-Host ""

Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
Read-Host | Out-Null