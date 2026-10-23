<# :
@cls
@echo off
title Xoa lenh in ket va Fix may in Offline - Windows

:: Kiem tra va yeu cau quyen Administrator
net session >nul 2>&1
if %errorLevel% neq 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

:: Tạo file ps1 tam thoi trong thu muc Temp
set "ps1_temp=%temp%\printer_fix_%random%.ps1"
copy /y "%~f0" "%ps1_temp%" >nul

:: Thuc thi file ps1 qua bo doc mac dinh cua PowerShell
powershell -NoProfile -ExecutionPolicy Bypass -File "%ps1_temp%"

:: Don dep file tam
del "%ps1_temp%" >nul 2>&1
pause
exit /b
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host "   DANG FIX LOI KET LENH IN VA MAY IN OFFLINE..." -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Dung Service Print Spooler va xoa toan bo file in ket trong thu muc Spool
try {
    Write-Host "[1/3] Dang dung Service Print Spooler va xoa file in ket... " -NoNewline
    Stop-Service -Name "Spooler" -Force -ErrorAction Stop
    
    $spoolPath = "$env:SystemRoot\System32\spool\PRINTERS\*"
    Get-ChildItem -Path $spoolPath -Force -Recurse -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
    
    Write-Host "[Thanh cong]" -ForegroundColor Green
} catch {
    Write-Host "[That bai]" -ForegroundColor Red
}

# 2. Khoi dong lai Service Print Spooler
try {
    Write-Host "[2/3] Dang khoi dong lai Service Print Spooler... " -NoNewline
    Start-Service -Name "Spooler" -ErrorAction Stop
    Write-Host "[Thanh cong]" -ForegroundColor Green
} catch {
    Write-Host "[That bai]" -ForegroundColor Red
}

# 3. Huy che do "Use Printer Offline" tren tat ca cac may in
Write-Host "[3/3] Dang chuyen tat ca may in sang trang thai Online..." -ForegroundColor Yellow

try {
    # Cach 1: Dung Cmdlet Set-Printer
    if (Get-Command Set-Printer -ErrorAction SilentlyContinue) {
        Get-Printer | ForEach-Object {
            Write-Host "   -> Dang xu ly may in: $($_.Name)" -ForegroundColor Cyan
            Set-Printer -Name $_.Name -WorkOffline $false -ErrorAction SilentlyContinue
        }
    }

    # Cach 2: Dung WMI Fallback cap nhat thuoc tinh WorkOffline qua lop Win32_Printer
    $wmiPrinters = Get-WmiObject -Class Win32_Printer -ErrorAction SilentlyContinue
    foreach ($p in $wmiPrinters) {
        if ($p.WorkOffline -eq $true) {
            $p.WorkOffline = $false
            $null = $p.Put()
        }
    }
    Write-Host "   -> Da chuyen toan bo may in ve trang thai Online hoan tat." -ForegroundColor Green
} catch {
    Write-Host "   -> Co loi khi cap nhat trang thai Offline cua may in." -ForegroundColor Red
}

Write-Host ""
Write-Host "=========================================================" -ForegroundColor Green
Write-Host "   HOAN TAT XU LY KET LENH IN VA FIX MAY IN OFFLINE!" -ForegroundColor Green
Write-Host "=========================================================" -ForegroundColor Green
Write-Host ""