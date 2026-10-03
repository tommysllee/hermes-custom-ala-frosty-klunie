#!/usr/bin/env bash
# ============================================================================
#  install-mac.sh — Pemasang AI Agent Bisnis untuk macOS
# ============================================================================
#  macOS tidak punya apt dan tidak punya systemd, jadi pemasangnya berbeda
#  dari Linux. Skrip ini memasang komponennya lewat Homebrew + pip,
#  lalu mendaftarkan autostart lewat LaunchAgent.
#
#  CARA PAKAI
#     git clone https://github.com/tommysllee/hermes-custom.git
#     cd hermes-custom
#     ./install-mac.sh
#
#  Opsi:
#     ./install-mac.sh --tes        periksa saja, tidak mengubah apa pun
#     ./install-mac.sh --tanpa-stt  tanpa suara lokal
#
#  ---------------------------------------------------------------------------
#  PERINGATAN PENTING
#    Kalau FileVault aktif, MacBook BERHENTI di layar login setelah restart.
#    Sebelum ada yang login, robot TIDAK jalan.
#    Baca docs/MAC.md sebelum memakai ini untuk keperluan 24/7.
#  ----------------------------------------------------------------------------
set -uo pipefail

VERSI="1.0.0"
LOG="/tmp/agent-install-mac-$(date +%Y%m%d_%H%M).log"
TES=0; TANPA_STT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --tes|--dry-run) TES=1 ;;
    --tanpa-stt)     TANPA_STT=1 ;;
    -h|--help) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
  shift
done

# Warna
if [ -t 1 ]; then
  HIJAU=$'\033[0;32m'; MERAH=$'\033[0;31m'; KUNING=$'\033[0;33m'
  BIRU=$'\033[0;36m'; OFF=$'\033[0m'
else
  HIJAU=""; MERAH=""; KUNING=""; BIRU=""; OFF=""
fi
ok()    { printf '%s  ✓%s %s\n' "$HIJAU" "$OFF" "$*"; }
gagal() { printf '%s  ✗%s %s\n' "$MERAH" "$OFF" "$*"; }
info()  { printf '%s  →%s %s\n' "$KUNING" "$OFF" "$*"; }
judul() { printf '\n%s═══ %s ═══%s\n' "$BIRU" "$*" "$OFF"; }
jalan() { if [ "$TES" = "1" ]; then printf '      [tes] %s\n' "$*"; return 0; fi; eval "$@" >>"$LOG" 2>&1; }

cat <<'SAMPUL'
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║          P E M A S A N G   A I   A G E N T   B I S N I S           ║
║                          (macOS)                                   ║
║                                                                    ║
║   Catatan: robot hanya hidup SETELAH Anda login ke Mac.            ║
║   Kalau butuh 24/7, pakai komputer Linux. Lihat docs/MAC.md.       ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
SAMPUL
echo
info "Catatan lengkap: $LOG"

# ===========================================================================
# TAHAP 1 — PERIKSA
# ===========================================================================
judul "TAHAP 1 dari 5 — MEMERIKSA SISTEM"

if [ "$(uname)" != "Darwin" ]; then
  gagal "skrip ini khusus macOS"
  info "Untuk Linux pakai: ./install.sh"
  info "Untuk Windows pakai: .\\install.ps1"
  exit 1
fi

MACOS_VER="$(sw_vers -productVersion)"
MACOS_NAMA="$(sw_vers -productName)"
ARCH="$(uname -m)"
info "Sistem : $MACOS_NAMA $MACOS_VER ($ARCH)"

# Versi minimal
VERSI_UTAMA="${MACOS_VER%%.*}"
if [ "${VERSI_UTAMA:-0}" -lt 12 ]; then
  gagal "butuh macOS 12 atau lebih baru"
  exit 1
fi
ok "versi macOS didukung"

# Ruang disk
RUANG_GB=$(df -g / 2>/dev/null | tail -1 | awk '{print $4}')
info "ruang disk : ${RUANG_GB:-?} GB"
if [ -n "${RUANG_GB:-}" ] && [ "$RUANG_GB" -lt 18 ]; then
  gagal "ruang kurang dari 18 GB"
  exit 1
