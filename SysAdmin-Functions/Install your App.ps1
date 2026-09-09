# Module: Install your App.ps1
# Description: Dynamic WinGet Software Installer via .txt Package Definitions
# Author     : Designed by Trung Nguyen IT. All Rights Reserved.

# Set context to local working dir if exists
if ($global:WorkingDir) { Set-Location $global:WorkingDir }

# Determine WinGet packages directory path
$wingetDir = Join-Path $PSScriptRoot "WinGet"

# Fallback check if running under deployed AppData environment
if (-not (Test-Path $wingetDir)) {
    $wingetDir = Join-Path $env:LOCALAPPDATA "SysAdmin-Tools-App\SysAdmin-Functions\WinGet"
}

Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "         WINGET AUTOMATIC APPLICATION INSTALLER     " -ForegroundColor Cyan
Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor DarkGray
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Check WinGet availability on target system
if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
    Write-Host "[!] ERROR: WinGet utility is not detected on this system." -ForegroundColor Red
    Write-Host "    Please ensure App Installer is enabled/updated." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
    Read-Host | Out-Null
    return
}

# Check if WinGet directory exists
if (-not (Test-Path $wingetDir)) {
    New-Item -Path $wingetDir -ItemType Directory | Out-Null
    Write-Host "[!] Notice: Created empty WinGet definitions folder at:" -ForegroundColor Yellow
    Write-Host "    $wingetDir" -ForegroundColor White
    Write-Host "    Please add your app code .txt files into this directory." -ForegroundColor DarkGray
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
    $selection = Read-Host "Select an application number to install"

    if ($selection -eq '0') {
        break
    }

    if ($selection -match '^\d+$' -and [int]$selection -le $packageFiles.Count -and [int]$selection -gt 0) {
        $selectedPackage = $packageFiles[[int]$selection - 1]
        $appName = $selectedPackage.BaseName
        $cmdString = (Get-Content -Path $selectedPackage.FullName -Raw).Trim()

        if ([string]::IsNullOrWhiteSpace($cmdString)) {
            Write-Host "[!] Error: File '$($selectedPackage.Name)' is empty!" -ForegroundColor Red
            Start-Sleep -Seconds 2
            Clear-Host
            continue
        }

        Write-Host ""
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host ">>> Executing Installation: $appName <<<" -ForegroundColor Green
        Write-Host "    Command: $cmdString" -ForegroundColor Gray
        Write-Host "====================================================" -ForegroundColor Green
        Write-Host ""

        # Execute WinGet command dynamically
        Invoke-Expression $cmdString

        Write-Host ""
        Write-Host "[V] Process finished for: $appName" -ForegroundColor Green
        Write-Host ""
        Write-Host "Press ENTER to continue..." -ForegroundColor Gray
        Read-Host | Out-Null
    } else {
        Write-Host "[!] Invalid selection. Please try again!" -ForegroundColor Red
        Start-Sleep -Seconds 1
    }

    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "         WINGET AUTOMATIC APPLICATION INSTALLER     " -ForegroundColor Cyan
    Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor DarkGray
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
}