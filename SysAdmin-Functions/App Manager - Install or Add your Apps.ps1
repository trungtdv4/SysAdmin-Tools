# Module: Install your App.ps1
# Description: Dynamic WinGet Local Package Installer with Auto-Appending Agreements
# Author     : Designed by Trung Nguyen IT. All Rights Reserved.

if ($global:WorkingDir) { Set-Location $global:WorkingDir }

# Determine local WinGet definitions directory
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

# Ensure directory exists
if (-not (Test-Path $wingetDir)) {
    New-Item -Path $wingetDir -ItemType Directory | Out-Null
}

# ------------------------------------------------------------------------------
# HELPER FUNCTION: ONLINE SEARCH & INSTALL (OPTION Z)
# ------------------------------------------------------------------------------
function Invoke-WinGetOnlineSearch {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "     WINGET ONLINE REPOSITORY SEARCH & INSTALL      " -ForegroundColor Cyan
    Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor DarkGray
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""

    $query = Read-Host "Enter software name to search online (or ENTER to cancel)"
    if ([string]::IsNullOrWhiteSpace($query)) { return }

    Write-Host ""
    Write-Host "[+] Searching WinGet Online Repository for '$query'..." -ForegroundColor Yellow

    $searchRaw = winget search $query --accept-source-agreements 2>$null
    $results = @()
    $startParsing = $false

    foreach ($line in $searchRaw) {
        if ($line -match '^-+') {
            $startParsing = $true
            continue
        }
        if ($startParsing -and -not [string]::IsNullOrWhiteSpace($line)) {
            $parts = $line -split '\s{2,}'
            if ($parts.Count -ge 2) {
                $results += [PSCustomObject]@{
                    Name = $parts[0].Trim()
                    Id   = $parts[1].Trim()
                }
            }
        }
    }

    if (-not $results -or $results.Count -eq 0) {
        Write-Host "[!] No software matching '$query' found on WinGet Repository." -ForegroundColor Red
        Write-Host ""
        Write-Host "Press ENTER to return..." -ForegroundColor Gray
        Read-Host | Out-Null
        return
    }

    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "SEARCH RESULTS FOR: '$query'" -ForegroundColor Yellow
    Write-Host "====================================================" -ForegroundColor Cyan

    $maxCount = [math]::Min($results.Count, 15)
    for ($i = 0; $i -lt $maxCount; $i++) {
        Write-Host "  $($i + 1). $($results[$i].Name) " -NoNewline -ForegroundColor White
        Write-Host "[$($results[$i].Id)]" -ForegroundColor Gray
    }
    Write-Host "  0. Back to Local Menu" -ForegroundColor Gray
    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host "Tips: Enter numbers separated by commas to install multiple (e.g., 1,3)" -ForegroundColor Gray
    Write-Host ""

    $selectionInput = Read-Host "Select application number(s) to install"
    if ($selectionInput.Trim() -eq '0' -or [string]::IsNullOrWhiteSpace($selectionInput)) { return }

    $selectedIndices = $selectionInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }

    foreach ($indexStr in $selectedIndices) {
        $index = [int]$indexStr
        if ($index -gt 0 -and $index -le $maxCount) {
            $app = $results[$index - 1]
            $appName = $app.Name
            $appId   = $app.Id

            Write-Host ""
            Write-Host "====================================================" -ForegroundColor Cyan
            Write-Host ">>> Processing Package: $appName [$appId] <<<" -ForegroundColor Cyan
            Write-Host "====================================================" -ForegroundColor Cyan

            # Pre-check if installed
            Write-Host "[+] Checking if '$appName' is already installed..." -ForegroundColor Yellow
            $checkResult = winget list --id $appId --accept-source-agreements 2>$null

            if ($checkResult -match $appId) {
                Write-Host "[!] WARNING: '$appName' is ALREADY INSTALLED on this system!" -ForegroundColor Yellow
                Write-Host "    Skipping installation." -ForegroundColor DarkGray
            } else {
                Write-Host "[+] Executing WinGet online installation..." -ForegroundColor Green
                $cmd = "winget install --id $appId -e --silent --accept-package-agreements --accept-source-agreements"
                Write-Host "    Command: $cmd" -ForegroundColor Gray
                
                Invoke-Expression $cmd
                Write-Host "[V] Finished installation task for: $appName" -ForegroundColor Green
            }
        } else {
            Write-Host "[!] Index '$indexStr' out of range. Skipped." -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Press ENTER to return..." -ForegroundColor Gray
    Read-Host | Out-Null
}

# ------------------------------------------------------------------------------
# MAIN LOCAL MENU LOOP
# ------------------------------------------------------------------------------
while ($true) {
    $packageFiles = Get-ChildItem -Path $wingetDir -Filter "*.txt" -ErrorAction SilentlyContinue | Sort-Object Name

    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host "AVAILABLE LOCAL SOFTWARE PACKAGES:" -ForegroundColor Yellow

    if ($packageFiles -and $packageFiles.Count -gt 0) {
        for ($i = 0; $i -lt $packageFiles.Count; $i++) {
            Write-Host "  $($i + 1). $($packageFiles[$i].BaseName)" -ForegroundColor White
        }
    } else {
        Write-Host "  (No local .txt package definitions found)" -ForegroundColor DarkGray
    }

    Write-Host "  Z. Other? (Search online repository)" -ForegroundColor Green
    Write-Host "  0. Return to Main Menu" -ForegroundColor Gray
    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Tips: Enter numbers separated by commas to install multiple apps (e.g., 1,3)" -ForegroundColor Gray
    $selectionInput = Read-Host "Select an option or application number(s)"

    # Handle Exit
    if ($selectionInput.Trim() -eq '0') {
        break
    }

    # Handle Option Z (Search Online)
    if ($selectionInput.Trim() -eq 'Z' -or $selectionInput.Trim() -eq 'z') {
        Invoke-WinGetOnlineSearch
        Clear-Host
        Write-Host "====================================================" -ForegroundColor Cyan
        Write-Host "       WINGET BATCH & SMART APP INSTALLER           " -ForegroundColor Cyan
        Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor DarkGray
        Write-Host "====================================================" -ForegroundColor Cyan
        Write-Host ""
        continue
    }

    # Handle Local Selections
    $selectedIndices = $selectionInput -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }

    if (-not $selectedIndices -or $selectedIndices.Count -eq 0) {
        Write-Host "[!] Invalid selection. Please try again!" -ForegroundColor Red
        Start-Sleep -Seconds 1
        Clear-Host
        continue
    }

    foreach ($indexStr in $selectedIndices) {
        $index = [int]$indexStr
        if ($packageFiles -and $index -gt 0 -and $index -le $packageFiles.Count) {
            $selectedPackage = $packageFiles[$index - 1]
            $appName = $selectedPackage.BaseName
            $cmdString = (Get-Content -Path $selectedPackage.FullName -Raw).Trim()

            if ([string]::IsNullOrWhiteSpace($cmdString)) {
                Write-Host "[!] Error: File '$($selectedPackage.Name)' is empty!" -ForegroundColor Red
                continue
            }

            # AUTO-APPEND MISSING AGREEMENTS PARAMETERS
            if ($cmdString -notmatch '--accept-package-agreements') {
                $cmdString += " --accept-package-agreements"
            }
            if ($cmdString -notmatch '--accept-source-agreements') {
                $cmdString += " --accept-source-agreements"
            }

            Write-Host ""
            Write-Host "====================================================" -ForegroundColor Cyan
            Write-Host ">>> Processing Local Package [$index]: $appName <<<" -ForegroundColor Cyan
            Write-Host "====================================================" -ForegroundColor Cyan

            # Extract App ID from string
            $appId = ""
            if ($cmdString -match '--id\s+([^\s]+)') {
                $appId = $matches[1]
            }

            $isInstalled = $false
            if (-not [string]::IsNullOrWhiteSpace($appId)) {
                Write-Host "[+] Checking if '$appName' (ID: $appId) is installed..." -ForegroundColor Yellow
                $checkResult = winget list --id $appId --accept-source-agreements 2>$null
                if ($checkResult -match $appId) {
                    $isInstalled = $true
                }
            }

            if ($isInstalled) {
                Write-Host "[!] WARNING: '$appName' is ALREADY INSTALLED on this system!" -ForegroundColor Yellow
                Write-Host "    Skipping installation." -ForegroundColor DarkGray
            } else {
                Write-Host "[+] App not found. Executing installation command..." -ForegroundColor Green
                Write-Host "    Command: $cmdString" -ForegroundColor Gray
                Write-Host ""

                Invoke-Expression $cmdString
                Write-Host ""
                Write-Host "[V] Finished installation task for: $appName" -ForegroundColor Green
            }
        } else {
            Write-Host "[!] Option '$indexStr' is out of range. Skipped." -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "[V] All selected local tasks completed!" -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Press ENTER to return..." -ForegroundColor Gray
    Read-Host | Out-Null

    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "       WINGET BATCH & SMART APP INSTALLER           " -ForegroundColor Cyan
    Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor DarkGray
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
}