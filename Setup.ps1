# ==============================================================================
# File: Setup.ps1 (Remote Entry Point / Loader)
# Author: Designed by trungtdv4@gmail.com. All Rights Reserved.
# ==============================================================================
$githubUser = "trungtdv4"   # Thay Username GitHub của anh
$githubRepo = "SysAdmin-Tools"         # Thay Tên Repository của anh
$branch     = "main"

$installDir = Join-Path $env:LOCALAPPDATA "SysAdmin-Tools-App"
$zipPath    = Join-Path $env:TEMP "sysadmin-tools.zip"
$zipUrl     = "https://github.com/$githubUser/$githubRepo/archive/refs/heads/$branch.zip"

Clear-Host
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "             SYSADMIN TOOLS - SETUP LOADER              " -ForegroundColor Cyan
Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor Yellow
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[+] Downloading application package from GitHub..." -ForegroundColor Yellow
try {
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -ErrorAction Stop
    Write-Host "[V] Download completed!" -ForegroundColor Green
} catch {
    Write-Error "[!] Failed to download repository package. Please check your GitHub URL."
    Exit
}

if (Test-Path $installDir) { Remove-Item -Path $installDir -Recurse -Force }

Write-Host "[+] Extracting files to Local AppData..." -ForegroundColor Yellow
Expand-Archive -Path $zipPath -DestinationPath $env:TEMP -Force

$extractedFolder = Join-Path $env:TEMP "$githubRepo-$branch"
if (Test-Path $extractedFolder) {
    Move-Item -Path $extractedFolder -Destination $installDir -Force
    Remove-Item -Path $zipPath -Force -ErrorAction SilentlyContinue
    Write-Host "[V] Application extracted successfully!" -ForegroundColor Green
} else {
    Write-Error "[!] Extraction failed."
    Exit
}

# Launch Bootstrapper.bat
$batPath = Join-Path $installDir "Bootstrapper.bat"
if (Test-Path $batPath) {
    Write-Host ""
    Write-Host ">>> Launching Bootstrapper.bat in new window... <<<" -ForegroundColor Cyan
    Start-Sleep -Seconds 1
    Start-Process -FilePath $batPath -WorkingDirectory $installDir
    
    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "[V] Setup finished! Application launched." -ForegroundColor Green
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host ""
    
    $null = Read-Host "Press ENTER to exit this Loader window"
    Exit
} else {
    Write-Error "[!] Cannot find 'Bootstrapper.bat'!"
}