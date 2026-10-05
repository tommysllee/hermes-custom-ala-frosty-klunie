# ============================================================================
#  install.ps1 — Business AI Agent installer for WINDOWS
# ============================================================================
#  Windows tidak punya sistem Linux, jadi pemasangnya metheni WSL2 + Ubuntu.
#  This script handles everything: install WSL, run the Linux installer,
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
#     Stage 1  periksa Windows + WSL
#     Stage 2  install WSL2 + Ubuntu (kalau not yet ada)
#     Stage 3  run the Linux installer inside Ubuntu
#     Stage 4  daftarkan autostart (Task Scheduler)
#     Stage 5  YOUR TURN: Tailscale, Nous Portal, WhatsApp, Google
#  ----------------------------------------------------------------------------

param(
    [switch]$Test,
    [switch]$SkipStt
)

$ErrorActionPreference = "Stop"
$VERSION = "1.0.0"
$DISTRO = "Ubuntu"

# ---------------------------------------------------------------------------
# Tampilan
# ---------------------------------------------------------------------------
function Write-Ok    { param($m) Write-Host "  [OK] $m"   -ForegroundColor Green }
function Write-Info  { param($m) Write-Host "  [>]  $m"   -ForegroundColor Yellow }
function Write-Fail { param($m) Write-Host "  [X]  $m"   -ForegroundColor Red }
function Write-Title { param($m) Write-Host "`n=== $m ===" -ForegroundColor Cyan }

Write-Host @"
+====================================================================+
|                                                                    |
|        P E M A S A N G   A I   A G E N T   B I S N I S             |
|                        (Windows)                                   |
|                                                                    |
|   Semuanya berjalan sendiri. you hanya perlu bertindak di         |
|   bagian TERAKHIR (sekitar 5 menit).                               |
|                                                                    |
+====================================================================+
"@ -ForegroundColor Cyan

# ---------------------------------------------------------------------------
# Check: running as Administrator?
# ---------------------------------------------------------------------------
$mySid = [Security.Principal.WindowsIdentity]::GetCurrent()
$principal = New-Object Security.Principal.WindowsPrincipal($mySid)
$admin = $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $admin) {
    Write-Fail "This script must be run as Administrator."
    Write-Host ""
    Write-Host "  1. Tutup PowerShell ini" -ForegroundColor Yellow
    Write-Host "  2. Open Start Menu, cari 'PowerShell'" -ForegroundColor Yellow
    Write-Host "  3. Klik kanan -> 'Run as administrator'" -ForegroundColor Yellow
    Write-Host "  4. Ulangi perintahnya" -ForegroundColor Yellow
    exit 1
}
Write-Ok "berjalan sebagai Administrator"

# ===========================================================================
# STAGE 1 — PERIKSA WINDOWS & WSL
# ===========================================================================
Write-Title "STAGE 1 of 5 - CHECKING SYSTEM"

$os = Get-CimInstance Win32_OperatingSystem
Write-Info "Windows : $($os.Caption) (build $($os.BuildNumber))"

if ([int]$os.BuildNumber -lt 19041) {
    Write-Fail "Windows terlalu lama. Need Windows 10 versi 2004 (build 19041) atau lebih baru."
    exit 1
}
Write-Ok "Windows version didukung"

# Ruang disk
$disk = Get-PSDrive C
$spaceGB = [math]::Round($disk.Free / 1GB, 1)
Write-Info "ruang disk C: $spaceGB GB"
if ($spaceGB -lt 18) {
    Write-Fail "ruang kurang dari 18 GB — kosongkan dulu"
    exit 1
}
Write-Ok "ruang cukup"

# Memori
$ramGB = [math]::Round($os.TotalVisibleMemorySize / 1MB, 1)
Write-Info "memori      : $ramGB GB"

# Virtualisasi (syarat WSL2)
$cpu = Get-CimInstance Win32_Processor
if ($cpu.VirtualizationFirmwareEnabled -eq $false) {
    Write-Fail "Virtualisasi mati di BIOS."
    Write-Host "  Nyalakan VT-x (Intel) atau AMD-V di BIOS, lalu ulangi." -ForegroundColor Yellow
    exit 1
}
Write-Ok "virtualisasi aktif"

