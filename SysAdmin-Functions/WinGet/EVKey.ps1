# ==============================================================================
# Script Name: EVKey.ps1
# Description: Copies EVKey folder to C:\, creates Desktop Shortcut, and launches EVKey64.exe
# Author     : Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.
# ==============================================================================

# 1. Determine Source and Destination Paths (Smart Relative Path Lookup)
# Step 1: Try resolving relative path to SysAdmin-Resources
$sourceDir = Join-Path $PSScriptRoot "..\..\SysAdmin-Resources\EVKey"

# Step 2: Fallback lookup for AppData execution environment
if (-not (Test-Path $sourceDir)) {
    $sourceDir = Join-Path $env:LOCALAPPDATA "SysAdmin-Tools-App\SysAdmin-Resources\EVKey"
}

$destDir = "C:\EVKey"
$exePath = Join-Path $destDir "EVKey64.exe"

Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host "                                      EVKEY CUSTOM INSTALLER                                            " -ForegroundColor Cyan
Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host ""

if (-not (Test-Path $sourceDir)) {
    Write-Host "[!] Error: Source directory 'EVKey' not found in $PSScriptRoot!" -ForegroundColor Red
    Write-Host "    Please ensure 'EVKey' folder exists next to this script." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Press ENTER to return..." -ForegroundColor Gray
    Read-Host | Out-Null
    return
}

# 2. Copy EVKey Folder to C:\ Directory
try {
    Write-Host "[+] Copying EVKey files to $destDir..." -ForegroundColor Yellow
    if (-not (Test-Path $destDir)) {
        New-Item -Path $destDir -ItemType Directory | Out-Null
    }
    Copy-Item -Path "$sourceDir\*" -Destination $destDir -Recurse -Force -ErrorAction Stop
    Write-Host "  [V] Files copied successfully!" -ForegroundColor Green
} catch {
    Write-Host "  [!] Failed to copy files: $_" -ForegroundColor Red
    return
}

# 3. Create Shortcut on User Desktop
try {
    Write-Host "[+] Creating Shortcut on Desktop..." -ForegroundColor Yellow
    
    $desktopPath = [System.Environment]::GetFolderPath("Desktop")
    $shortcutPath = Join-Path $desktopPath "EVKey.lnk"

    # Use WScript.Shell COM Object to build .lnk shortcut
    $wshShell = New-Object -ComObject WScript.Shell
    $shortcut = $wshShell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $exePath
    $shortcut.WorkingDirectory = $destDir
    $shortcut.Description = "EVKey Vietnamese Keyboard"
    $shortcut.IconLocation = "$exePath, 0"
    $shortcut.Save()

    Write-Host "  [V] Desktop Shortcut created at: $shortcutPath" -ForegroundColor Green
} catch {
    Write-Host "  [!] Failed to create Desktop Shortcut: $_" -ForegroundColor Red
}

# 4. Launch EVKey Application
Write-Host ""
if (Test-Path $exePath) {
    Write-Host "[+] Launching EVKey64.exe..." -ForegroundColor Green
    Start-Process -FilePath $exePath -WorkingDirectory $destDir
    Write-Host "[V] EVKey installed, shortcut created, and launched successfully!" -ForegroundColor Green
} else {
    Write-Host "[!] Error: Executive file 'EVKey64.exe' not found at $exePath!" -ForegroundColor Red
}

Write-Host ""
Write-Host "Press ENTER to return..." -ForegroundColor Gray
Read-Host | Out-Null