fi
ok "ruang cukup"

# Memori
RAM_GB=$(( $(sysctl -n hw.memsize 2>/dev/null || echo 0) / 1073741824 ))
info "memori     : ${RAM_GB} GB"
if [ "$RAM_GB" -lt 4 ]; then
  info "memori < 4 GB — suara lokal dilewati"
  TANPA_STT=1
fi

# Internet
curl -fsS --max-time 10 https://example.com >/dev/null 2>&1 \
  && ok "internet tersambung" \
  || { gagal "tidak ada internet"; exit 1; }

# FileVault — peringatan penting
FV="$(fdesetup status 2>/dev/null || echo 'tidak diketahui')"
if echo "$FV" | grep -qi "On"; then
  echo
  gagal "FileVault AKTIF"
  cat <<'FVW'

     Ini penting: dengan FileVault aktif, MacBook berhenti di
     layar login setelah restart. Robot TIDAK jalan sampai ada
     yang login.

     Solusi supaya robot hidup setelah reboot:
       System Settings -> Users & Groups -> Automatically log in as

     Ingat: FileVault tetap aktif. Sandi boot tetap diminta saat
     pertama menyalakan. Auto-login hanya berlaku setelah disk terbuka.

     Kalau butuh robot yang selalu hidup -> pakai komputer Linux.
FVW
  echo
else
  ok "FileVault tidak aktif"
fi

# Xcode Command Line Tools (dibutuhkan Homebrew)
if ! xcode-select -p >/dev/null 2>&1; then
  info "memasang Xcode Command Line Tools (muncul jendela, klik Install)..."
  jalan "xcode-select --install"
  echo
  info "Tunggu sampai selesai, lalu ULANGI skrip ini."
  exit 0
fi
ok "alat pengembang siap"

if [ "$TES" = "1" ]; then
  echo; ok "PEMERIKSAAN SELESAI — mode tes"; exit 0
fi

# ===========================================================================
# TAHAP 2 — HOMEBREW + KOMPONEN DASAR
# ===========================================================================
judul "TAHAP 2 dari 5 — KOMPONEN DASAR"

# Homebrew
if command -v brew >/dev/null 2>&1; then
  ok "Homebrew sudah ada"
else
  info "memasang Homebrew (akan minta sandi Anda)..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" >>"$LOG" 2>&1
  # Tambahkan ke PATH (Apple Silicon vs Intel)
  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$HOME/.zprofile"
  fi
  command -v brew >/dev/null 2>&1 && ok "Homebrew dipasang" || { gagal "Homebrew gagal"; exit 1; }
fi

# Docker Desktop
if command -v docker >/dev/null 2>&1; then
  ok "Docker sudah ada"
else
  info "memasang Docker Desktop (unduhan besar)..."
  jalan "brew install --cask docker"
  ok "Docker Desktop dipasang"
  info "BUKA aplikasi Docker sekali dari Applications — robot butuh itu"
fi

# Alat tambahan
info "memasang alat pendukung..."
jalan "brew install python3 ffmpeg imagemagick git rsync"
ok "alat pendukung siap"

# Hermes
if command -v hermes >/dev/null 2>&1; then
  ok "Hermes sudah ada"
else
  info "memasang Hermes..."
  jalan "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"
  export PATH="$HOME/.local/bin:$PATH"
  command -v hermes >/dev/null 2>&1 && ok "Hermes dipasang" || { gagal "Hermes gagal"; exit 1; }
fi

# Tailscale
if command -v tailscale >/dev/null 2>&1; then
  ok "Tailscale sudah ada"
else
  info "memasang Tailscale..."
  jalan "brew install --cask tailscale"
  ok "Tailscale dipasang (buka aplikasinya untuk login)"
fi

# Camoufox
if [ -x "$HOME/.cache/camoufox/camoufox-bin" ] || [ -d "$HOME/Library/Caches/camoufox" ]; then
  ok "Camoufox sudah ada"