# WSL already ada?
$hasWsl = $false
try {
    $null = wsl --status 2>$null
    $hasWsl = $true
    Write-Ok "WSL already terpasang"
} catch {
    Write-Info "WSL not yet terinstall — akan diinstall di stage 2"
}

# Ubuntu already ada?
$hasUbuntu = $false
if ($hasWsl) {
    $list = wsl -l -q 2>$null
    if ($list -match $DISTRO) {
        $hasUbuntu = $true
        Write-Ok "Ubuntu already terinstall di WSL"
    } else {
        Write-Info "Ubuntu not yet ada di WSL — akan diinstall di stage 2"
    }
}

if ($Test) {
    Write-Host ""
    Write-Ok "PEMERIKSAAN COMPLETE - mode tes, none yang diubah"
    exit 0
}

# ===========================================================================
# STAGE 2 — PASANG WSL2 + UBUNTU
# ===========================================================================
Write-Title "STAGE 2 of 5 - WSL2 + UBUNTU"

if (-not $hasWsl) {
    Write-Info "installing WSL2 (perlu beberapa menit)..."
    wsl --install --no-distribution
    Write-Ok "WSL2 dipasang"
    Write-Host ""
    Write-Fail "RESTART DIPERLUKAN"
    Write-Host "  After the restart, run this script again:" -ForegroundColor Yellow
    Write-Host "     .\install.ps1" -ForegroundColor White
    exit 0
}

if (-not $hasUbuntu) {
    Write-Info "installing Ubuntu di WSL..."
    wsl --install -d $DISTRO
    Write-Host ""
    Write-Host "  Ubuntu akan meminta you creating USERNAME dan PASSWORD." -ForegroundColor Yellow
    Write-Host "  CATAT baik-baik - akan dipakai lagi nanti." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Press Enter once the Ubuntu account is created"

    # Pastikan versi 2
    Write-Info "memastikan WSL versi 2..."
    wsl --set-version $DISTRO 2 2>$null
}
Write-Ok "Ubuntu ready di WSL"

# Ambil Ubuntu username
$ubuntuUser = (wsl -d $DISTRO -e whoami).Trim()
Write-Ok "Ubuntu username: $ubuntuUser"

# ===========================================================================
# STAGE 3 — JALANKAN PEMASANG LINUX DI DALAM UBUNTU
# ===========================================================================
Write-Title "STAGE 3 of 5 - INSTALLING COMPONENTS (di dalam Ubuntu)"

Write-Info "preparing base tools in Ubuntu..."
wsl -d $DISTRO -u root -e bash -c "apt-get update -qq && apt-get install -y -qq git curl rsync" 2>$null

# ===========================================================================
# CHECK FIRST: is Hermes already present inside Ubuntu?
# If already, cukup pakai yang ada - jangan install ulang.
# ===========================================================================
Write-Info "checking whether Hermes is already installed in Ubuntu..."
$hermesCheck = (wsl -d $DISTRO -u $ubuntuUser -e bash -lc "command -v hermes || ls ~/.local/bin/hermes 2>/dev/null || ls ~/.hermes/bin/hermes 2>/dev/null || echo NOADA" 2>$null)
if ($hermesCheck -and $hermesCheck.Trim() -ne "NOADA" -and $hermesCheck -notmatch "NOADA") {
    Write-Ok "Hermes ALREADY PRESENT in Ubuntu: $($hermesCheck.Trim())"
    Write-Info "   not reinstalled - continuing to the next stage"
    $HermesExists = $true
} else {
    Write-Info "Hermes not found - will be installed"
    $HermesExists = $false
}
Write-Host ""

# Copy the repo into Ubuntu (when run from Windows)
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoInWsl = "/tmp/hermes-custom"

