# ==============================================================================
# Script Name: Docker (include WSL 2).ps1
# ==============================================================================
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Function Invoke-DockerAndWSL2Setup {
    Write-Host "==================================================================================" -ForegroundColor Cyan
    Write-Host "                 DOCKER DESKTOP & WSL 2 AUTOMATED INSTALLER                       " -ForegroundColor Cyan
    Write-Host "  Copyright (c) 2026 Trung Nguyen (trungnm.work@gmail.com). All rights reserved.  " -ForegroundColor Cyan
    Write-Host "==================================================================================" -ForegroundColor Cyan

    # 1. KIỂM TRA QUYỀN ADMINISTRATOR
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    If (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Write-Host "`n[!] Loi: Script yeu cau quyen Administrator de cai dat WSL 2 va Docker!" -ForegroundColor Red
        Return
    }

    # 2. KIỂM TRA TRẠNG THÁI WSL 2 VÀ DOCKER HIỆN TẠI
    Write-Host "`n[1/4] Dang kiem tra trang thai WSL 2 va Docker tren he thong..." -ForegroundColor Yellow

    $HasWSL = $False
    $HasDocker = $False

    # Kiem tra WSL
    Try {
        $WslCheck = wsl --status 2>&1
        If ($LASTEXITCODE -eq 0) {
            $HasWSL = $True
            Write-Host "   -> WSL: Da duoc cai dat." -ForegroundColor Green
        } Else {
            Write-Host "   -> WSL: Chua cai dat hoac chua kich hoat." -ForegroundColor DarkYellow
        }
    } Catch {
        Write-Host "   -> WSL: Chua cai dat." -ForegroundColor DarkYellow
    }

    # Kiem tra Docker
    Try {
        $DockerVerCheck = docker --version 2>&1
        If ($LASTEXITCODE -eq 0) {
            $HasDocker = $True
            Write-Host "   -> Docker: Da duoc cai dat ($DockerVerCheck)." -ForegroundColor Green
        } Else {
            Write-Host "   -> Docker: Chua cai dat." -ForegroundColor DarkYellow
        }
    } Catch {
        Write-Host "   -> Docker: Chua cai dat." -ForegroundColor DarkYellow
    }

    # Neu ca 2 da cai dat thi thong bao va ket thuc function de quay ve menu cha
    If ($HasWSL -and $HasDocker) {
        Write-Host "`n======================================================================" -ForegroundColor Green
        Write-Host " HE THONG DA SAN SANG! Ca WSL 2 va Docker deu da duoc cai dat tu truoc." -ForegroundColor Green
        Write-Host "======================================================================" -ForegroundColor Green
        Return
    }

    # 3. CÀI ĐẶT WSL 2 BẰNG LỆNH NATIVE CỦA WINDOWS (KHÔNG CÀI KÈM DISTRO)
    Write-Host "`n[2/4] Dang xu ly kich hoat va cai dat loi WSL 2..." -ForegroundColor Yellow
    If (-not $HasWSL) {
        wsl --install --no-distribution
        If ($LASTEXITCODE -eq 0) {
            wsl --set-default-version 2 2>$null
            Write-Host "   -> Cai dat loi WSL 2 thanh cong!" -ForegroundColor Green
        } Else {
            Write-Host "   [!] Canh bao: Qua trinh cai WSL tra ve ma loi ($LASTEXITCODE). He thong co the can khoi dong lai." -ForegroundColor DarkYellow
        }
    } Else {
        Write-Host "   -> Bo qua buoc nay vi WSL da ton tai." -ForegroundColor Gray
    }

    # 4. CÀI ĐẶT DOCKER DESKTOP QUA WINGET (NẾU CHƯA CÓ)
    Write-Host "`n[3/4] Dang xu ly cai dat Docker Desktop qua WinGet..." -ForegroundColor Yellow
    If (-not $HasDocker) {
        winget install --id Docker.DockerDesktop -e --silent --accept-package-agreements --accept-source-agreements
        If ($LASTEXITCODE -eq 0) {
            Write-Host "   -> Cai dat Docker Desktop thanh cong!" -ForegroundColor Green
        } Else {
            Write-Host "   [!] Loi: Khong the cai dat Docker Desktop qua WinGet (Ma loi: $LASTEXITCODE)." -ForegroundColor Red
            Return
        }
    } Else {
        Write-Host "   -> Bo qua buoc nay vi Docker da ton tai." -ForegroundColor Gray
    }

    # Cap nhat lai bien moi truong PATH cho phien PowerShell hien tai de nhan dien lenh docker/wsl ngay lap tuc
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    # 5. KIỂM TRA LẠI WSL --STATUS, DOCKER --VERSION VÀ DOCKER INFO
    Write-Host "`n[4/4] Dang kiem tra lai he thong sau khi cai dat..." -ForegroundColor Yellow

    Write-Host "`n--- [Kiem tra: wsl --status] ---" -ForegroundColor Cyan
    Try {
        wsl --status
    } Catch {
        Write-Host "Chua the truy xuat wsl --status (Yeu cau khoi dong lai Windows)." -ForegroundColor DarkYellow
    }

    Write-Host "`n--- [Kiem tra: docker --version] ---" -ForegroundColor Cyan
    Try {
        docker --version
    } Catch {
        Write-Host "Khong tim thay lenh docker trong PATH hien tai." -ForegroundColor Red
    }

    Write-Host "`n--- [Kiem tra: docker info] ---" -ForegroundColor Cyan
    # Thu khoi chay Docker Desktop neu chua chay
    $DockerDesktopExe = "$env:ProgramFiles\Docker\Docker\Docker Desktop.exe"
    If ((Test-Path $DockerDesktopExe) -and (-not (Get-Process "Docker Desktop" -ErrorAction SilentlyContinue))) {
        Write-Host "Dang khoi dong Docker Desktop Engine (vui long cho 15 giay)..." -ForegroundColor DarkGray
        Start-Process -FilePath $DockerDesktopExe
        Start-Sleep -Seconds 15
    }

    Try {
        docker info
    } Catch {
        Write-Host "[!] Docker Engine chua san sang. Vui long khoi dong lai Windows de hoan tat cau hinh WSL 2." -ForegroundColor DarkYellow
    }

    Write-Host "`n======================================================================" -ForegroundColor Green
    Write-Host " HOAN TAT QUA TRINH CAI DAT! Neu WSL 2 vua duoc cai lan dau, hay Restart may roi check lai!." -ForegroundColor Green
    Write-Host "======================================================================" -ForegroundColor Green
}

# Thuc thi ham chinh
Invoke-DockerAndWSL2Setup