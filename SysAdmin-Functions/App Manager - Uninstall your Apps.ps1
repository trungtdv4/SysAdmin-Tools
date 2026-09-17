# Module: Uninstall Apps.ps1
# Description: Scan installed software via WinGet and support batch uninstallation
# Author     : Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.

if ($global:WorkingDir) { Set-Location $global:WorkingDir }

Clear-Host
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host "                                 WINGET BATCH APPLICATION UNINSTALLER                                   " -ForegroundColor Cyan
Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host ""

# Check WinGet availability
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[!] ERROR: WinGet utility is not detected on this system." -ForegroundColor Red
    Write-Host "    Please ensure App Installer is enabled/updated." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
    Read-Host | Out-Null
    return
}

while ($true) {
    Write-Host "[+] Scanning system for installed applications via WinGet, please wait..." -ForegroundColor Yellow
    Write-Host ""

    # Fetch installed packages using winget list
    $listRaw = winget list --accept-source-agreements 2>$null
    $installedApps = @()
    $startParsing = $false

    foreach ($line in $listRaw) {
        if ($line -match '^-+') {
            $startParsing = $true
            continue
        }
        if ($startParsing -and -not [string]::IsNullOrWhiteSpace($line)) {
            # Filter out status lines or table borders
            $cleanLine = $line -replace '\[Unknown\]|\[msstore\]|\[winget\]', ''
            $parts = $cleanLine -split '\s{2,}' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

            if ($parts.Count -ge 2) {
                $appName = $parts[0].Trim()
                $appId   = $parts[1].Trim()

                # Filter out system components or invalid tokens
                if ($appId -match '^[A-Za-z0-9\.\-_]+$' -and $appId -notlike "*Component*") {
                    $installedApps += [PSCustomObject]@{
                        Name = $appName
                        Id   = $appId
                    }
                }
            }
        }
    }

    if (-not $installedApps -or $installedApps.Count -eq 0) {
        Write-Host "[!] No uninstallable applications detected via WinGet." -ForegroundColor Red
        Write-Host ""
        Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
        Read-Host | Out-Null
        return
    }

    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "INSTALLED APPLICATIONS DETECTED ($($installedApps.Count) Total):" -ForegroundColor Yellow
    Write-Host "====================================================" -ForegroundColor Cyan

    # Display top 25 apps per page for clean UI
    $maxCount = [math]::Min($installedApps.Count, 30)
    for ($i = 0; $i -lt $maxCount; $i++) {
        Write-Host "  $($i + 1). $($installedApps[$i].Name) " -NoNewline -ForegroundColor White
        Write-Host "[$($installedApps[$i].Id)]" -ForegroundColor Gray
    }
    Write-Host "  0. Return to Main Menu" -ForegroundColor Gray
    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Tips: Enter numbers separated by commas to uninstall multiple apps (e.g., 1,3,5)" -ForegroundColor Gray
    Write-Host ""

    $selectionInput = Read-Host "Select application number(s) to uninstall"

    if ($selectionInput.Trim() -eq '0' -or [string]::IsNullOrWhiteSpace($selectionInput)) {
        break
    }

    $selectedIndices = $selectionInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }

    if (-not $selectedIndices -or $selectedIndices.Count -eq 0) {
        Write-Host "[!] Invalid selection format. Please try again!" -ForegroundColor Red
        Start-Sleep -Seconds 1
        Clear-Host
        continue
    }

    foreach ($indexStr in $selectedIndices) {
        $index = [int]$indexStr
        if ($index -gt 0 -and $index -le $maxCount) {
            $targetApp = $installedApps[$index - 1]
            $appName   = $targetApp.Name
            $appId     = $targetApp.Id

            Write-Host ""
            Write-Host "====================================================" -ForegroundColor Red
            Write-Host ">>> Uninstalling Package [$index]: $appName [$appId] <<<" -ForegroundColor Red
            Write-Host "====================================================" -ForegroundColor Red
            Write-Host ""

            # Construct WinGet uninstall command
            $cmd = "winget uninstall --id `"$appId`" -e --silent --disable-interactivity --accept-source-agreements"
            Write-Host "    Executing Command: $cmd" -ForegroundColor Gray
            Write-Host ""

            Invoke-Expression $cmd

            # Sleep 2 seconds to release uninstaller locks
            Start-Sleep -Seconds 2

            Write-Host ""
            Write-Host "[V] Uninstallation process finished for: $appName" -ForegroundColor Green
        } else {
            Write-Host "[!] Index '$indexStr' out of range. Skipped." -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "[V] All selected uninstallation tasks completed!" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press ENTER to refresh list and return..." -ForegroundColor Gray
    Read-Host | Out-Null

    Clear-Host
}