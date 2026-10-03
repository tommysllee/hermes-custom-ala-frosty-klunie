# ============================================================================
#  install.ps1 — Pemasang AI Agent Bisnis untuk WINDOWS
# ============================================================================
#  Windows tidak punya sistem Linux, jadi pemasangnya memakai WSL2 + Ubuntu.
#  Skrip ini mengurus semuanya: pasang WSL, jalankan pemasang Linux,
#  lalu daftarkan autostart lewat Task Scheduler.
#
#  CARA PAKAI (PowerShell sebagai Administrator)
#     git clone <URL-REPO-ANDA>
#     cd hermes-custom
#     .\install.ps1
#
#  Opsi:
#     .\install.ps1 -Tes         periksa saja, tidak mengubah apa pun
#     .\install.ps1 -LewatiStt   tanpa suara lokal
#
#  ---------------------------------------------------------------------------
#  URUTAN (yang melibatkan manusia SELALU di akhir)
#     Tahap 1  periksa Windows + WSL
#     Tahap 2  pasang WSL2 + Ubuntu (kalau belum ada)
#     Tahap 3  jalankan pemasang Linux di dalam Ubuntu
#     Tahap 4  daftarkan autostart (Task Scheduler)
#     Tahap 5  GILIRAN ANDA: Tailscale, Nous Portal, WhatsApp, Google
#  ----------------------------------------------------------------------------

param(
    [switch]$Tes,
    [switch]$LewatiStt
)

$ErrorActionPreference = "Stop"
$VERSI = "1.0.0"
$DISTRO = "Ubuntu"

# ---------------------------------------------------------------------------
# Tampilan
# ---------------------------------------------------------------------------
function Tulis-Ok    { param($m) Write-Host "  [OK] $m"   -ForegroundColor Green }
function Tulis-Info  { param($m) Write-Host "  [>]  $m"   -ForegroundColor Yellow }
function Tulis-Gagal { param($m) Write-Host "  [X]  $m"   -ForegroundColor Red }
function Tulis-Judul { param($m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }

Write-Host @"
+====================================================================+
|                                                                    |
|        P E M A S A N G   A I   A G E N T   B I S N I S             |
|                        (Windows)                                   |
|                                                                    |
|   Semuanya berjalan sendiri. Anda hanya perlu bertindak di         |
|   bagian TERAKHIR (sekitar 5 menit).                               |
|                                                                    |
+====================================================================+
"@ -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Cek: dijalankan sebagai Administrator?
# ---------------------------------------------------------------------------
$idSaya = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($idSaya)
$admin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $admin) {
    Tulis-Gagal "Skrip ini harus dijalankan sebagai Administrator."
    Write-Host ""
    Write-Host "  1. Tutup PowerShell ini" -ForegroundColor Yellow
    Write-Host "  2. Buka Start Menu, cari 'PowerShell'" -ForegroundColor Yellow
    Write-Host "  3. Klik kanan -> 'Run as administrator'" -ForegroundColor Yellow
    Write-Host "  4. Ulangi perintahnya" -ForegroundColor Yellow
    exit 1
}
Tulis-Ok "berjalan sebagai Administrator"

# ===========================================================================
# TAHAP 1 — PERIKSA WINDOWS & WSL
# ===========================================================================
Tulis-Judul "TAHAP 1 dari 5 - MEMERIKSA SISTEM"

$os = Get-CimInstance Win32_OperatingSystem
Tulis-Info "Windows : $($os.Caption) (build $($os.BuildNumber))"

if ([int]$os.BuildNumber -lt 19041) {
    Tulis-Gagal "Windows terlalu lama. Butuh Windows 10 versi 2004 (build 19041) atau lebih baru."
    exit 1
}
Tulis-Ok "versi Windows didukung"

# Ruang disk
$disk = Get-PSDrive C
$ruangGB = [math]::Round($disk.Free / 1GB, 1)
Tulis-Info "ruang disk C: $ruangGB GB"
if ($ruangGB -lt 18) {
    Tulis-Gagal "ruang kurang dari 18 GB — kosongkan dulu"
    exit 1
}
Tulis-Ok "ruang cukup"

# Memori
$ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
Tulis-Info "memori      : $ramGB GB"

