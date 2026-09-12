# Module: Install your App.ps1
# Description: Smart Package Installer (Fixed Store/Unknown App ID Parsing)
# Author     : Designed by trungtdv4@gmail.com. All Rights Reserved.

if ($global:WorkingDir) { Set-Location $global:WorkingDir }

$wingetDir = Join-Path $PSScriptRoot "WinGet"
if (-not (Test-Path $wingetDir)) {
    $wingetDir = Join-Path $env:LOCALAPPDATA "SysAdmin-Tools-App\SysAdmin-Functions\WinGet"
}

Clear-Host
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "           SMART PACKAGE & FEATURE INSTALLER            " -ForegroundColor Cyan
Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $wingetDir)) {
    New-Item -Path $wingetDir -ItemType Directory | Out-Null
}

# ------------------------------------------------------------------------------
# HELPER FUNCTION: ONLINE SEARCH & INSTALL (OPTION Z - FIXED PARSER)
# ------------------------------------------------------------------------------
function Invoke-WinGetOnlineSearch {
    Clear-Host
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "        WINGET ONLINE REPOSITORY SEARCH & INSTALL       " -ForegroundColor Cyan
    Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
    Write-Host "========================================================" -ForegroundColor Cyan
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
            # Clean up line by removing [Unknown] or other bracket tags
            $cleanLine = $line -replace '\[Unknown\]|\[msstore\]|\[winget\]', ''
            $parts = $cleanLine -split '\s{2,}' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

            if ($parts.Count -ge 2) {
                $rawId = $parts[1].Trim()
                # Ensure we capture only valid ID tokens
                if ($rawId -match '^[A-Za-z0-9\.\-_]+$') {
                    $results += [PSCustomObject]@{
                        Name = $parts[0].Trim()
                        Id   = $rawId
                    }
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

            Write-Host "[+] Checking if '$appName' is already installed..." -ForegroundColor Yellow
            $checkResult = winget list --id $appId --accept-source-agreements 2>$null

            if ($checkResult -match [regex]::Escape($appId)) {
                Write-Host "[!] WARNING: '$appName' is ALREADY INSTALLED on this system!" -ForegroundColor Yellow
                Write-Host "    Skipping installation." -ForegroundColor DarkGray
            } else {
                Write-Host "[+] Executing WinGet online installation..." -ForegroundColor Green
                $cmd = "winget install --id `"$appId`" -e --silent --disable-interactivity --accept-package-agreements --accept-source-agreements"
                Write-Host "    Command: $cmd" -ForegroundColor Gray
                
                Invoke-Expression $cmd
                Start-Sleep -Seconds 2
                
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
    Write-Host "AVAILABLE LOCAL PACKAGES & FEATURES:" -ForegroundColor Yellow

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
    Write-Host "Tips: Enter numbers separated by commas to install multiple items (e.g., 1,3)" -ForegroundColor Gray
    $selectionInput = Read-Host "Select an option or package number(s)"

    if ($selectionInput.Trim() -eq '0') { break }

    if ($selectionInput.Trim() -eq 'Z' -or $selectionInput.Trim() -eq 'z') {
        Invoke-WinGetOnlineSearch
        Clear-Host
        Write-Host "========================================================" -ForegroundColor Cyan
        Write-Host "           SMART PACKAGE & FEATURE INSTALLER            " -ForegroundColor Cyan
        Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
        Write-Host "========================================================" -ForegroundColor Cyan
        Write-Host ""
        continue
    }

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

            Write-Host ""
            Write-Host "====================================================" -ForegroundColor Cyan
            Write-Host ">>> Processing Item [$index]: $appName <<<" -ForegroundColor Cyan
            Write-Host "====================================================" -ForegroundColor Cyan

            # --- BRANCH 1: POWERSHELL FEATURE COMMANDS ---
            if ($cmdString -match 'Enable-WindowsOptionalFeature|DISM') {
                $featureName = ""
                if ($cmdString -match '-FeatureName\s+["'']?([^"''\s]+)["'']?') {
                    $featureName = $matches[1]
                }

                $isInstalled = $false
                if (-not [string]::IsNullOrWhiteSpace($featureName)) {
                    Write-Host "[+] Checking Windows Feature status for '$featureName'..." -ForegroundColor Yellow
                    $featureStatus = Get-WindowsOptionalFeature -Online -FeatureName $featureName -ErrorAction SilentlyContinue
                    if ($featureStatus -and $featureStatus.State -eq "Enabled") {
                        $isInstalled = $true
                    }
                }

                if ($isInstalled) {
                    Write-Host "[!] WARNING: Windows Feature '$featureName' is ALREADY ENABLED!" -ForegroundColor Yellow
                    Write-Host "    Skipping installation." -ForegroundColor DarkGray
                } else {
                    Write-Host "[+] Enabling Windows Feature..." -ForegroundColor Green
                    Write-Host "    Command: $cmdString" -ForegroundColor Gray
                    Write-Host ""
                    Invoke-Expression $cmdString
                    Write-Host ""
                    Write-Host "[V] Feature activation completed: $appName" -ForegroundColor Green
                }
            } 
            # --- BRANCH 2: WINGET PACKAGES ---
            else {
                if ($cmdString -notmatch '--accept-package-agreements') { $cmdString += " --accept-package-agreements" }
                if ($cmdString -notmatch '--accept-source-agreements') { $cmdString += " --accept-source-agreements" }
                if ($cmdString -notmatch '--disable-interactivity') { $cmdString += " --disable-interactivity" }

                $appId = ""
                if ($cmdString -match '--id\s+["'']?([^"''\s]+)["'']?') { $appId = $matches[1] }

                $isInstalled = $false
                if (-not [string]::IsNullOrWhiteSpace($appId)) {
                    Write-Host "[+] Checking if '$appName' (ID: $appId) is installed..." -ForegroundColor Yellow
                    $checkResult = winget list --id $appId --accept-source-agreements 2>$null
                    if ($checkResult -match [regex]::Escape($appId)) { $isInstalled = $true }
                }

                if ($isInstalled) {
                    Write-Host "[!] WARNING: '$appName' is ALREADY INSTALLED on this system!" -ForegroundColor Yellow
                    Write-Host "    Skipping installation." -ForegroundColor DarkGray
                } else {
                    Write-Host "[+] Executing WinGet installation command..." -ForegroundColor Green
                    Write-Host "    Command: $cmdString" -ForegroundColor Gray
                    Write-Host ""
                    
                    Invoke-Expression $cmdString
                    Start-Sleep -Seconds 2
                    
                    Write-Host ""
                    Write-Host "[V] Finished installation task for: $appName" -ForegroundColor Green
                }
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
    Write-Host "Press ENTER to return..." -ForegroundColor Gray
    Read-Host | Out-Null

    Clear-Host
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host "          SMART PACKAGE & FEATURE INSTALLER             " -ForegroundColor Cyan
    Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
    Write-Host "========================================================" -ForegroundColor Cyan
    Write-Host ""
}