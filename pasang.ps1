# ===========================================================================
#  PEMASANG SATU PERINTAH — Windows (PowerShell)
#
#  Cara pakai (buka PowerShell sebagai Administrator, tempel SATU baris ini):
#
#    irm https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/pasang.ps1 | iex
#
#  Skrip ini memasang Ubuntu (WSL2), lalu menjalankan pemasang lengkap
#  di dalamnya, lalu mengatur agar hidup sendiri saat komputer menyala.
# ===========================================================================

$ErrorActionPreference = "Stop"

$Repo = "https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main"

function Tulis($teks, $warna = "White") { Write-Host $teks -ForegroundColor $warna }

Tulis ""
Tulis "  ┌─────────────────────────────────────────────────────────┐" Cyan
Tulis "  │   PEMASANG AI AGENT — WINDOWS                           │" Cyan
Tulis "  └─────────────────────────────────────────────────────────┘" Cyan
Tulis ""
Tulis "  Butuh 20-40 menit. Bisa ditinggal." Yellow
Tulis ""

# --- 1. Pastikan Administrator -------------------------------------------
$id = [Security.Principal.WindowsIdentity]::GetCurrent()
$prinsip = New-Object Security.Principal.WindowsPrincipal($id)
if (-not $prinsip.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Tulis "  ✗ Harus dijalankan sebagai Administrator." Red
    Tulis ""
    Tulis "  Cara: klik kanan 'Windows PowerShell' → 'Run as administrator'" Yellow
    Tulis "  Lalu tempel lagi perintahnya."
    exit 1
}
Tulis "  ✓ Akses Administrator OK" Green

# --- 2. Pastikan Windows 10/11 -------------------------------------------
$versi = [System.Environment]::OSVersion.Version
if ($versi.Major -lt 10) {
    Tulis "  ✗ Perlu Windows 10 atau 11." Red
    exit 1
}
Tulis "  ✓ Windows $($versi.Major) terdeteksi" Green

# --- 3. Pasang WSL2 + Ubuntu ---------------------------------------------
Tulis ""
Tulis "  Memasang Ubuntu (WSL2)..." Yellow

$wslAda = $false
try {
    $keluar = wsl --status 2>&1
    if ($LASTEXITCODE -eq 0) { $wslAda = $true }
} catch { $wslAda = $false }

if (-not $wslAda) {
    Tulis "  Mengaktifkan fitur WSL..." Yellow
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
    Tulis "  ⚠ Perlu RESTART komputer sekali." Yellow
    Tulis ""
    Tulis "  Setelah nyala lagi, jalankan perintah ini sekali lagi." Yellow
    Tulis ""
    $jwb = Read-Host "  Restart sekarang? (y/n)"
    if ($jwb -eq "y") { Restart-Computer }
    exit 0
}
Tulis "  ✓ WSL sudah ada" Green

# Pastikan Ubuntu terpasang
$distro = (wsl --list --quiet 2>&1) -join " "
if ($distro -notmatch "Ubuntu") {
    Tulis "  Memasang Ubuntu..." Yellow
    wsl --install -d Ubuntu --no-launch 2>&1 | Out-Null
    Start-Sleep -Seconds 5
}

# Pastikan WSL2
wsl --set-default-version 2 2>&1 | Out-Null
Tulis "  ✓ Ubuntu siap" Green

# --- 4. Jalankan pemasang di dalam Ubuntu --------------------------------
Tulis ""
Tulis "  ┌─────────────────────────────────────────────────────────┐" Cyan
Tulis "  │   MEMULAI PEMASANGAN DI DALAM UBUNTU                    │" Cyan
Tulis "  └─────────────────────────────────────────────────────────┘" Cyan
Tulis ""
Tulis "  Kalau Ubuntu baru dipasang, Anda akan diminta membuat" Yellow
Tulis "  nama pengguna dan kata sandi. Ingat kata sandinya." Yellow
Tulis ""

$perintah = "curl -fsSL $Repo/pasang.sh | bash"

# Buat pengguna otomatis kalau belum ada (hindari prompt)
wsl -d Ubuntu -u root -- bash -lc "id -u hermes >/dev/null 2>&1 || useradd -m -s /bin/bash hermes; echo 'hermes ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/hermes; chmod 0440 /etc/sudoers.d/hermes" 2>&1 | Out-Null

# Jalankan sebagai root supaya tidak ada prompt sama sekali
wsl -d Ubuntu -u root -- bash -lc "export HOME=/root; $perintah"

# --- 5. Autostart lewat Task Scheduler ----------------------------------
Tulis ""
Tulis "  Mengatur agar hidup sendiri saat komputer menyala..." Yellow

$aksi = New-ScheduledTaskAction -Execute "wsl.exe" `
    -Argument "-d Ubuntu -u root -- bash -lc 'cd /root && nohup bash -c \"sleep 20; systemctl start hermes-gateway 2>/dev/null || service hermes-gateway start 2>/dev/null || true\" >/dev/null 2>&1 &'"

$picu = New-ScheduledTaskTrigger -AtStartup
$setelan = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries -StartWhenAvailable -RestartCount 3 -RestartInterval (New-TimeSpan -Minutes 1)
$prinsipal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest

try {
    Unregister-ScheduledTask -TaskName "Hermes Agent Autostart" -Confirm:$false -ErrorAction SilentlyContinue
    Register-ScheduledTask -TaskName "Hermes Agent Autostart" `
        -Action $aksi -Trigger $picu -Settings $setelan -Principal $prinsipal `
        -Description "Menjalankan AI Agent Hermes otomatis saat komputer menyala" | Out-Null
    Tulis "  ✓ Hidup sendiri saat komputer nyala" Green
} catch {
    Tulis "  ⚠ Autostart gagal diatur — jalankan manual nanti" Yellow
}

# --- 6. Selesai ----------------------------------------------------------
Tulis ""
Tulis "  ┌─────────────────────────────────────────────────────────┐" Green
Tulis "  │   SELESAI                                               │" Green
Tulis "  └─────────────────────────────────────────────────────────┘" Green
Tulis ""
Tulis "  Ubuntu + AI Agent sudah terpasang di komputer ini."
Tulis ""
Tulis "  Untuk membukanya nanti:" Cyan
Tulis "    1. Buka 'Ubuntu' dari Start Menu"
Tulis "    2. Ketik:  hermes"
Tulis ""
Tulis "  Kalau bingung, hubungi teknisi Anda." Yellow
Tulis ""