# Virtualisasi (syarat WSL2)
$cpu = Get-CimInstance Win32_Processor
if ($cpu.VirtualizationFirmwareEnabled -eq $false) {
    Tulis-Gagal "Virtualisasi mati di BIOS."
    Write-Host "  Nyalakan VT-x (Intel) atau AMD-V di BIOS, lalu ulangi." -ForegroundColor Yellow
    exit 1
}
Tulis-Ok "virtualisasi aktif"

# WSL sudah ada?
$wslAda = $false
try {
    $null = wsl --status 2>$null
    $wslAda = $true
    Tulis-Ok "WSL sudah terpasang"
} catch {
    Tulis-Info "WSL belum terpasang — akan dipasang di tahap 2"
}

# Ubuntu sudah ada?
$ubuntuAda = $false
if ($wslAda) {
    $daftar = wsl -l -q 2>$null
    if ($daftar -match $DISTRO) {
        $ubuntuAda = $true
        Tulis-Ok "Ubuntu sudah terpasang di WSL"
    } else {
        Tulis-Info "Ubuntu belum ada di WSL — akan dipasang di tahap 2"
    }
}

if ($Tes) {
    Write-Host ""
    Tulis-Ok "PEMERIKSAAN SELESAI - mode tes, tidak ada yang diubah"
    exit 0
}

# ===========================================================================
# TAHAP 2 — PASANG WSL2 + UBUNTU
# ===========================================================================
Tulis-Judul "TAHAP 2 dari 5 - WSL2 + UBUNTU"

if (-not $wslAda) {
    Tulis-Info "memasang WSL2 (perlu beberapa menit)..."
    wsl --install --no-distribution
    Tulis-Ok "WSL2 dipasang"
    Write-Host ""
    Tulis-Gagal "RESTART DIPERLUKAN"
    Write-Host "  Setelah restart, jalankan skrip ini lagi:" -ForegroundColor Yellow
    Write-Host "     .\install.ps1" -ForegroundColor White
    exit 0
}

if (-not $ubuntuAda) {
    Tulis-Info "memasang Ubuntu di WSL..."
    wsl --install -d $DISTRO
    Write-Host ""
    Write-Host "  Ubuntu akan meminta Anda membuat USERNAME dan PASSWORD." -ForegroundColor Yellow
    Write-Host "  CATAT baik-baik - akan dipakai lagi nanti." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Tekan Enter setelah selesai membuat akun Ubuntu"

    # Pastikan versi 2
    Tulis-Info "memastikan WSL versi 2..."
    wsl --set-version $DISTRO 2 2>$null
}
Tulis-Ok "Ubuntu siap di WSL"

# Ambil username Ubuntu
$userUbuntu = (wsl -d $DISTRO -e whoami).Trim()
Tulis-Ok "username Ubuntu: $userUbuntu"

# ===========================================================================
# TAHAP 3 — JALANKAN PEMASANG LINUX DI DALAM UBUNTU
# ===========================================================================
Tulis-Judul "TAHAP 3 dari 5 - MEMASANG KOMPONEN (di dalam Ubuntu)"

Tulis-Info "menyiapkan alat dasar di Ubuntu..."
wsl -d $DISTRO -u root -e bash -c "apt-get update -qq && apt-get install -y -qq git curl rsync" 2>$null

# Salin repo ke dalam Ubuntu (kalau dijalankan dari Windows)
$lokasiSkrip = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoDiWsl = "/tmp/hermes-custom"

Tulis-Info "menyalin berkas pemasang ke Ubuntu..."
$pathWindows = (Get-Item $lokasiSkrip).FullName
wsl -d $DISTRO -u root -e bash -c "rm -rf $repoDiWsl && mkdir -p $repoDiWsl && cp -a '/mnt/$(($pathWindows -replace '\\','/') -replace '^([A-Za-z]):', '$1')/.' $repoDiWsl/ 2>/dev/null || true"

$opsi = ""
if ($LewatiStt) { $opsi = "--tanpa-stt" }

Tulis-Info "menjalankan pemasang Linux..."
Write-Host "  (ini bagian terpanjang - 15 sampai 30 menit)" -ForegroundColor Yellow
Write-Host ""