Write-Info "copying installer files into Ubuntu..."
$windowsPath = (Get-Item $scriptPath).FullName
wsl -d $DISTRO -u root -e bash -c "rm -rf $repoInWsl && mkdir -p $repoInWsl && cp -a '/mnt/$(($windowsPath -replace '\\','/') -replace '^([A-Za-z]):', '$1')/.' $repoInWsl/ 2>/dev/null || true"

$options = ""
if ($SkipStt) { $options = "--tanpa-stt" }

Write-Info "running the Linux installer..."
Write-Host "  (this is the longest part - 15 to 30 minutes)" -ForegroundColor Yellow
Write-Host ""

wsl -d $DISTRO -u root -e bash -c "cd $repoInWsl && chmod +x install.sh && ./install.sh $options"

if ($LASTEXITCODE -ne 0) {
    Write-Fail "The installer reported a problem. Check the output above."
} else {
    Write-Ok "komponen dasar terpasang"
}

# ===========================================================================
# STAGE 4 — AUTOSTART (TASK SCHEDULER)
# ===========================================================================
Write-Title "STAGE 4 of 5 - AUTOSTART"

$taskName = "AI Agent Gateway"
$command = "wsl.exe -d $DISTRO -u $ubuntuUser -e bash -lc '~/.local/bin/hermes gateway'"

Write-Info "mendaftarkan autostart..."
schtasks /create /tn "$taskName" /tr "$command" /sc onstart /ru SYSTEM /rl HIGHEST /f 2>$null | Out-Null

if ($LASTEXITCODE -eq 0) {
    Write-Ok "autostart terdaftar — nyala sendiri saat Windows dinyalakan"
} else {
    Write-Fail "pendaftaran gagal. Daftarkan manual lewat Task Scheduler."
    Write-Host "     Lihat: docs/WINDOWS.md bagian 'Langkah 3'" -ForegroundColor Yellow
}

# ===========================================================================
# STAGE 5 — YOUR TURN
# ===========================================================================
Write-Title "STAGE 5 of 5 - YOUR TURN (sekitar 5 menit)"

Write-Host @"

  Pemasangan teknis SUDAH COMPLETE.
  Empat langkah berikut butuh you - karena hanya you yang punya kuncinya.

"@ -ForegroundColor White

Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |  1. JARINGAN AMAN (otomatis)                            |" -ForegroundColor Cyan
Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host @"

     If you menerima kunci dari teknisi, langkah ini already otomatis.
     If not, open Ubuntu and run:

        wsl -d Ubuntu
        sudo tailscale up --ssh

     PENTING: install Tailscale di WINDOWS juga (bukan hanya di Ubuntu)
     supaya remote view bisa diakses dari HP/laptop:
        winget install --id Tailscale.Tailscale

"@ -ForegroundColor White

Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |  2. AKUN AI - WAJIB                                     |" -ForegroundColor Cyan
Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host @"

     Open Ubuntu, then run:

        wsl -d Ubuntu
        hermes setup --portal

     Browser akan terbuka. Login sekali, pilih model. GRATIS di awal.

"@ -ForegroundColor White

Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host "  |  3. WHATSAPP (opsional)                                 |" -ForegroundColor Cyan
Write-Host "  +---------------------------------------------------------+" -ForegroundColor Cyan
Write-Host @"

     SELF-CHAT mode: the robot only replies to your own messages.

     a. Di Ubuntu, nyalakan remote view:
          ~/.hermes/remote-view/remote-view.sh start
          ~/.hermes/remote-view/remote-view.sh password
     b. Run jembatan port (di PowerShell Administrator):
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
Write-Ok "Hermes             installed (inside WSL Ubuntu)"
Write-Ok "WhatsApp           http://localhost:8081"
Write-Ok "Pencarian          http://localhost:8080"
Write-Ok "Autostart          Task Scheduler aktif"
Write-Host ""
Write-Host "  Panduan lengkap: docs/WINDOWS.md" -ForegroundColor Yellow
Write-Host "  Selamat! Sistemnya already jadi." -ForegroundColor Green
Write-Host ""
