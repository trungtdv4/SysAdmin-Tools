# Module: Install your App.ps1
# Description: Smart Package Installer with Fixed Absolute Path & Manual ID Fallback
# Author     : Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.

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
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host "                                  SMART PACKAGE & FEATURE INSTALLER                                     " -ForegroundColor Cyan
Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
Write-Host "========================================================================================================" -ForegroundColor Cyan
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
	Write-Host "========================================================================================================" -ForegroundColor Cyan
	Write-Host "                               INSTALL APPLICATION VIA MANUAL WINGET ID                                 " -ForegroundColor Cyan
	Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
	Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
	Write-Host "========================================================================================================" -ForegroundColor Cyan
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
    if (Test-WinGetExactInstalledId -AppId $cleanId) {
        Write-Host "[!] WARNING: App ID '$cleanId' is ALREADY INSTALLED on this system!" -ForegroundColor Yellow
        Write-Host "    Skipping installation." -ForegroundColor DarkGray
    } else {
        Write-Host "[+] Executing WinGet installation for ID: $cleanId..." -ForegroundColor Green
        $wingetArgs = @("install", "--id", $cleanId, "-e", "--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity")
        Write-Host "    Command: winget $($wingetArgs -join ' ')" -ForegroundColor Gray
        Write-Host ""

        & winget @wingetArgs
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host ""
            Write-Host "[V] Successfully installed package with ID: $cleanId" -ForegroundColor Green
        } else {
            Write-Host ""
            Write-Host "[!] Installation failed or exited with error code: $LASTEXITCODE" -ForegroundColor Red
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
	Write-Host "========================================================================================================" -ForegroundColor Cyan
	Write-Host "                              WINGET ONLINE REPOSITORY SEARCH & INSTALL                                 " -ForegroundColor Cyan
	Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
	Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
	Write-Host "========================================================================================================" -ForegroundColor Cyan
    Write-Host ""

    $query = Read-Host "Enter software name to search online (or ENTER to cancel)"
    if ([string]::IsNullOrWhiteSpace($query)) { return }

    Write-Host ""
    Write-Host "[+] Searching WinGet Online Repository for '$query'..." -ForegroundColor Yellow

    $searchRaw = winget search $query --accept-source-agreements 2>$null
    $results = @()
    $startParsing = $false

    foreach ($line in $searchRaw) {
        if ($line -match '^-{10,}') {
            $startParsing = $true
            continue
        }
        if (-not $startParsing -or [string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $rem = $line.Trim()

        # 1. Tách Source ở cuối dòng (winget, msstore...)
        $source = ""
        if ($rem -match '\s+([A-Za-z0-9_\-\.]+)$') {
            $source = $matches[1]
            $rem = $rem.Substring(0, $rem.Length - $matches[0].Length).TrimEnd()
        } else {
            continue
        }

        # 2. Tách Match tag nếu có (Tag: ..., Moniker: ..., Command: ...)
        if ($rem -match '\s+(?:Tag|Moniker|Command):\s+.*$') {
            $rem = $rem.Substring(0, $rem.Length - $matches[0].Length).TrimEnd()
        }

        # 3. Tách Version (từ cuối cùng còn lại)
        $version = ""
        if ($rem -match '\s+(\S+)$') {
            $version = $matches[1]
            $rem = $rem.Substring(0, $rem.Length - $matches[0].Length).TrimEnd()
        } else {
            continue
        }

        # 4. Tách ID (từ cuối cùng còn lại, ID trong WinGet không bao giờ có khoảng trắng)
        $id = ""
        if ($rem -match '\s+(\S+)$') {
            $id = $matches[1]
            $rem = $rem.Substring(0, $rem.Length - $matches[0].Length).TrimEnd()
        } else {
            continue
        }

        # 5. Phần chuỗi còn lại ở đầu dòng chính là Name (tên app đầy đủ)
        $name = $rem.Trim()
        if (-not [string]::IsNullOrWhiteSpace($name) -and -not [string]::IsNullOrWhiteSpace($id)) {
            $results += [PSCustomObject]@{
                Name    = $name
                Id      = $id
                Version = $version
                Source  = $source
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
        $sourceTag = if ($results[$i].Source) { " ($($results[$i].Source))" } else { "" }
        Write-Host "  $($i + 1). $($results[$i].Name) " -NoNewline -ForegroundColor White
        Write-Host "[$($results[$i].Id)]" -NoNewline -ForegroundColor Cyan
        Write-Host "$sourceTag" -ForegroundColor DarkGray
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
            if (Test-WinGetExactInstalledId -AppId $appId) {
                Write-Host "[!] WARNING: '$appName' is ALREADY INSTALLED on this system!" -ForegroundColor Yellow
                Write-Host "    Skipping installation." -ForegroundColor DarkGray
            } else {
                Write-Host "[+] Executing WinGet online installation..." -ForegroundColor Green
                
                $wingetArgs = @("install", "--id", $appId, "-e")
                if ($app.Source) {
                    $wingetArgs += @("--source", $app.Source)
                }
                $wingetArgs += @("--accept-package-agreements", "--accept-source-agreements", "--disable-interactivity")
                
                Write-Host "    Command: winget $($wingetArgs -join ' ')" -ForegroundColor Gray
                Write-Host ""
                
                & winget @wingetArgs
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host ""
                    Write-Host "[V] Finished installation task for: $appName" -ForegroundColor Green
                } else {
                    Write-Host ""
                    Write-Host "[!] ERROR: Failed to install '$appName' automatically (Exit Code: $LASTEXITCODE)." -ForegroundColor Red
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
# INSTALLED-APP DETECTION: WinGet JSON inventory + Windows uninstall registry
# ------------------------------------------------------------------------------
function Get-WinGetInstalledIdHashSet {
    Write-Host "[+] Loading installed WinGet package IDs..." -ForegroundColor Yellow

    # HashSet keeps exact, case-insensitive package-ID comparisons.
    $installedIds = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $tempExportPath = Join-Path $env:TEMP ("SysAdminTools-WinGetExport-{0}.json" -f ([guid]::NewGuid().ToString('N')))

    try {
        $wingetCommand = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($wingetCommand) {
            # winget export writes a supported JSON format. Do not parse the
            # human-readable "winget list" table, whose columns can shift.
            & $wingetCommand.Source export --output $tempExportPath --accept-source-agreements --disable-interactivity 2>$null | Out-Null

            if (Test-Path -LiteralPath $tempExportPath) {
                $exportData = Get-Content -LiteralPath $tempExportPath -Raw -ErrorAction Stop |
                    ConvertFrom-Json -ErrorAction Stop

                foreach ($source in @($exportData.Sources)) {
                    foreach ($package in @($source.Packages)) {
                        $packageId = [string]$package.PackageIdentifier
                        if (-not [string]::IsNullOrWhiteSpace($packageId)) {
                            [void]$installedIds.Add($packageId.Trim())
                        }
                    }
                }
            }
        }
    } catch {
        Write-Host "[!] WinGet JSON inventory unavailable; checking registered app names where possible." -ForegroundColor DarkYellow
    } finally {
        if (Test-Path -LiteralPath $tempExportPath) {
            Remove-Item -LiteralPath $tempExportPath -Force -ErrorAction SilentlyContinue
        }
    }

    # Keep the HashSet as a single object instead of letting PowerShell
    # enumerate its elements into separate pipeline outputs.
    return ,$installedIds
}

function Get-InstalledApplicationRegistryInventory {
    $uninstallPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $installedEntries = @(
        foreach ($registryPath in $uninstallPaths) {
            Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue |
                Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.DisplayName) } |
                Select-Object DisplayName, DisplayVersion, Publisher
        }
    )

    # Click-to-Run's ProductReleaseIds distinguish Microsoft 365 from Office LTSC 2024.
    $officeConfigurationPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration'
    )
    $officeProductReleaseIds = @(
        foreach ($registryPath in $officeConfigurationPaths) {
            $configuration = Get-ItemProperty -Path $registryPath -ErrorAction SilentlyContinue
            if ($configuration -and -not [string]::IsNullOrWhiteSpace([string]$configuration.ProductReleaseIds)) {
                [string]$configuration.ProductReleaseIds
            }
        }
    )

    return [PSCustomObject]@{
        Entries = $installedEntries
        OfficeProductReleaseIds = $officeProductReleaseIds
    }
}

function Test-WinGetExactInstalledId {
    param (
        [Parameter(Mandatory = $true)]
        [string]$AppId
    )

    if ([string]::IsNullOrWhiteSpace($AppId)) { return $false }

    try {
        # Query one exact ID and verify it as a complete token, never as a substring.
        $listOutput = & winget list --id $AppId --exact --accept-source-agreements --disable-interactivity 2>$null
        $idPattern = '(?i)(?<![A-Za-z0-9._+-])' + [regex]::Escape($AppId.Trim()) + '(?![A-Za-z0-9._+-])'

        foreach ($line in @($listOutput)) {
            if ([string]$line -match $idPattern) { return $true }
        }
    } catch {
        return $false
    }

    return $false
}

function ConvertTo-AppNameKey {
    param ([string]$Name)

    if ([string]::IsNullOrWhiteSpace($Name)) { return "" }

    $cleanName = $Name -replace '\s*\([^)]*\)\s*$', ''
    $cleanName = $cleanName -replace '[®™©]', ''
    return ($cleanName -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
}

function Test-AppIsInstalledWinGetArray {
    param (
        [System.IO.FileInfo]$packageFile,
        [System.Collections.Generic.HashSet[string]]$installedIdsSet,
        [PSCustomObject]$installedAppInventory
    )

    if ($packageFile.Extension -eq ".ps1") { return $false }

    $cmdString = (Get-Content -Path $packageFile.FullName -Raw -ErrorAction SilentlyContinue).Trim()
    if ([string]::IsNullOrWhiteSpace($cmdString)) { return $false }

    # 1. Windows Optional Features (DISM)
    if ($cmdString -match 'Enable-WindowsOptionalFeature|DISM') {
        if ($cmdString -match '-FeatureName\s+["'']?([^"''\s]+)["'']?') {
            $featureName = $matches[1]
            $featureStatus = Get-WindowsOptionalFeature -Online -FeatureName $featureName -ErrorAction SilentlyContinue
            if ($featureStatus -and $featureStatus.State -eq "Enabled") { return $true }
        }
        return $false
    }

    # 2. Extract the package ID from the local install definition.
    $appId = ""
    if ($cmdString -match '(?i)--id\s+["'']?([^"''\s]+)["'']?') {
        $appId = $matches[1].Trim()
    }

    $packageName = [string]$packageFile.BaseName
    $officeProductIds = (@($installedAppInventory.OfficeProductReleaseIds) -join ';')

    # Microsoft 365 and the "Office 2024" menu entry currently share the same
    # WinGet ID (Microsoft.Office), so use Click-to-Run product identity here.
    if ($appId -ieq 'Microsoft.Office' -and $packageName -match '(?i)^Microsoft\s+Office\s+2024\b') {
        if ($officeProductIds -match '(?i)2024') { return $true }

        foreach ($entry in @($installedAppInventory.Entries)) {
            if ([string]$entry.DisplayName -match '(?i)^Microsoft\s+Office.*\b2024\b') { return $true }
        }
        return $false
    }

    if ($appId -ieq 'Microsoft.Office' -and $packageName -match '(?i)^Microsoft\s+365\b') {
        if ($officeProductIds -match '(?i)(O365|M365|Microsoft365)') { return $true }

        foreach ($entry in @($installedAppInventory.Entries)) {
            if ([string]$entry.DisplayName -match '(?i)^(Microsoft\s+365|Microsoft\s+Office\s+365|Microsoft\s+365\s+Apps)\b') {
                return $true
            }
        }
        return $false
    }

    # 3. Exact package ID from WinGet's JSON export.
    if (-not [string]::IsNullOrWhiteSpace($appId) -and
        $installedIdsSet -and $installedIdsSet.Contains($appId)) {
        return $true
    }

    # 4. Query WinGet directly if export could not map this package.
    #    This is slower than the cache, so it is used only for unresolved IDs.
    if (-not [string]::IsNullOrWhiteSpace($appId) -and
        (Test-WinGetExactInstalledId -AppId $appId)) {
        return $true
    }

    # 5. Display-name fallback for apps installed outside WinGet or not mapped
    #    to a source ID (notably Intel Driver & Support Assistant).
    if ($appId -ieq 'Intel.IntelDriverAndSupportAssistant') {
        foreach ($entry in @($installedAppInventory.Entries)) {
            if ([string]$entry.DisplayName -match '(?i)\bIntel\b.*(?:Driver\s*(?:&|and)\s*Support\s*Assistant|\bDSA\b)') {
                return $true
            }
        }
    }

    $packageNameKey = ConvertTo-AppNameKey -Name $packageName
    if ($packageNameKey.Length -ge 4) {
        foreach ($entry in @($installedAppInventory.Entries)) {
            $installedNameKey = ConvertTo-AppNameKey -Name ([string]$entry.DisplayName)
            if ([string]::IsNullOrWhiteSpace($installedNameKey)) { continue }

            if ($installedNameKey -eq $packageNameKey) { return $true }

            # Permit a version or locale suffix, but do not use broad substring matching.
            if ($installedNameKey.StartsWith($packageNameKey, [StringComparison]::OrdinalIgnoreCase)) {
                $suffix = $installedNameKey.Substring($packageNameKey.Length)
                if ($suffix -match '^(?:\d|x64|x86|32bit|64bit|enus|eng|update|version)') {
                    return $true
                }
            }
        }
    }

    return $false
}

# ------------------------------------------------------------------------------
# MAIN LOCAL MENU LOOP
# ------------------------------------------------------------------------------	
$checkInstalled = $false

while ($true) {
	Clear-Host
	Write-Host "====================================================" -ForegroundColor Cyan
	Write-Host "       SMART PACKAGE & FEATURE INSTALLER            " -ForegroundColor Cyan
	Write-Host "  Copyright (c) 2026 Trung Nguyen. All Rights Reserved. " -ForegroundColor DarkGray
	Write-Host "====================================================" -ForegroundColor Cyan
	Write-Host ""

	# Load the WinGet ID cache and registry inventory only when check switch is enabled.
	if ($checkInstalled) {
		$installedIdsSet = Get-WinGetInstalledIdHashSet
		$installedAppInventory = Get-InstalledApplicationRegistryInventory
		Write-Host ""
	} else {
		$installedIdsSet = $null
		$installedAppInventory = $null
	}

	# Quet danh sach file .txt local
	$packageFiles = Get-ChildItem -Path $wingetDir -Filter "*.*" -ErrorAction SilentlyContinue | Where-Object { $_.Extension -eq ".txt" -or $_.Extension -eq ".ps1" } | Sort-Object Name

	Write-Host "AVAILABLE LOCAL PACKAGES & CUSTOM INSTALLERS:" -ForegroundColor Yellow

	if ($packageFiles -and $packageFiles.Count -gt 0) {
		for ($i = 0; $i -lt $packageFiles.Count; $i++) {
			$file = $packageFiles[$i]
			$extTag = if ($file.Extension -eq ".ps1") { " [Custom Script]" } else { "" }
			
			if ($checkInstalled) {
				# Prefer exact IDs from the cache; use exact WinGet/registry fallbacks when needed.
				$isInstalled = Test-AppIsInstalledWinGetArray -packageFile $file -installedIdsSet $installedIdsSet -installedAppInventory $installedAppInventory

				if ($isInstalled) {
					Write-Host "  $($i + 1). $($file.BaseName)$extTag " -NoNewline -ForegroundColor Green
					Write-Host "[Installed]" -ForegroundColor DarkGreen
				} else {
					Write-Host "  $($i + 1). $($file.BaseName)$extTag" -ForegroundColor White
				}
			} else {
				Write-Host "  $($i + 1). $($file.BaseName)$extTag" -ForegroundColor White
			}
		}
	}

    $statusDisplay = if ($checkInstalled) { "[ON - Scanned]" } else { "[OFF - Fast Mode]" }
    $statusColor   = if ($checkInstalled) { "Green" } else { "DarkGray" }
    Write-Host "  X. Check Installed Status: " -NoNewline -ForegroundColor Cyan
    Write-Host "$statusDisplay" -ForegroundColor $statusColor
    Write-Host "  Y. Input App ID Manually (Fallback for special apps)" -ForegroundColor Yellow
    Write-Host "  Z. Other? (Search online repository)" -ForegroundColor Blue
    Write-Host "  0. Return to Main Menu" -ForegroundColor Gray
    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Tips: Enter numbers separated by commas to install multiple items (e.g., 1,3)" -ForegroundColor Gray
    $selectionInput = Read-Host "Select an option or package number(s)"

    if ([string]::IsNullOrWhiteSpace($selectionInput)) { continue }
    if ($selectionInput.Trim() -eq '0') { break }

    # Option X: Toggle Check Installed Status
    if ($selectionInput.Trim() -ieq 'X') {
        $checkInstalled = -not $checkInstalled
        continue
    }

    # Option Y: Manual App ID Input
    if ($selectionInput.Trim() -eq 'Y' -or $selectionInput.Trim() -eq 'y') {
        Invoke-WinGetManualIdInstall
        Clear-Host
		Write-Host "========================================================================================================" -ForegroundColor Cyan
		Write-Host "                                 SMART PACKAGE & FEATURE INSTALLER                                      " -ForegroundColor Cyan
		Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
		Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
		Write-Host "========================================================================================================" -ForegroundColor Cyan
        Write-Host ""
        continue
    }

    # Option Z: Online Search
    if ($selectionInput.Trim() -eq 'Z' -or $selectionInput.Trim() -eq 'z') {
        Invoke-WinGetOnlineSearch
        Clear-Host
		Write-Host "========================================================================================================" -ForegroundColor Cyan
		Write-Host "                                 SMART PACKAGE & FEATURE INSTALLER                                      " -ForegroundColor Cyan
		Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
		Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
		Write-Host "========================================================================================================" -ForegroundColor Cyan
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
                        if (Test-WinGetExactInstalledId -AppId $appId) { $isInstalled = $true }
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
	Write-Host "========================================================================================================" -ForegroundColor Cyan
	Write-Host "                                 SMART PACKAGE & FEATURE INSTALLER                                      " -ForegroundColor Cyan
	Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
	Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
	Write-Host "========================================================================================================" -ForegroundColor Cyan
    Write-Host ""
}

# ------------------------------------------------------------------------------
# [FLAG: GLOBAL_ERROR_TRAP] - Giu man hinh dừng lai neu co loi bat ngo
# ------------------------------------------------------------------------------
trap {
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host "[!] CRITICAL ERROR DETECTED:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Yellow
    Write-Host "Script Location: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Gray
    Write-Host "====================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Press ENTER to exit..." -ForegroundColor White
    Read-Host | Out-Null
    continue
}