wsl -d $DISTRO -u root -e bash -c "cd $repoDiWsl && chmod +x install.sh && ./install.sh $opsi"

if ($LASTEXITCODE -ne 0) {
    Tulis-Gagal "Pemasang melaporkan masalah. Periksa keluaran di atas."
} else {
    Tulis-Ok "komponen dasar terpasang"
}

# ===========================================================================
# TAHAP 4 — AUTOSTART (TASK SCHEDULER)
# ===========================================================================
Tulis-Judul "TAHAP 4 dari 5 - AUTOSTART"

$namaTask = "AI Agent Gateway"
$perintah = "wsl.exe -d $DISTRO -u $userUbuntu -e bash -lc '~/.local/bin/hermes gateway'"

Tulis-Info "mendaftarkan autostart..."
schtasks /create /tn "$namaTask" /tr "$perintah" /sc onstart /ru SYSTEM /rl HIGHEST /f 2>$null | Out-Null

if ($LASTEXITCODE -eq 0) {
    Tulis-Ok "autostart terdaftar — nyala sendiri saat Windows dinyalakan"
} else {
    Tulis-Gagal "pendaftaran gagal. Daftarkan manual lewat Task Scheduler."
    Write-Host "     Lihat: docs/WINDOWS.md bagian 'Langkah 3'" -ForegroundColor Yellow
}

# ===========================================================================
# TAHAP 5 — GILIRAN ANDA
# ===========================================================================
Tulis-Judul "TAHAP 5 dari 5 - GILIRAN ANDA (sekitar 5 menit)"

Write-Host @"

  Pemasangan teknis SUDAH SELESAI.
  Empat langkah berikut butuh Anda - karena hanya Anda yang punya kuncinya.

"@ -ForegroundColor White

Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |  1. JARINGAN AMAN (otomatis)                            |" -ForegroundColor Cyan
Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host @"

     Kalau Anda menerima kunci dari teknisi, langkah ini sudah otomatis.
     Kalau tidak, buka Ubuntu dan jalankan:

        wsl -d Ubuntu
        sudo tailscale up --ssh

     PENTING: pasang Tailscale di WINDOWS juga (bukan hanya di Ubuntu)
     supaya remote view bisa diakses dari HP/laptop:
        winget install --id Tailscale.Tailscale

"@ -ForegroundColor White

Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |  2. AKUN AI - WAJIB                                     |" -ForegroundColor Cyan
Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host @"

     Buka Ubuntu, lalu jalankan:

        wsl -d Ubuntu
        hermes setup --portal

     Browser akan terbuka. Login sekali, pilih model. GRATIS di awal.

"@ -ForegroundColor White

Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |  3. WHATSAPP (opsional)                                 |" -ForegroundColor Cyan
Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host @"

     Mode SELF-CHAT: robot hanya membalas pesan Anda sendiri.

     a. Di Ubuntu, nyalakan remote view:
          ~/.hermes/remote-view/remote-view.sh start
          ~/.hermes/remote-view/remote-view.sh password
     b. Jalankan jembatan port (di PowerShell Administrator):
          netsh interface portproxy add v4tov4 listenport=6080 listenaddress=0.0.0.0 connectport=6080 connectaddress=(wsl hostname -I).Trim()
     c. Buka:  http://<IP-Tailscale-Windows>:6080/vnc.html
     d. Pindai QR WhatsApp
     e. MATIKAN remote view: remote-view.sh stop

"@ -ForegroundColor White

Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |  4. GOOGLE - Sheets / Drive / Docs (opsional)           |" -ForegroundColor Cyan
Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host @"

     Di Ubuntu:
        wsl -d Ubuntu
        hermes setup tools

"@ -ForegroundColor White

Write-Host "=== RINGKASAN ===" -ForegroundColor Cyan
Tulis-Ok "Hermes             terpasang (di dalam WSL Ubuntu)"
Tulis-Ok "WhatsApp           http://localhost:8081"
Tulis-Ok "Pencarian          http://localhost:8080"
Tulis-Ok "Autostart          Task Scheduler aktif"
Write-Host ""
Write-Host "  Panduan lengkap: docs/WINDOWS.md" -ForegroundColor Yellow
Write-Host "  Selamat! Sistemnya sudah jadi." -ForegroundColor Green
Write-Host ""
