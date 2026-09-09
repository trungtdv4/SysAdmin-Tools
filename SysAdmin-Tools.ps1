# ==============================================================================
# Script Name: SysAdmin-Tools.ps1
# Description: Portable System Administration Platform
# Author     : Designed by Trung Nguyen IT. All Rights Reserved.
# ==============================================================================

function Test-IsAdmin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "      SYSADMIN TOOLS - SYSTEM MANAGEMENT PLATFORM   " -ForegroundColor Cyan
Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-IsAdmin)) {
    Write-Host "[!] NOTICE: Running under Standard User Privileges." -ForegroundColor Yellow
    Write-Host "    Administrative functions will require elevation." -ForegroundColor DarkGray
    Write-Host ""
}

# Dynamic Module Scan (Physical Local Path)
$functionsDir = Join-Path $PSScriptRoot "SysAdmin-Functions"

while ($true) {
    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host "AVAILABLE SYSTEM ADMIN FUNCTIONS:" -ForegroundColor Cyan

    $scriptFiles = Get-ChildItem -Path $functionsDir -Filter "*.ps1" -ErrorAction SilentlyContinue | Sort-Object Name

    if (-not $scriptFiles -or $scriptFiles.Count -eq 0) {
        Write-Host "[!] No function scripts (.ps1) found in: $functionsDir" -ForegroundColor Red
        Write-Host "  0. Exit Application" -ForegroundColor Gray
    } else {
        for ($i = 0; $i -lt $scriptFiles.Count; $i++) {
            Write-Host "  $($i + 1). $($scriptFiles[$i].BaseName)" -ForegroundColor White
        }
        Write-Host "  0. Exit Application" -ForegroundColor Gray
    }

    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""
    $selection = Read-Host "Select a function number"

    if ($selection -eq '0') {
        Write-Host ""
        Write-Host "[+] Cleaning up application directory in AppData..." -ForegroundColor Yellow
        
        $appDataDir = Join-Path $env:LOCALAPPDATA "SysAdmin-Tools-App"
        if (Test-Path $appDataDir) {
            Remove-Item -Path $appDataDir -Recurse -Force -ErrorAction SilentlyContinue
        }

        Write-Host "Thank you for using SysAdmin Tools! Goodbye." -ForegroundColor Green
        Write-Host "Designed by Trung Nguyen IT. All Rights Reserved." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        Exit
    }

    if ($selection -match '^\d+$' -and [int]$selection -le $scriptFiles.Count -and [int]$selection -gt 0) {
        $selectedScript = $scriptFiles[[int]$selection - 1].FullName
        Write-Host ""
        Write-Host ">>> Executing Module: $($scriptFiles[[int]$selection - 1].BaseName) <<<" -ForegroundColor Green
        
        & $selectedScript
    } else {
        Write-Host "[!] Invalid selection. Please try again!" -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
    
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "      SYSADMIN TOOLS - SYSTEM MANAGEMENT PLATFORM   " -ForegroundColor Cyan
    Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor Yellow
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
}