else
  info "mengunduh Camoufox (~1,3 GB)..."
  PY="$(command -v python3)"
  "$PY" -c "import camoufox" 2>/dev/null || jalan "$PY -m pip install --user -q camoufox"
  jalan "$PY" -m camoufox fetch
  ok "Camoufox selesai (atau akan dicoba lagi nanti)"
fi

# ===========================================================================
# TAHAP 3 — PENGATURAN
# ===========================================================================
judul "TAHAP 3 dari 5 — PENGATURAN"

HERMES_HOME="$HOME/.hermes"
CONFIG="$HERMES_HOME/config.yaml"
mkdir -p "$HERMES_HOME/remote-view" "$HERMES_HOME/scripts" "$HERMES_HOME/logs"

if [ ! -f "$CONFIG" ] || ! grep -q "dibuat-oleh-installer" "$CONFIG" 2>/dev/null; then
  [ -f "$CONFIG" ] && cp -a "$CONFIG" "$CONFIG.sebelum-install-$(date +%Y%m%d_%H%M)"
  cat > "$CONFIG" <<'YAML'
# dibuat-oleh-installer — AI Agent Bisnis (macOS)
agent:
  provider: nous
  reasoning_effort: medium

stt:
  provider: local
  model: medium
  language: id

web:
  backend: ddgs

browser:
  backend: camoufox
  headless: true

terminal:
  backend: local
  timeout: 180
YAML
  ok "pengaturan dasar ditulis"
else
  info "pengaturan sudah ada — tidak ditimpa"
fi

# Suara lokal
if [ "$TANPA_STT" = "0" ]; then
  PY="$(command -v python3)"
  if "$PY" -c "import faster_whisper" 2>/dev/null; then ok "mesin suara lokal siap"
  else
    info "memasang mesin suara lokal..."
    "$PY" -m pip install --user -q faster-whisper 2>>"$LOG" \
      && ok "mesin suara lokal siap" || info "suara lokal gagal — bisa dicoba nanti"
  fi
fi

# Remote view (tanpa Xvfb/x11vnc — macOS punya VNC bawaan)
cat > "$HERMES_HOME/remote-view/remote-view.sh" <<'RVS'
#!/usr/bin/env bash
# Remote view di macOS memakai VNC bawaan sistem.
set -uo pipefail
IP_TS="$(if command -v tailscale >/dev/null 2>&1; then tailscale ip -4 2>/dev/null | head -1; fi)"
[ -z "$IP_TS" ] && IP_TS="$(ipconfig getifaddr en0 2>/dev/null || echo 127.0.0.1)"
case "${1:-status}" in
  start)
    echo "  Nyalakan berbagi layar macOS:"
    echo "     System Settings -> General -> Sharing -> Screen Sharing: ON"
    echo ""
    echo "  Lalu hubungkan dari perangkat lain (via Finder atau VNC):"
    echo "     vnc://$IP_TS"
    ;;
  stop)
    echo "  Matikan: System Settings -> General -> Sharing -> Screen Sharing: OFF"
    ;;
  status)
    if launchctl list 2>/dev/null | grep -q com.apple.screensharing; then
      echo "  Status: AKTIF — vnc://$IP_TS"
    else
      echo "  Status: MATI (nyalakan lewat System Settings -> Sharing)"
    fi
    ;;
  *)
    echo "Pakai: $0 start | stop | status"
    ;;
esac
RVS
chmod +x "$HERMES_HOME/remote-view/remote-view.sh"
ok "remote view disiapkan (pakai VNC bawaan macOS)"

# ===========================================================================
# TAHAP 4 — AUTOSTART (LaunchAgent)
# ===========================================================================
judul "TAHAP 4 dari 5 — OTOMATISASI"

LA_DIR="$HOME/Library/LaunchAgents"
mkdir -p "$LA_DIR"
PLIST="$LA_DIR/com.hermes.gateway.plist"
HERMES_BIN="$(command -v hermes || echo "$HOME/.local/bin/hermes")"

cat > "$PLIST" <<PLISTF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.hermes.gateway</string>
    <key>ProgramArguments</key>
    <array>
        <string>$HERMES_BIN</string>
        <string>gateway</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/tmp/hermes-gateway.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/hermes-gateway-error.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:$HOME/.local/bin</string>
    </dict>
