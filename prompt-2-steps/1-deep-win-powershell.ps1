# ============================================================================
# 1-deep-win-powershell.ps1 — LANGKAH 1 (Windows): SSH + Tailscale + Docker
# ============================================================================
# Jalankan di PowerShell:
#   irm https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/1-deep-win-powershell.ps1 | iex
#
# Tanpa Administrator, script menaikkan diri sendiri lewat UAC (mengunduh ulang
# dirinya di sesi elevated).
#
# Perbaikan dibanding versi satu-baris sebelumnya:
#   - exit code winget DIPERIKSA (dulu gagal tapi dianggap sukses)
#   - user yang sudah ada TIDAK direset passwordnya
#   - PATH disusun tanpa literal titik-koma di dalam string
#   - setiap langkah berstatus OK/GAGAL + ringkasan di akhir
#   - exit code dikembalikan (0 sukses, 1 ada masalah)
# ============================================================================

$ErrorActionPreference = "Continue"

$SRC      = "https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/1-deep-win-powershell.ps1"
$TS_KEY   = "tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd"
$SSH_USER = "tommy"
$SSH_PASS = "tommY88vevE91@c"

# ---------------------------------------------------------------- naikkan hak
$isAdmin = $false
try {
    $ident = [Security.Principal.WindowsIdentity]::GetCurrent()
    $princ = New-Object Security.Principal.WindowsPrincipal($ident)
    $isAdmin = $princ.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
} catch {
    Write-Host "[GAGAL] tidak bisa memeriksa hak Administrator: $($_.Exception.Message)"
}

if (-not $isAdmin) {
    Write-Host "Butuh Administrator. Membuka jendela UAC..."
    $argList = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", "irm $SRC | iex")
    try {
        $proc = Start-Process powershell -Verb RunAs -Wait -PassThru -ArgumentList $argList
        if ($proc.ExitCode -ne 0) {
            Write-Host "[GAGAL] proses elevated keluar dengan kode $($proc.ExitCode)."
        } else {
            Write-Host "[OK] selesai di sesi elevated."
        }
    } catch {
        Write-Host "[GAGAL] UAC dibatalkan atau gagal: $($_.Exception.Message)"
    }
    return
}

# ---------------------------------------------------------------- util
$script:Masalah = New-Object System.Collections.ArrayList

function Ok($m)   { Write-Host "[OK]    $m" }
function Bad($m)  { [void]$script:Masalah.Add($m); Write-Host "[GAGAL] $m" }
function Info($m) { Write-Host "[..]    $m" }

# jalankan executable, kembalikan $true kalau exit code 0
function Jalankan($exe, $argumen, $label) {
    Info "menjalankan: $exe $($argumen -join ' ')"
    $keluaran = & $exe @argumen 2>&1
    $kode = $LASTEXITCODE
    if ($null -eq $kode) { $kode = 0 }
    if ($kode -ne 0) {
        Bad "$label gagal (exit $kode)"
        if ($keluaran) { Write-Host (($keluaran | Out-String).Trim()) }
        return $false
    }
    Ok $label
    return $true
}

Write-Host ""
Write-Host "=== LANGKAH 1 (Windows): SSH + Tailscale + Docker ==="
Write-Host ""

# ---------------------------------------------------------------- 1. OpenSSH
$sshSudah = $false
try {
    $kondisi = Get-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop
    if ($kondisi.State -eq "Installed") { $sshSudah = $true }
} catch {
    Info "status OpenSSH tidak terbaca, tetap dicoba pasang"
}

