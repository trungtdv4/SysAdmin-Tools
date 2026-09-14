# Module: Install your App.ps1
# Description: Smart Package Installer with Fixed Absolute Path & Manual ID Fallback
# Author     : Designed by trungtdv4@gmail.com. All Rights Reserved.

# Fix Working Directory Context to script's own directory
$currentScriptDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($currentScriptDir)) {
    $currentScriptDir = Join-Path $env:LOCALAPPDATA "SysAdmin-Tools-App\SysAdmin-Functions"
}

# Absolute Path to WinGet directory
$wingetDir = Join-Path $currentScriptDir "WinGet"

# Set current location context
if (Test-Path $currentScriptDir) {
    Set-Location $currentScriptDir
}

Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "       SMART PACKAGE & FEATURE INSTALLER            " -ForegroundColor Cyan
Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Auto-create WinGet folder if it does not exist
if (-not (Test-Path $wingetDir)) {
    New-Item -Path $wingetDir -ItemType Directory -Force | Out-Null
}

# ------------------------------------------------------------------------------
# HELPER 1: EXECUTE DIRECT WINGET INSTALL BY MANUAL ID (OPTION Y)
# ------------------------------------------------------------------------------
function Invoke-WinGetManualIdInstall {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "      INSTALL APPLICATION VIA MANUAL WINGET ID      " -ForegroundColor Cyan
    Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Tips: Enter exact WinGet App ID (e.g., Google.Chrome, 9N4S39MXHM1T)" -ForegroundColor Gray
    
    $manualId = Read-Host "Enter App ID to install (or ENTER to cancel)"
    if ([string]::IsNullOrWhiteSpace($manualId)) { return }

    $cleanId = $manualId.Trim()

    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ">>> Processing Manual App ID: $cleanId <<<" -ForegroundColor Cyan
    Write-Host "====================================================" -ForegroundColor Cyan

    Write-Host "[+] Checking if ID '$cleanId' is already installed..." -ForegroundColor Yellow
    $checkResult = winget list --id $cleanId --accept-source-agreements 2>$null

    if ($checkResult -match [regex]::Escape($cleanId)) {
        Write-Host "[!] WARNING: App ID '$cleanId' is ALREADY INSTALLED on this system!" -ForegroundColor Yellow
        Write-Host "    Skipping installation." -ForegroundColor DarkGray
    } else {
        Write-Host "[+] Executing WinGet installation for ID: $cleanId..." -ForegroundColor Green
        $cmd = "winget install --id `"$cleanId`" -e --silent --disable-interactivity --accept-package-agreements --accept-source-agreements"
        Write-Host "    Command: $cmd" -ForegroundColor Gray
        Write-Host ""

        $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command $cmd" -Wait -NoNewWindow -PassThru
        
        if ($process.ExitCode -eq 0) {
            Write-Host ""
            Write-Host "[V] Successfully installed package with ID: $cleanId" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "[!] Installation failed or exited with error code: $($process.ExitCode)" -ForegroundColor Red
            Write-Host "    Please double-check the exact ID using 'winget search' CLI." -ForegroundColor Yellow
        }
    }

    Write-Host ""
    Write-Host "Press ENTER to return to menu..." -ForegroundColor Gray
    Read-Host | Out-Null
}

# ------------------------------------------------------------------------------
# HELPER 2: ONLINE SEARCH & INSTALL (OPTION Z)
# ------------------------------------------------------------------------------
function Invoke-WinGetOnlineSearch {
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "     WINGET ONLINE REPOSITORY SEARCH & INSTALL      " -ForegroundColor Cyan
    Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
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
            $cleanLine = $line -replace '\[Unknown\]|\[msstore\]|\[winget\]', ''
            $parts = $cleanLine -split '\s{2,}' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

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

            Write-Host "[+] Checking if '$appName' is already installed..." -ForegroundColor Yellow
            $checkResult = winget list --id $appId --accept-source-agreements 2>$null

            if ($checkResult -match [regex]::Escape($appId)) {
                Write-Host "[!] WARNING: '$appName' is ALREADY INSTALLED on this system!" -ForegroundColor Yellow
                Write-Host "    Skipping installation." -ForegroundColor DarkGray
            } else {
                Write-Host "[+] Executing WinGet online installation..." -ForegroundColor Green
                $cmd = "winget install --id `"$appId`" -e --silent --disable-interactivity --accept-package-agreements --accept-source-agreements"
                Write-Host "    Command: $cmd" -ForegroundColor Gray
                
                $process = Start-Process -FilePath "powershell.exe" -ArgumentList "-Command $cmd" -Wait -NoNewWindow -PassThru
                
                if ($process.ExitCode -eq 0) {
                    Write-Host "[V] Finished installation task for: $appName" -ForegroundColor Green
                } else {
                    Write-Host "[!] ERROR: Failed to install '$appName' automatically." -ForegroundColor Red
                    Write-Host "    [GUIDE]: Please note down ID [$appId], return to Menu, and choose Option Y to input manually!" -ForegroundColor Yellow
                }
                Start-Sleep -Seconds 2
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
    # Absolute Path Scan for .txt and .ps1 files in WinGet directory
    $packageFiles = Get-ChildItem -Path $wingetDir -Filter "*.*" -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq ".txt" -or $_.Extension -eq ".ps1" } | Sort-Object Name

    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host "AVAILABLE LOCAL PACKAGES & CUSTOM INSTALLERS:" -ForegroundColor Yellow

    if ($packageFiles -and $packageFiles.Count -gt 0) {
        for ($i = 0; $i -lt $packageFiles.Count; $i++) {
            $extTag = if ($packageFiles[$i].Extension -eq ".ps1") { " [Custom Script]" } else { "" }
            Write-Host "  $($i + 1). $($packageFiles[$i].BaseName)$extTag" -ForegroundColor White
        }
    } else {
        Write-Host "  (No local .txt or .ps1 package definitions found in: $wingetDir)" -ForegroundColor DarkGray
    }

    Write-Host "  Y. Input App ID Manually (Fallback for special apps)" -ForegroundColor Yellow
    Write-Host "  Z. Other? (Search online repository)" -ForegroundColor Green
    Write-Host "  0. Return to Main Menu" -ForegroundColor Gray
    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Tips: Enter numbers separated by commas to install multiple items (e.g., 1,3)" -ForegroundColor Gray
    $selectionInput = Read-Host "Select an option or package number(s)"

    if ($selectionInput.Trim() -eq '0') { break }

    # Option Y: Manual App ID Input
    if ($selectionInput.Trim() -eq 'Y' -or $selectionInput.Trim() -eq 'y') {
        Invoke-WinGetManualIdInstall
        Clear-Host
        Write-Host "====================================================" -ForegroundColor Cyan
        Write-Host "       SMART PACKAGE & FEATURE INSTALLER            " -ForegroundColor Cyan
        Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
        Write-Host "====================================================" -ForegroundColor Cyan
        Write-Host ""
        continue
    }

    # Option Z: Online Search
    if ($selectionInput.Trim() -eq 'Z' -or $selectionInput.Trim() -eq 'z') {
        Invoke-WinGetOnlineSearch
        Clear-Host
        Write-Host "====================================================" -ForegroundColor Cyan
        Write-Host "       SMART PACKAGE & FEATURE INSTALLER            " -ForegroundColor Cyan
        Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
        Write-Host "====================================================" -ForegroundColor Cyan
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

            Write-Host ""
            Write-Host "====================================================" -ForegroundColor Cyan
            Write-Host ">>> Processing Item [$index]: $appName <<<" -ForegroundColor Cyan
            Write-Host "====================================================" -ForegroundColor Cyan

            # --- BRANCH 1: CUSTOM POWERSHELL SCRIPT (.ps1) ---
            if ($selectedPackage.Extension -eq ".ps1") {
                Write-Host "[+] Executing Custom Script Installer: $($selectedPackage.Name)" -ForegroundColor Green
                Write-Host ""
                & $selectedPackage.FullName
                Write-Host ""
                Write-Host "[V] Finished Custom Script execution for: $appName" -ForegroundColor Green
            }
            # --- BRANCH 2: TEXT DEFINITION FILES (.txt) ---
            else {
                $cmdString = (Get-Content -Path $selectedPackage.FullName -Raw).Trim()

                if ([string]::IsNullOrWhiteSpace($cmdString)) {
                    Write-Host "[!] Error: File '$($selectedPackage.Name)' is empty!" -ForegroundColor Red
                    continue
                }

                # Windows Feature Check
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
                # WinGet Command Check
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
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "       SMART PACKAGE & FEATURE INSTALLER            " -ForegroundColor Cyan
    Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
}