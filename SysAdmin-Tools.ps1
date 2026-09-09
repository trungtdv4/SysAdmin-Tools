# ==============================================================================
# Script Name: SysAdmin-Tools.ps1
# Description: Portable System Administration Wish Tools Platform
# Author     : Designed by Trung Nguyen IT. All Rights Reserved.
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. HELPER & PRIVILEGE CHECK FUNCTIONS
# ------------------------------------------------------------------------------
function Test-IsAdmin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

# ------------------------------------------------------------------------------
# 2. INITIALIZE ENVIRONMENT & MODULE DYNAMIC SCAN
# ------------------------------------------------------------------------------
Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "      SYSADMIN TOOLS - SYSTEM MANAGEMENT PLATFORM   " -ForegroundColor Cyan
Write-Host "  Designed by Trung Nguyen IT. All Rights Reserved. " -ForegroundColor Yellow
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

# Determine functions directory (support local and remote execution)
$global:WorkingDir = if (Test-Path "D:\") { "D:\SysAdmin-Tools" } else { "C:\SysAdmin-Tools" }
if (-not (Test-Path $global:WorkingDir)) {
    New-Item -Path $global:WorkingDir -ItemType Directory | Out-Null
}

$functionsDir = Join-Path $PSScriptRoot "SysAdmin-Functions"
if ([string]::IsNullOrEmpty($PSScriptRoot) -or (-not (Test-Path $functionsDir))) {
    $functionsDir = Join-Path $global:WorkingDir "SysAdmin-Functions"
    if (-not (Test-Path $functionsDir)) {
        New-Item -Path $functionsDir -ItemType Directory | Out-Null
    }
}

if (-not (Test-IsAdmin)) {
    Write-Host "[!] NOTICE: Running under Standard User Privileges." -ForegroundColor Yellow
    Write-Host "    Administrative functions will require elevation." -ForegroundColor DarkGray
    Write-Host ""
}

# ------------------------------------------------------------------------------
# 3. DYNAMIC MENU LOOP
# ------------------------------------------------------------------------------
while ($true) {
    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host "AVAILABLE SYSTEM ADMIN FUNCTIONS:" -ForegroundColor Cyan

    # Dynamic scan for .ps1 files in SysAdmin-Functions
    $scriptFiles = Get-ChildItem -Path $functionsDir -Filter "*.ps1" -ErrorAction SilentlyContinue | Sort-Object Name

    if (-not $scriptFiles -or $scriptFiles.Count -eq 0) {
        Write-Host "[!] No function scripts (.ps1) found in: $functionsDir" -ForegroundColor Red
        Write-Host "    Please add module scripts into the directory above." -ForegroundColor DarkGray
        Write-Host ""
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
        Write-Host "Thank you for using SysAdmin Tools! Goodbye." -ForegroundColor Green
        Write-Host "Designed by Trung Nguyen IT. All Rights Reserved." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        Exit
    }

    if ($selection -match '^\d+$' -and [int]$selection -le $scriptFiles.Count -and [int]$selection -gt 0) {
        $selectedScript = $scriptFiles[[int]$selection - 1].FullName
        Write-Host ""
        Write-Host ">>> Executing Module: $($scriptFiles[[int]$selection - 1].BaseName) <<<" -ForegroundColor Green
        
        # Execute module script
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