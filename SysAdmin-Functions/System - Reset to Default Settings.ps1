# Module File: SysAdmin-Functions/Restore System Defaults.ps1
# Description: Restores Windows System Defaults (UAC, Network Firewall, Print Spooler, Hosts file)
# Author     : Designed by trungtdv4@gmail.com. All Rights Reserved.

Clear-Host
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host "         RESTORE WINDOWS DEFAULT SETTINGS           " -ForegroundColor Cyan
Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
Write-Host "====================================================" -ForegroundColor Cyan
Write-Host ""

function Test-IsAdmin {
    $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object System.Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-IsAdmin)) {
    Write-Host "[!] ERROR: Restoring system defaults requires Administrator privileges." -ForegroundColor Red
    Write-Host "    Please run the application as Administrator." -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "Press ENTER to return to main menu..." -ForegroundColor Gray
    Read-Host | Out-Null
    return
}

while ($true) {
    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host "SELECT SYSTEM DEFAULTS TO RESTORE:" -ForegroundColor Yellow
    Write-Host "  1. Restore UAC (User Account Control) to Windows Default (Prompt Yes/No)" -ForegroundColor White
    Write-Host "  2. Restore Windows Firewall to Default Rules" -ForegroundColor White
    Write-Host "  3. Restore Hosts File to Default" -ForegroundColor White
    Write-Host "  4. Restore Windows Update Services & Policies to Default" -ForegroundColor White
    Write-Host "  9. RESTORE ALL ABOVE DEFAULTS AT ONCE" -ForegroundColor Green
    Write-Host "  0. Return to Main Menu" -ForegroundColor Gray
    Write-Host "----------------------------------------------------" -ForegroundColor Cyan
    Write-Host ""

    $choice = Read-Host "Select an option number"

    if ($choice -eq '0') { break }

    switch ($choice) {
        "1" {
            Write-Host ""
            Write-Host "[+] Restoring UAC (User Account Control) Registry settings..." -ForegroundColor Yellow
            try {
                $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
                
                # EnableLUA = 1 (Bật UAC)
                Set-ItemProperty -Path $uacPath -Name "EnableLUA" -Value 1 -Force
                # ConsentPromptBehaviorAdmin = 5 (Prompt for consent for non-Windows binaries - Mặc định hiện Yes/No)
                Set-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 5 -Force
                # PromptOnSecureDesktop = 1 (Làm tối màn hình khi hỏi Yes/No)
                Set-ItemProperty -Path $uacPath -Name "PromptOnSecureDesktop" -Value 1 -Force
                # ConsentPromptBehaviorUser = 3 (Nhập credential nếu là user thường)
                Set-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorUser" -Value 3 -Force

                Write-Host "  [V] UAC has been restored to Microsoft Default!" -ForegroundColor Green
                Write-Host "      (Note: A computer restart is required for UAC changes to fully apply)" -ForegroundColor DarkGray
            } catch {
                Write-Host "  [!] Failed to restore UAC: $_" -ForegroundColor Red
            }
        }
        "2" {
            Write-Host ""
            Write-Host "[+] Restoring Windows Defender Firewall to default state..." -ForegroundColor Yellow
            try {
                netsh advfirewall reset | Out-Null
                Write-Host "  [V] Windows Firewall rules reset to factory defaults!" -ForegroundColor Green
            } catch {
                Write-Host "  [!] Failed to reset Firewall: $_" -ForegroundColor Red
            }
        }
        "3" {
            Write-Host ""
            Write-Host "[+] Restoring system Hosts file to Microsoft default..." -ForegroundColor Yellow
            try {
                $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
                $defaultHosts = @"
# Copyright (c) 1993-2009 Microsoft Corp.
#
# This is a sample HOSTS file used by Microsoft TCP/IP for Windows.
#
# This file contains the mappings of IP addresses to host names. Each
# entry should be kept on an individual line. The IP address should
# be placed in the first column followed by the corresponding host name.
# The IP address and the host name should be separated by at least one
# space.
#
# Additionally, comments (such as these) may be inserted on individual
# lines or following the machine name denoted by a '#' symbol.
#
# For example:
#
#      102.54.94.97     rhino.acme.com          # source server
#       38.25.63.10     x.acme.com              # x client host

# localhost name resolution is handled within DNS itself.
#	127.0.0.1       localhost
#	::1             localhost
"@
                Set-Content -Path $hostsPath -Value $defaultHosts -Force
                Write-Host "  [V] Hosts file successfully reset!" -ForegroundColor Green
            } catch {
                Write-Host "  [!] Failed to reset Hosts file: $_" -ForegroundColor Red
            }
        }
        "4" {
            Write-Host ""
            Write-Host "[+] Resetting Windows Update Services and Policies..." -ForegroundColor Yellow
            try {
                Stop-Service -Name wuauserv, bits -ErrorAction SilentlyContinue
                Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name * -ErrorAction SilentlyContinue
                Start-Service -Name wuauserv, bits -ErrorAction SilentlyContinue
                Write-Host "  [V] Windows Update policies reset to defaults!" -ForegroundColor Green
            } catch {
                Write-Host "  [!] Notice: Windows Update resync completed with warnings." -ForegroundColor Yellow
            }
        }
        "9" {
            Write-Host ""
            Write-Host "[+] Restoring ALL system defaults..." -ForegroundColor Yellow
            
            # 1. UAC
            $uacPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
            Set-ItemProperty -Path $uacPath -Name "EnableLUA" -Value 1 -Force
            Set-ItemProperty -Path $uacPath -Name "ConsentPromptBehaviorAdmin" -Value 5 -Force
            Set-ItemProperty -Path $uacPath -Name "PromptOnSecureDesktop" -Value 1 -Force

            # 2. Firewall
            netsh advfirewall reset | Out-Null

            # 3. Hosts
            $hostsPath = "$env:SystemRoot\System32\drivers\etc\hosts"
            $defaultHosts = "# Default Hosts File`n127.0.0.1 localhost`n::1 localhost"
            Set-Content -Path $hostsPath -Value $defaultHosts -Force

            Write-Host "  [V] All core Windows defaults have been successfully restored!" -ForegroundColor Green
        }
        Default {
            Write-Host "[!] Invalid selection. Please try again." -ForegroundColor Red
        }
    }

    Write-Host ""
    Write-Host "Press ENTER to continue..." -ForegroundColor Gray
    Read-Host | Out-Null
    Clear-Host
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host "         RESTORE WINDOWS DEFAULT SETTINGS           " -ForegroundColor Cyan
    Write-Host "  Designed by trungtdv4@gmail.com. All Rights Reserved. " -ForegroundColor DarkGray
    Write-Host "====================================================" -ForegroundColor Cyan
    Write-Host ""
}