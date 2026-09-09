# ==============================================================================
# Script Name: SysAdmin-Tools.ps1
# Description: Dynamic System Admin Platform (Pure Dynamic Dynamic Scan)
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
# 2. CONFIGURATION FOR REMOTE IN-MEMORY SCAN
# ------------------------------------------------------------------------------
$githubUser = "trungtdv4"   # Thay Username GitHub của anh
$githubRepo = "SysAdmin-Tools"         # Thay Tên Repository của anh
$branch     = "main"

# ------------------------------------------------------------------------------
# 3. ENVIRONMENT DETECTION & DYNAMIC MENU LOOP
# ------------------------------------------------------------------------------
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

# Check if running in memory (irm | iex) or physical file
$isInMemory = [string]::IsNullOrEmpty($PSScriptRoot)
$localFunctionsDir = Join-Path $PSScriptRoot "SysAdmin-Functions"

while ($true) {
    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host "AVAILABLE SYSTEM ADMIN FUNCTIONS:" -ForegroundColor Cyan

    $modulesList = @()

    if ($isInMemory) {
        # Fetch file list dynamically via GitHub REST API
        $apiUrl = "https://api.github.com/repos/$githubUser/$githubRepo/contents/SysAdmin-Functions?ref=$branch"
        try {
            $apiResponse = Invoke-RestMethod -Uri $apiUrl -Headers @{ "User-Agent" = "PowerShell-SysAdmin-Tools" } -ErrorAction Stop
            $remoteFiles = $apiResponse | Where-Object { $_.name -like "*.ps1" } | Sort-Object name

            foreach ($file in $remoteFiles) {
                $modulesList += [PSCustomObject]@{
                    Name = ($file.name -replace '\.ps1$', '')
                    Type = "Remote"
                    Url  = $file.download_url
                }
            }
        } catch {
            Write-Host "[!] Error fetching module directory from GitHub API: $_" -ForegroundColor Red
        }
    } else {
        # Scan local SysAdmin-Functions directory
        if (Test-Path $localFunctionsDir) {
            $localFiles = Get-ChildItem -Path $localFunctionsDir -Filter "*.ps1" -ErrorAction SilentlyContinue | Sort-Object Name
            foreach ($file in $localFiles) {
                $modulesList += [PSCustomObject]@{
                    Name = $file.BaseName
                    Type = "Local"
                    Path = $file.FullName
                }
            }
        }
    }

    # Render Menu
    if (-not $modulesList -or $modulesList.Count -eq 0) {
        Write-Host "[!] No function scripts (.ps1) found." -ForegroundColor Red
        Write-Host "  0. Exit Application" -ForegroundColor Gray
    } else {
        for ($i = 0; $i -lt $modulesList.Count; $i++) {
            Write-Host "  $($i + 1). $($modulesList[$i].Name)" -ForegroundColor White
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

    if ($selection -match '^\d+$' -and [int]$selection -le $modulesList.Count -and [int]$selection -gt 0) {
        $selectedModule = $modulesList[[int]$selection - 1]
        Write-Host ""
        Write-Host ">>> Executing Module: $($selectedModule.Name) <<<" -ForegroundColor Green
        
        if ($selectedModule.Type -eq "Remote") {
            try {
                # Fetch code straight to RAM and execute
                $scriptContent = Invoke-RestMethod -Uri $selectedModule.Url -ErrorAction Stop
                Invoke-Expression $scriptContent
            } catch {
                Write-Host "[!] Error fetching module from GitHub Raw: $_" -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        } else {
            & $selectedModule.Path
        }
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