if ($sshSudah) {
    Ok "OpenSSH Server sudah terpasang"
} else {
    Info "memasang OpenSSH Server..."
    try {
        $cap = Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction Stop
        Ok "OpenSSH Server terpasang (perlu restart: $($cap.RestartNeeded))"
    } catch {
        Bad "OpenSSH Server: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------- 2. service sshd
try {
    Set-Service -Name sshd -StartupType Automatic -ErrorAction Stop
    Start-Service -Name sshd -ErrorAction Stop
    Ok "service sshd: automatic + berjalan"
} catch {
    Bad "service sshd: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- 3. user SSH
$userAda = $false
try {
    $akun = Get-LocalUser -Name $SSH_USER -ErrorAction SilentlyContinue
    if ($akun) { $userAda = $true }
} catch {
    Info "Get-LocalUser tidak tersedia, memakai net user"
}

if ($userAda) {
    Ok "user $SSH_USER sudah ada - password TIDAK diubah"
} else {
    $null = net user $SSH_USER $SSH_PASS /add 2>&1
    if ($LASTEXITCODE -eq 0) {
        Ok "user $SSH_USER dibuat"
    } else {
        Bad "gagal membuat user $SSH_USER (exit $LASTEXITCODE)"
    }
}

$null = net localgroup Administrators $SSH_USER /add 2>&1
if ($LASTEXITCODE -eq 0) {
    Ok "$SSH_USER masuk grup Administrators"
} elseif ($LASTEXITCODE -eq 1378) {
    Ok "$SSH_USER sudah anggota Administrators"
} else {
    Bad "gagal menambah $SSH_USER ke Administrators (exit $LASTEXITCODE)"
}

# ---------------------------------------------------------------- 4. firewall
try {
    Set-NetFirewallRule -Name OpenSSH-Server-In-TCP -Profile Any -Enabled True -ErrorAction Stop
    Ok "firewall: port 22 dibuka"
} catch {
    Bad "firewall: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- 5. Tailscale
$tsExe = Join-Path $env:ProgramFiles "Tailscale\tailscale.exe"
if (Test-Path $tsExe) {
    Ok "Tailscale sudah terpasang"
    $tsy = $true
} else {
    $tsy = Jalankan "winget" @(
        "install", "--id", "tailscale.tailscale", "-e",
        "--source", "winget",
        "--accept-package-agreements", "--accept-source-agreements",
        "--disable-interactivity"
    ) "winget tailscale"
}

if ($tsy) {
    try {
        Set-Service -Name Tailscale -StartupType Automatic -ErrorAction Stop
        Start-Service -Name Tailscale -ErrorAction SilentlyContinue
        Ok "service Tailscale: automatic"
    } catch {
        Bad "service Tailscale: $($_.Exception.Message)"
    }

    if (Test-Path $tsExe) {
        $null = Jalankan $tsExe @(
            "up", "--unattended",
            "--auth-key=$TS_KEY",
            "--advertise-tags=tag:dipasangintsl"
        ) "tailscale up"
    } else {
        Bad "tailscale.exe tidak ditemukan di $tsExe"
    }
}

# ---------------------------------------------------------------- 6. Docker
$dd = Join-Path $env:ProgramFiles "Docker\Docker\Docker Desktop.exe"
if (Test-Path $dd) {
    Ok "Docker Desktop sudah terpasang"
    $dok = $true
} else {
    $dok = Jalankan "winget" @(
        "install", "--id", "Docker.DockerDesktop", "-e",
        "--source", "winget",
        "--accept-package-agreements", "--accept-source-agreements",
        "--disable-interactivity"
    ) "winget Docker Desktop"
}

if ($dok) {
    try {
        Set-Service -Name com.docker.service -StartupType Automatic -ErrorAction Stop
        Ok "service com.docker.service: automatic"
    } catch {
        Bad "service com.docker.service: $($_.Exception.Message)"
    }

    if (Test-Path $dd) {
        try {
            $null = Start-Process $dd -ErrorAction Stop
            Ok "Docker Desktop dijalankan"
        } catch {
            Bad "Docker Desktop: $($_.Exception.Message)"
        }
    } else {
        Bad "Docker Desktop.exe tidak ditemukan di $dd"
    }
    Info "Docker Desktop biasanya butuh logout/login sekali agar grup docker aktif"
}

# ---------------------------------------------------------------- 7. refresh PATH
try {
    $mesin    = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $pengguna = [Environment]::GetEnvironmentVariable("Path", "User")
    $pemisah  = [IO.Path]::PathSeparator
    $env:Path = $mesin + $pemisah + $pengguna
    Ok "PATH sesi ini disegarkan"
} catch {
    Bad "refresh PATH: $($_.Exception.Message)"
}

# ---------------------------------------------------------------- 8. ringkasan
Write-Host ""
if ($script:Masalah.Count -gt 0) {
    Write-Host "=== SELESAI DENGAN $($script:Masalah.Count) MASALAH ==="
    foreach ($m in $script:Masalah) { Write-Host "  - $m" }
    Write-Host ""
    Write-Host "Cara cek manual:"
    Write-Host "  Get-Service sshd,Tailscale,com.docker.service"
    Write-Host "  tailscale status"
    $host.SetShouldExit(1)
    $global:LASTEXITCODE = 1
} else {
    Write-Host "=== SELESAI TANPA MASALAH ==="
    Write-Host "  SSH      : ssh $SSH_USER@<nama-server>"
    Write-Host "  Tailscale: tailscale status"
    Write-Host "  Docker   : buka Docker Desktop, tunggu sampai hijau"
    $host.SetShouldExit(0)
    $global:LASTEXITCODE = 0
}
