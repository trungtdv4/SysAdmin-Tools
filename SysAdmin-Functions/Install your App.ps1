# Module: Install your App.ps1
# Description: Multi-Select Batch Installer via WinGet with Pre-Installation Check
# Author     : Designed by Trung Nguyen IT. All Rights Reserved.

# Set location context
if ($global:WorkingDir) { Set-Location $global:WorkingDir }

# Determine WinGet packages directory
$wingetDir = Join-Path $PSScriptRoot "WinGet"
if (-not (Test-Path $wingetDir)) {
    $wingetDir = Join-Path $env:LOCALAPPDATA "SysAdmin-Tools-App\SysAdmin-Functions\WinGet"
}

Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "       WINGET BATCH & SMART APP INSTALLER           " -ForegroundColor Cyan
Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor DarkGray
Write-Host "====================================================" -ForegroundColor Cyan
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

# Check directory existence
if (-not (Test-Path $wingetDir)) {
    New-Item -Path $wingetDir -ItemType Directory | Out-Null
    Write-Host "[!] Notice: Created empty WinGet definitions folder at:" -ForegroundColor Yellow
    Write-Host "    $wingetDir" -ForegroundColor White
    Write-Host ""
    Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
    Read-Host | Out-Null
    return
}

while ($true) {
    # Scan all .txt package definitions
    $packageFiles = Get-ChildItem -Path $wingetDir -Filter "*.txt" -ErrorAction SilentlyContinue | Sort-Object Name

    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host "AVAILABLE SOFTWARE PACKAGES:" -ForegroundColor Yellow

    if (-not $packageFiles -or $packageFiles.Count -eq 0) {
        Write-Host "[!] No package definitions (.txt) found in WinGet folder." -ForegroundColor Red
        Write-Host "  0. Return to Main Menu" -ForegroundColor Gray
    } else {
        for ($i = 0; $i -lt $packageFiles.Count; $i++) {
            Write-Host "  $($i + 1). $($packageFiles[$i].BaseName)" -ForegroundColor White
        }
        Write-Host "  0. Return to Main Menu" -ForegroundColor Gray
    }

    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Tips: Enter numbers separated by commas to install multiple apps (e.g., 1,3,4)" -ForegroundColor Gray
    $selectionInput = Read-Host "Select application number(s)"

    if ($selectionInput.Trim() -eq '0') {
        break
    }

    # Split input by commas and clean up spaces
    $selectedIndices = $selectionInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }

    if (-not $selectedIndices -or $selectedIndices.Count -eq 0) {
        Write-Host "[!] Invalid selection format. Please try again!" -ForegroundColor Red
        Start-Sleep -Seconds 1
        Clear-Host
        continue
    }

    foreach ($indexStr in $selectedIndices) {
        $index = [int]$indexStr
        if ($index -gt 0 -and $index -le $packageFiles.Count) {
            $selectedPackage = $packageFiles[$index - 1]
            $appName = $selectedPackage.BaseName
            $cmdString = (Get-Content -Path $selectedPackage.FullName -Raw).Trim()

            if ([string]::IsNullOrWhiteSpace($cmdString)) {
                Write-Host "[!] Error: File '$($selectedPackage.Name)' is empty!" -ForegroundColor Red
                continue
            }

            Write-Host ""
            Write-Host "====================================================" -ForegroundColor Cyan
            Write-Host ">>> Processing Package [$index]: $appName <<<" -ForegroundColor Cyan
            Write-Host "====================================================" -ForegroundColor Cyan

            # Extract App ID from the winget command string
            $appId = ""
            if ($cmdString -match '--id\s+([^\s]+)') {
                $appId = $matches[1]
            }

            # Pre-check if application is already installed on target machine
            $isInstalled = $false
            if (-not [string]::IsNullOrEmpty($appId)) {
                Write-Host "[+] Checking if '$appName' (ID: $appId) is already installed..." -ForegroundColor Yellow
                $checkResult = winget list --id $appId --accept-source-agreements 2>$null
                
                if ($checkResult -match $appId) {
                    $isInstalled = $true
                }
            }

            if ($isInstalled) {
                Write-Host "[!] WARNING: '$appName' is ALREADY INSTALLED on this system!" -ForegroundColor Yellow
                Write-Host "    Skipping installation process for this package." -ForegroundColor DarkGray
            } else {
                Write-Host "[+] App not found. Executing installation command..." -ForegroundColor Green
                Write-Host "    Command: $cmdString" -ForegroundColor Gray
                Write-Host ""

                # Execute installation command
                Invoke-Expression $cmdString

                Write-Host ""
                Write-Host "[V] Installation process finished for: $appName" -ForegroundColor Green
            }
        } else {
            Write-Host "[!] Option '$indexStr' is out of range. Skipped." -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "[V] All selected tasks completed!" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press ENTER to return to application menu..." -ForegroundColor Gray
    Read-Host | Out-Null

    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "       WINGET BATCH & SMART APP INSTALLER           " -ForegroundColor Cyan
    Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor DarkGray
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
}