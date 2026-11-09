# ==============================================================================
# Script Name: SysAdmin-Tools.ps1
# Description: Portable System Administration Platform
# Author     : Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.
# ==============================================================================

function Test-IsAdmin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

Clear-Host
Write-Host "========================================================================================================" -ForegroundColor Cyan
Write-Host "                             SYSADMIN TOOLS - SYSTEM MANAGEMENT PLATFORM                                " -ForegroundColor Cyan
Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
Write-Host "========================================================================================================" -ForegroundColor Cyan
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

    $scriptFiles = @(Get-ChildItem -Path $functionsDir -File -ErrorAction SilentlyContinue | Where-Object { $_.Extension -in '.ps1', '.bat', '.cmd' } | Sort-Object Name)

    if (-not $scriptFiles -or $scriptFiles.Count -eq 0) {
        Write-Host "[!] No function scripts (.ps1, .bat) found in: $functionsDir" -ForegroundColor Red
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
        Write-Host "Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved." -ForegroundColor Yellow
        Start-Sleep -Seconds 1
        Exit
    }

    if ($selection -match '^\d+$' -and [int]$selection -le $scriptFiles.Count -and [int]$selection -gt 0) {
        $selectedScript = $scriptFiles[[int]$selection - 1].FullName
        Write-Host ""
        Write-Host ">>> Executing Module: $($scriptFiles[[int]$selection - 1].BaseName) <<<" -ForegroundColor Green
        
        $ext = [System.IO.Path]::GetExtension($selectedScript).ToLower()

        if ($ext -eq '.bat' -or $ext -eq '.cmd') {
            # Kiem tra xem co phai file hybrid Bat/PS1 khong (co dong <# : o dau)
            $firstLine = Get-Content -Path $selectedScript -TotalCount 1 -ErrorAction SilentlyContinue
            if ($firstLine -and $firstLine.TrimStart() -match '^<#\s*:') {
                # Day la file hybrid: extract phan PowerShell (tu sau dong "#>") va chay trong process moi
                # KHONG goi bat truc tiep vi bat header se chay lai vong lap tu-elevate vo han
                $allLines   = Get-Content -Path $selectedScript -Encoding UTF8 -ErrorAction SilentlyContinue
                $psStartIdx = -1
                for ($li = 0; $li -lt $allLines.Count; $li++) {
                    if ($allLines[$li].TrimEnd() -eq '#>') {
                        $psStartIdx = $li + 1
                        break
                    }
                }
                if ($psStartIdx -ge 0 -and $psStartIdx -lt $allLines.Count) {
                    $psContent = ($allLines[$psStartIdx..($allLines.Count - 1)]) -join "`r`n"
                    $tmpFile   = [System.IO.Path]::Combine($env:TEMP, "sat_hybrid_$([System.IO.Path]::GetRandomFileName()).ps1")
                    Set-Content -Path $tmpFile -Value $psContent -Encoding UTF8 -Force
                    try {
                        & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $tmpFile
                    } finally {
                        Remove-Item -Path $tmpFile -Force -ErrorAction SilentlyContinue
                    }
                } else {
                    # Khong tim thay ranh gioi PS, chay bat qua cmd de tranh loi
                    & cmd.exe /c `"$selectedScript`"
                }
            } else {
                # Bat thong thuong (khong hybrid): chay qua cmd
                & cmd.exe /c `"$selectedScript`"
            }
        } else {
            # File .ps1: chay qua powershell.exe moi doc lap
            # KHONG dung "& $selectedScript" inline vi loi tu script con se propagate
            # len SysAdmin-Tools.ps1 va co the crash toan bo session (cua so tat ngay)
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $selectedScript
        }
    } else {
        Write-Host "[!] Invalid selection. Please try again!" -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
    
    Clear-Host
	Write-Host "========================================================================================================" -ForegroundColor Cyan
	Write-Host "                             SYSADMIN TOOLS - SYSTEM MANAGEMENT PLATFORM                                " -ForegroundColor Cyan
	Write-Host "  Copyright (c) 2026 Trung Nguyen (82429801+trungtdv4@users.noreply.github.com). All rights reserved.   " -ForegroundColor DarkGray
	Write-Host "                      Licensed under the GNU General Public License v3.0 (GPLv3).                       " -ForegroundColor DarkGray
	Write-Host "========================================================================================================" -ForegroundColor Cyan
    Write-Host ""
}