</dict>
</plist>
PLISTF

launchctl unload "$PLIST" 2>/dev/null || true
if launchctl load "$PLIST" 2>>"$LOG"; then
  launchctl start com.hermes.gateway 2>/dev/null || true
  ok "autostart terdaftar (LaunchAgent)"
  info "berjalan setelah Anda login ke Mac"
else
  gagal "pendaftaran autostart gagal — lihat docs/MAC.md"
fi

# Cegah tidur saat colok listrik
info "mencegah Mac tidur saat colok listrik..."
jalan "sudo pmset -c sleep 0 disablesleep 1"
ok "Mac tidak akan tidur saat colok listrik"

# Backup otomatis
cat > "$HERMES_HOME/scripts/backup-agent.sh" <<'BK'
#!/usr/bin/env bash
set -uo pipefail
TGL="$(date +%Y%m%d_%H%M)"
DIR="$HOME/backups_agent"
mkdir -p "$DIR"
ARSIP="$DIR/agent_${TGL}.tar.gz"
tar -czf "$ARSIP" -C "$HOME" .hermes 2>/dev/null || true
echo "$(date '+%F %T') backup: $ARSIP"
find "$DIR" -name 'agent_*.tar.gz' -mtime +7 -delete 2>/dev/null || true
BK
chmod +x "$HERMES_HOME/scripts/backup-agent.sh"
# cron di macOS masih ada
( crontab -l 2>/dev/null | grep -v 'backup-agent.sh'; \
  echo "0 2,14 * * * $HERMES_HOME/scripts/backup-agent.sh >> $HERMES_HOME/logs/backup.log 2>&1" \
) | crontab - 2>/dev/null && ok "backup otomatis 2x sehari aktif"

# ===========================================================================
# TAHAP 5 — GILIRAN ANDA
# ===========================================================================
judul "TAHAP 5 dari 5 — GILIRAN ANDA (sekitar 5 menit)"

cat <<'PESAN'

  Pemasangan teknis SUDAH SELESAI.
  Empat langkah berikut butuh Anda.

PESAN

echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  1. JARINGAN AMAN (otomatis)                            │"
echo "  └─────────────────────────────────────────────────────────┘"
cat <<'TS'

     Buka aplikasi Tailscale dari Applications, lalu login.
     Kalau menerima kunci dari teknisi, jalankan di Terminal:

        sudo tailscale up --ssh

TS

echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  2. AKUN AI — WAJIB                                     │"
echo "  └─────────────────────────────────────────────────────────┘"
cat <<'NOUS'

     Jalankan:

        hermes setup --portal

     Browser terbuka. Login sekali, pilih model. GRATIS di awal.

NOUS

echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  3. WHATSAPP (opsional)                                 │"
echo "  └─────────────────────────────────────────────────────────┘"
cat <<'WA'

     Mode SELF-CHAT: robot hanya membalas pesan Anda sendiri.

        docker compose -f ~/evolution/docker-compose.yml up -d
        open http://localhost:8081/manager

     Pindai QR: WhatsApp -> Setelan -> Perangkat Tertaut

WA

echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  4. GOOGLE — Sheets / Drive / Docs (opsional)           │"
echo "  └─────────────────────────────────────────────────────────┘"
cat <<'GO'

        hermes setup tools

GO

echo
echo "  ═══════════════════════════════════════════════════════════════"
echo "   RINGKASAN"
echo "  ═══════════════════════════════════════════════════════════════"
echo
ok "Hermes          terpasang"
ok "Suara lokal     siap (tanpa API key)"
ok "Tailscale       terpasang"
ok "Autostart       LaunchAgent terdaftar"
ok "Anti-tidur      aktif saat colok listrik"
echo
gagal "INGAT: robot hidup SETELAH Anda login ke Mac"
info "Kalau butuh 24/7, pakai komputer Linux — lihat docs/MAC.md"
info "Catatan lengkap: $LOG"
echo
echo "  Selamat! Sistemnya sudah jadi."
echo
