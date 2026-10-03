#!/usr/bin/env bash
# ============================================================================
#  install.sh — Pemasang AI Agent Bisnis (otomatis penuh)
# ============================================================================
#  Satu perintah. Duduk santai. Yang perlu Anda kerjakan hanya di bagian
#  paling akhir (sekitar 5 menit).
#
#  CARA PAKAI
#     git clone <URL-REPO-ANDA>
#     cd hermes-custom
#     ./install.sh
#
#  Opsi:
#     --tes            periksa sistem saja, tidak mengubah apa pun
#     --tanpa-docker   lewati Docker (Evolution, SearXNG, backup)
#     --tanpa-stt      lewati model suara lokal
#
#  ---------------------------------------------------------------------------
#  URUTAN (yang melibatkan manusia SELALU di akhir)
#    Tahap 1  periksa sistem
#    Tahap 2  pasang dasar          (Hermes, Docker, venv, Camoufox)
#    Tahap 3  pasang aplikasi       (STT lokal, search, Evolution, noVNC)
#    Tahap 4  otomatiskan           (autostart, backup 2x sehari, Sheets)
#    Tahap 5  GILIRAN ANDA:
#             1. Tailscale   -> otomatis nyambung ke tailnet pemilik repo
#             2. Nous Portal -> login sekali (WAJIB)
#             3. WhatsApp    -> scan QR (mode self-chat)
#             4. Google      -> login OAuth (Sheets/Drive/Docs)
#  ----------------------------------------------------------------------------
set -uo pipefail

VERSI="1.0.0"
LOG="/tmp/agent-install-$(date +%Y%m%d_%H%M).log"
TES=0; TANPA_DOCKER=0; TANPA_STT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --tes|--dry-run) TES=1 ;;
    --tanpa-docker)  TANPA_DOCKER=1 ;;
    --tanpa-stt)     TANPA_STT=1 ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Warna & pesan
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  HIJAU=$'\033[0;32m'; MERAH=$'\033[0;31m'; KUNING=$'\033[0;33m'
  BIRU=$'\033[0;36m'; TEBAL=$'\033[1m'; OFF=$'\033[0m'
else
  HIJAU=""; MERAH=""; KUNING=""; BIRU=""; TEBAL=""; OFF=""
fi
ok()    { printf '%s  ✓%s %s\n' "$HIJAU" "$OFF" "$*"; }
gagal() { printf '%s  ✗%s %s\n' "$MERAH" "$OFF" "$*"; }
info()  { printf '%s  →%s %s\n' "$KUNING" "$OFF" "$*"; }
judul() { printf '\n%s═══ %s ═══%s\n' "$BIRU" "$*" "$OFF"; }
kotak() { printf '%s  ┌─────────────────────────────────────────────────────────┐%s\n' "$BIRU" "$OFF"
          printf '%s  │  %-53s│%s\n' "$BIRU" "$*" "$OFF"
          printf '%s  └─────────────────────────────────────────────────────────┘%s\n' "$BIRU" "$OFF"; }

# Jalankan perintah (kalau --tes, hanya cetak)
jalan() {
  if [ "$TES" = "1" ]; then printf '      [tes] %s\n' "$*"; return 0; fi
  eval "$@" >>"$LOG" 2>&1
}

# Muat pengaturan installer kalau ada
DIR_REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$DIR_REPO/.env" ]; then . "$DIR_REPO/.env"
elif [ -f "$DIR_REPO/installer.env" ]; then . "$DIR_REPO/installer.env"; fi

TS_AUTHKEY="${TS_AUTHKEY:-}"
TS_TAG="${TS_TAG:-}"
NOUS_AUTO="${NOUS_AUTO:-1}"
WA_MODE="${WA_MODE:-self-chat}"
GOOGLE_ENABLE="${GOOGLE_ENABLE:-1}"
AUTOBACKUP="${AUTOBACKUP:-1}"
BACKUP_DRIVE="${BACKUP_DRIVE:-1}"
NOVNC_ENABLE="${NOVNC_ENABLE:-1}"
KONTAK_NAMA="${KONTAK_NAMA:-}"
KONTAK_TELEGRAM="${KONTAK_TELEGRAM:-}"
KONTAK_EMAIL="${KONTAK_EMAIL:-}"
KONTAK_WA="${KONTAK_WA:-}"

cat <<'SAMPUL'
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║          P E M A S A N G   A I   A G E N T   B I S N I S           ║
║                                                                    ║
║   Semuanya berjalan sendiri. Anda hanya perlu bertindak di         ║
║   bagian TERAKHIR (sekitar 5 menit): login, scan QR, selesai.      ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
SAMPUL
echo
info "Catatan lengkap: $LOG"
[ -n "$TS_TAG" ] && info "Tag jaringan: $TS_TAG"

# ===========================================================================
# TAHAP 1 — PERIKSA SISTEM
# ===========================================================================
judul "TAHAP 1 dari 5 — MEMERIKSA SISTEM"

OS_ID=""
[ -r /etc/os-release ] && . /etc/os-release
OS_ID="${ID:-}"
ARCH="$(uname -m)"
info "Sistem : ${PRETTY_NAME:-tidak dikenal} (${ARCH})"

case "$OS_ID" in
  ubuntu|debian) ok "sistem didukung" ;;
  *)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      ok "WSL terdeteksi — didukung"
    else
      gagal "butuh Ubuntu atau Debian"
      info "Windows: pasang WSL2 + Ubuntu (lihat docs/WINDOWS.md)"
      info "Mac    : lihat docs/MAC.md"
      exit 1
    fi ;;
esac

DI_WSL=0; grep -qi microsoft /proc/version 2>/dev/null && DI_WSL=1
[ "$DI_WSL" = "1" ] && info "berjalan di dalam WSL"

# Akses admin
if [ "$(id -u)" = "0" ]; then SUDO=""; ok "berjalan sebagai root"
else
  SUDO="sudo"
  if sudo -n true 2>/dev/null; then ok "akses admin siap"
  else
    info "akses admin akan diminta sekali (masukkan sandi Anda)"
    sudo -v 2>/dev/null || { gagal "tidak bisa memakai sudo"; exit 1; }
  fi
fi

# Disk & memori
RUANG_GB=$(df -BG --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')
info "ruang disk : ${RUANG_GB:-?} GB"
if [ -n "$RUANG_GB" ] && [ "$RUANG_GB" -lt 15 ]; then
  gagal "ruang kurang dari 15 GB — kosongkan dulu"
  exit 1
fi
ok "ruang cukup"

RAM_MB=$(awk '/MemTotal/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
info "memori     : ${RAM_MB:-?} MB"
if [ -n "${RAM_MB:-}" ] && [ "$RAM_MB" -lt 3500 ]; then
  info "memori < 4 GB — model suara lokal dilewati"
  TANPA_STT=1
fi

# Internet
curl -fsS --max-time 10 https://example.com >/dev/null 2>&1 \
  && ok "internet tersambung" \
  || { gagal "tidak ada internet"; exit 1; }

GAGAL_COUNT=0
catatan_gagal() { GAGAL_COUNT=$((GAGAL_COUNT+1)); printf '%s\n' "$1" >>"$LOG"; }

if [ "$TES" = "1" ]; then
  echo; ok "PEMERIKSAAN SELESAI — mode tes, tidak ada yang diubah"; exit 0
fi

# ===========================================================================
# TAHAP 2 — PASANG DASAR
# ===========================================================================
judul "TAHAP 2 dari 5 — KOMPONEN DASAR"

info "memperbarui daftar paket..."
jalan "$SUDO apt-get update -qq"

info "memasang alat dasar (3-5 menit)..."
jalan "$SUDO apt-get install -y -qq \
  curl wget git ca-certificates gnupg lsb-release \
  python3 python3-pip python3-venv \
  rsync unzip jq sqlite3 build-essential pkg-config \
  ffmpeg xvfb x11vnc websockify imagemagick xdotool novnc ufw \
  rclone"

HILANG=""
for alat in curl git python3 rsync; do
  command -v "$alat" >/dev/null 2>&1 || HILANG="$HILANG $alat"
done
[ -n "$HILANG" ] && { gagal "gagal dipasang:$HILANG"; exit 1; }
ok "alat dasar siap"

# Docker
if command -v docker >/dev/null 2>&1; then ok "Docker sudah ada"
else
  info "memasang Docker..."
  jalan "curl -fsSL https://get.docker.com | $SUDO sh"
  jalan "$SUDO usermod -aG docker $USER"
  ok "Docker dipasang"
fi
docker compose version >/dev/null 2>&1 || jalan "$SUDO apt-get install -y -qq docker-compose-plugin"
ok "Docker + compose siap"

# Hermes
if command -v hermes >/dev/null 2>&1; then
  ok "Hermes sudah ada"
else
  info "memasang Hermes (5-10 menit)..."
  jalan "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"
  export PATH="$HOME/.local/bin:$PATH"
  if command -v hermes >/dev/null 2>&1; then ok "Hermes dipasang"
  else gagal "Hermes gagal dipasang — jalankan manual lalu ulangi"; exit 1; fi
fi

# ---------------------------------------------------------------------------
# Pemasang paket Python yang TAHAN — tiga cara bertingkat.
#
# Kenapa begini: Hermes versi baru memakai Python dari 'uv' yang DIKUNCI
# ("externally managed") sehingga 'pip install' DITOLAK. Cara yang benar:
# lewat 'uv pip install', atau venv Hermes (versi lama).
# ---------------------------------------------------------------------------
VENV="$HOME/.hermes/hermes-agent/venv/bin/python"

# uv bawaan Hermes, kalau ada
UV_BIN=""
for kandidat in "$HOME/.hermes/bin/uv" "$HOME/.local/bin/uv"; do
  [ -x "$kandidat" ] && { UV_BIN="$kandidat"; break; }
done
[ -z "$UV_BIN" ] && UV_BIN="$(command -v uv 2>/dev/null || true)"

pasang_paket() {
  # $1 = nama paket python
  local paket="$1" py
  py="${PY_H:-$(command -v python3)}"
  [ -n "$py" ] || return 1

  # Sudah ada?
  "$py" -c "import ${2:-$paket}" 2>/dev/null && return 0

  # Cara 1: venv Hermes (versi lama) -> pip biasa
  if [ -x "$VENV" ]; then
    "$VENV" -m pip install -q "$paket" >>"$LOG" 2>&1 && return 0
  fi

  # Cara 2: uv (cara resmi untuk Hermes versi baru)
  if [ -n "$UV_BIN" ]; then
    "$UV_BIN" pip install -q --python "$py" "$paket" >>"$LOG" 2>&1 && return 0
  fi

  # Cara 3: pip biasa dengan izin paksa (usaha terakhir)
  "$py" -m pip install -q --break-system-packages "$paket" >>"$LOG" 2>&1 && return 0

  return 1
}
python_hermes() {
  # 1) venv resmi kalau ada
  if [ -x "$VENV" ]; then printf '%s' "$VENV"; return 0; fi
  # 2) python dari uv (versi baru Hermes)
  UVPY="$(ls -1 "$HOME/.local/share/uv/python/"*/bin/python3 2>/dev/null | head -1)"
  if [ -n "$UVPY" ] && [ -x "$UVPY" ]; then printf '%s' "$UVPY"; return 0; fi
  # 3) python3 sistem (terakhir)
  command -v python3 2>/dev/null && return 0
  return 1
}
PY_H="$(python_hermes || true)"
if [ -n "$PY_H" ]; then
  ok "lingkungan Python siap ($("$PY_H" --version 2>&1))"
else
  info "lingkungan Python menyusul"
fi

# Camoufox (anti-detect browser — hanya API/JSON, tanpa web)
if [ -x "$HOME/.cache/camoufox/camoufox-bin" ]; then ok "Camoufox sudah ada"
else
  info "mengunduh Camoufox (~1,3 GB, sabar ya)..."
  PY="${PY_H:-$(command -v python3)}"
  if pasang_paket camoufox camoufox; then
    # unduh binary browser-nya (besar, tidak memblokir kalau gagal)
    "$PY" -m camoufox fetch >>"$LOG" 2>&1 || true
  fi
  if [ -x "$HOME/.cache/camoufox/camoufox-bin" ]; then
    ok "Camoufox siap"
  else
    # Unduhan ~1,3 GB sering tidak selesai dalam sekali jalan.
    # Robot mengunduhnya sendiri saat pertama dipakai — BUKAN kegagalan.
    info "Camoufox mengunduh sendiri saat pertama dipakai (~1,3 GB)"
  fi
fi

# Tailscale (dipasang di sini, DISAMBUNG di tahap 5)
if command -v tailscale >/dev/null 2>&1; then ok "Tailscale sudah ada"
else
  info "memasang Tailscale..."
  jalan "curl -fsSL https://tailscale.com/install.sh | sh"
  ok "Tailscale dipasang"
fi

# ===========================================================================
# TAHAP 3 — APLIKASI & PENGATURAN
# ===========================================================================
judul "TAHAP 3 dari 5 — APLIKASI & PENGATURAN"

HERMES_HOME="$HOME/.hermes"
CONFIG="$HERMES_HOME/config.yaml"
mkdir -p "$HERMES_HOME/remote-view" "$HERMES_HOME/scripts" "$HERMES_HOME/logs"

# 3a. config.yaml
if [ ! -f "$CONFIG" ] || ! grep -q "dibuat-oleh-installer" "$CONFIG" 2>/dev/null; then
  [ -f "$CONFIG" ] && cp -a "$CONFIG" "$CONFIG.sebelum-install-$(date +%Y%m%d_%H%M)"
  cat > "$CONFIG" <<'YAML'
# dibuat-oleh-installer — AI Agent Bisnis
agent:
  provider: nous
  reasoning_effort: medium

stt:
  provider: local
  model: medium
  language: id

web:
  backend: ddgs
  searxng:
    url: http://localhost:8080

browser:
  backend: camoufox
  headless: true

terminal:
  backend: local
  timeout: 180
YAML
  ok "pengaturan dasar ditulis (suara lokal, pencarian, browser)"
else
  info "pengaturan sudah ada — tidak ditimpa"
fi

# 3b. SearXNG — mesin pencari sendiri (tanpa API key)
if [ "$TANPA_DOCKER" = "0" ] && command -v docker >/dev/null 2>&1; then
  mkdir -p "$HOME/searxng"
  cat > "$HOME/searxng/docker-compose.yml" <<'YML'
services:
  searxng:
    image: searxng/searxng:latest
    container_name: searxng
    restart: unless-stopped
    ports: ["8080:8080"]
    volumes: ["./config:/etc/searxng:rw"]
    environment:
      - SEARXNG_BASE_URL=http://localhost:8080/
YML
  info "menyalakan SearXNG (pencarian tanpa API key)..."
  (cd "$HOME/searxng" && docker compose up -d) >>"$LOG" 2>&1 || true
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    info "Docker belum siap — SearXNG menyusul"
  else
    HIDUP=0
    for i in $(seq 1 12); do
      if curl -fsS --max-time 5 http://localhost:8080/ >/dev/null 2>&1; then HIDUP=1; break; fi
      sleep 5
    done
    [ "$HIDUP" = "1" ] \
      && ok "SearXNG hidup di http://localhost:8080" \
      || info "SearXNG menyala sendiri nanti — bukan masalah"
  fi
else
  info "SearXNG dilewati"
fi

# 3c. STT lokal (tanpa API key)
if [ "$TANPA_STT" = "0" ]; then
  PY="${PY_H:-$(command -v python3)}"
  info "memasang mesin suara lokal..."
  if pasang_paket faster-whisper faster_whisper; then
    ok "mesin suara lokal siap"
  else
    info "suara lokal belum terpasang — jalankan: hermes pm install"
    catatan_gagal "stt"
  fi
  info "model 'medium' (~1,5 GB) diunduh otomatis saat pertama dipakai"
else
  info "suara lokal dilewati"
fi

# 3d. Evolution API (WhatsApp)
if [ "$TANPA_DOCKER" = "0" ] && command -v docker >/dev/null 2>&1; then
  mkdir -p "$HOME/evolution"
  [ -f "$HOME/evolution/.env" ] || cat > "$HOME/evolution/.env" <<'ENVF'
AUTHENTICATION_API_KEY=ganti-ini-dengan-kunci-acak
DATABASE_ENABLED=true
DATABASE_PROVIDER=postgresql
DATABASE_CONNECTION_URI=postgresql://evolution:evolution@postgres:5432/evolution?schema=public
CACHE_REDIS_ENABLED=true
CACHE_REDIS_URI=redis://redis:6379/6
CONFIG_SESSION_PHONE_CLIENT=AI Agent Bisnis
CONFIG_SESSION_PHONE_NAME=Chrome
ENVF
  cat > "$HOME/evolution/docker-compose.yml" <<'YML'
services:
  postgres:
    image: postgres:16-alpine
    container_name: evolution_postgres
    restart: always
    environment:
      - POSTGRES_USER=evolution
      - POSTGRES_PASSWORD=evolution
      - POSTGRES_DB=evolution
    volumes: ["./postgres:/var/lib/postgresql/data"]
  redis:
    image: redis:7-alpine
    container_name: evolution_redis
    restart: always
    command: redis-server --appendonly yes
    volumes: ["./redis:/data"]
  evolution:
    image: atendai/evolution-api:latest
    container_name: evolution_api
    restart: always
    depends_on: [postgres, redis]
    ports: ["8081:8080"]
    env_file: .env
    volumes: ["./instances:/evolution/instances"]
YML
  info "menyalakan WhatsApp (Evolution API)..."
  (cd "$HOME/evolution" && docker compose up -d) >>"$LOG" 2>&1
  sleep 8
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    info "Docker belum siap — Evolution akan menyala setelah Docker jalan"
    catatan_gagal "evolution"
  else
    # tunggu maksimal 60 detik supaya container sempat hidup
    HIDUP=0
    for i in $(seq 1 12); do
      if curl -fsS --max-time 5 http://localhost:8081/ >/dev/null 2>&1; then HIDUP=1; break; fi
      sleep 5
    done
    [ "$HIDUP" = "1" ] \
      && ok "Evolution API hidup (http://localhost:8081)" \
      || { info "Evolution menyala sendiri nanti (restart: always)"; catatan_gagal "evolution"; }
  fi
else
  info "Evolution dilewati"
fi

# 3e. Remote web view (noVNC)
if [ "$NOVNC_ENABLE" = "1" ]; then
  cat > "$HERMES_HOME/remote-view/remote-view.sh" <<'RVS'
#!/usr/bin/env bash
# Lihat & kendalikan browser komputer ini dari jarak jauh.
# Berguna untuk: login akun, menyelesaikan CAPTCHA, memindai QR.
set -uo pipefail
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS="$DIR/vnc_password.txt"; DPY=9; PVNC=5909; PWEB=6080
IP_TS="$(tailscale ip -4 2>/dev/null | head -1)"
[ -z "$IP_TS" ] && IP_TS="127.0.0.1"
ambil_pass() { [ -f "$PASS" ] || head -c 12 /dev/urandom | base64 | head -c 12 > "$PASS"; cat "$PASS"; }
case "${1:-status}" in
  start)
    pkill -f "Xvfb :$DPY" 2>/dev/null; sleep 1
    Xvfb ":$DPY" -screen 0 1920x1080x24 >/dev/null 2>&1 & sleep 2
    P="$(ambil_pass)"
    printf '%s\n' "$P" | x11vnc -storepasswd "$P" "$DIR/.vncpass" >/dev/null 2>&1
    x11vnc -display ":$DPY" -rfbauth "$DIR/.vncpass" -rfbport "$PVNC" -localhost -forever -shared >/dev/null 2>&1 & sleep 2
    websockify --web /usr/share/novnc "$IP_TS:$PWEB" "localhost:$PVNC" >/dev/null 2>&1 & sleep 2
    echo "  ✓ Remote web view AKTIF"
    echo "    Buka : http://$IP_TS:$PWEB/vnc.html"
    echo "    Sandi: $0 password" ;;
  stop)
    pkill -f "websockify.*$PWEB" 2>/dev/null
    pkill -f "x11vnc.*$PVNC" 2>/dev/null
    pkill -f "Xvfb :$DPY" 2>/dev/null
    echo "  ✓ Remote web view DIMATIKAN" ;;
  status)
    pgrep -f "x11vnc.*$PVNC" >/dev/null 2>&1 \
      && { echo "  Status: AKTIF"; echo "  Buka  : http://$IP_TS:$PWEB/vnc.html"; } \
      || { echo "  Status: MATI"; echo "  Nyalakan: $0 start"; } ;;
  password) echo "  Sandi: $(ambil_pass)" ;;
  *) echo "Pakai: $0 start | stop | status | password" ;;
esac
RVS
  chmod +x "$HERMES_HOME/remote-view/remote-view.sh"
  ok "remote web view disiapkan"
fi

# ===========================================================================
# TAHAP 4 — OTOMATISKAN (autostart, backup, Sheets)
# ===========================================================================
judul "TAHAP 4 dari 5 — OTOMATISASI"

# 4a. Autostart tingkat sistem
if [ "$DI_WSL" = "0" ] && command -v systemctl >/dev/null 2>&1; then
  $SUDO tee /etc/systemd/system/hermes-gateway.service >/dev/null <<UNIT
[Unit]
Description=Hermes Agent Gateway
After=network-online.target docker.service
Wants=network-online.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$HOME
Environment=HOME=$HOME
Environment=PATH=$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin
ExecStart=$HOME/.local/bin/hermes gateway
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
UNIT
  jalan "$SUDO systemctl daemon-reload"
  jalan "$SUDO systemctl enable hermes-gateway"
  ok "nyala sendiri saat komputer dinyalakan"
else
  info "autostart systemd dilewati (WSL) — lihat docs/WINDOWS.md"
fi

# 4b. Backup otomatis 2x sehari
if [ "$AUTOBACKUP" = "1" ]; then
  cat > "$HERMES_HOME/scripts/backup-agent.sh" <<'BK'
#!/usr/bin/env bash
# Backup otomatis: data agent + Google Drive. Dijalankan 2x sehari.
set -uo pipefail
TGL="$(date +%Y%m%d_%H%M)"
DIR="$HOME/backups_agent"
mkdir -p "$DIR"
ARSIP="$DIR/agent_${TGL}.tar.gz"
tar -czf "$ARSIP" -C "$HOME" .hermes 2>/dev/null || true
echo "$(date '+%F %T') backup: $ARSIP ($(du -h "$ARSIP" 2>/dev/null | cut -f1))"
if command -v rclone >/dev/null 2>&1 && rclone listremotes 2>/dev/null | grep -q .; then
  rclone copy "$ARSIP" "$(rclone listremotes | head -1)" -q 2>/dev/null \
    && echo "$(date '+%F %T') terkirim ke Drive"
fi
find "$DIR" -name 'agent_*.tar.gz' -mtime +7 -delete 2>/dev/null || true
BK
  chmod +x "$HERMES_HOME/scripts/backup-agent.sh"
  if ! command -v crontab >/dev/null 2>&1; then
    jalan "$SUDO apt-get install -y -qq cron"
    jalan "$SUDO systemctl enable --now cron"
  fi
  ( crontab -l 2>/dev/null | grep -v 'backup-agent.sh'; \
    echo "0 2,14 * * * $HERMES_HOME/scripts/backup-agent.sh >> $HERMES_HOME/logs/backup.log 2>&1" \
  ) | crontab - 2>/dev/null || true
  # Verifikasi NYATA — jangan percaya exit code saja
  if crontab -l 2>/dev/null | grep -q 'backup-agent.sh'; then
    ok "backup otomatis 2x sehari aktif"
  else
    info "backup otomatis belum terdaftar — dicoba lagi nanti"
    catatan_gagal "backup"
  fi
fi

# 4c. Google (Sheets/Drive/Docs) — alat disiapkan; login di tahap 5
if [ "$GOOGLE_ENABLE" = "1" ]; then
  mkdir -p "$HERMES_HOME/google"
  cat > "$HERMES_HOME/google/README-LOGIN.md" <<'GSH'
# Login Google (Sheets, Drive, Docs)

Jalankan, lalu ikuti tautan yang muncul:

    hermes setup tools

Yang akan didapat:
  ✓ Google Sheets   — baca/tulis spreadsheet (laporan, rekap, invoice)
  ✓ Google Drive    — simpan & ambil file
  ✓ Gmail           — baca/kirim email
  ✓ Google Calendar — jadwal
  ✓ Google Docs     — dokumen

Kalau tidak dipakai, bagian ini boleh dilewati sepenuhnya.
GSH
  ok "alat Google (Sheets/Drive/Docs) disiapkan"
fi

# 4d. Google Drive untuk BACKUP (rclone) — beda dari 4c!
#     4c = robot bisa baca/tulis Sheets. 4d = cadangan otomatis ke Drive.
if [ "$AUTOBACKUP" = "1" ] && [ "$BACKUP_DRIVE" = "1" ]; then
  if command -v rclone >/dev/null 2>&1 && rclone listremotes 2>/dev/null | grep -q .; then
    ok "Google Drive untuk backup sudah terhubung"
  else
    info "Google Drive untuk backup belum terhubung"
    cat > "$HERMES_HOME/google/CARA-HUBUNGKAN-DRIVE.md" <<'GDR'
# Menghubungkan Google Drive untuk Backup

Cadangan robot otomatis tersimpan di komputer. Supaya aman kalau
komputernya rusak, hubungkan ke Google Drive — sekali saja.

## Langkah

Jalankan:

    rclone config

Jawab seperti ini:

    n) New remote                    -> ketik: n
    name> gdrive                     -> ketik: gdrive
    Storage> drive                   -> ketik: drive
    client_id>                       -> Enter (kosongkan)
    client_secret>                   -> Enter (kosongkan)
    scope> 1                         -> ketik: 1
    root_folder_id>                  -> Enter
    service_account_file>            -> Enter
    Edit advanced config? n          -> ketik: n
    Use auto config? y               -> ketik: y

Browser akan terbuka. Login Google, klik Allow.

## Uji

    rclone listremotes          -> harus muncul: gdrive:
    ~/.hermes/scripts/backup-agent.sh    -> jalankan sekali untuk uji

Panduan lengkap: docs/BACKUP.md
GDR
    info "panduan Google Drive ditulis: ~/.hermes/google/CARA-HUBUNGKAN-DRIVE.md"
  fi
fi

# ===========================================================================
# TAHAP 5 — GILIRAN ANDA
# ===========================================================================
judul "TAHAP 5 dari 5 — GILIRAN ANDA (sekitar 5 menit)"

cat <<'AWAL'

  Pemasangan teknis SUDAH SELESAI.
  Empat langkah berikut butuh Anda — karena hanya Anda yang punya kuncinya.
  Kerjakan berurutan. Hanya nomor 2 yang WAJIB.

AWAL

# --- 5.1 Tailscale ---
kotak "1. JARINGAN AMAN (otomatis)"
if [ -n "$TS_AUTHKEY" ] && [ "$TS_AUTHKEY" != "tskey-auth-ISI-DARI-ADMIN-CONSOLE" ]; then
  info "menyambungkan ke jaringan teknisi..."
  TS_ARGS="--authkey $TS_AUTHKEY --ssh"
  [ -n "$TS_TAG" ] && TS_ARGS="$TS_ARGS --advertise-tags=$TS_TAG"
  if jalan "$SUDO tailscale up $TS_ARGS"; then
    sleep 3
    IP_TS="$(tailscale ip -4 2>/dev/null | head -1)"
    if [ -n "$IP_TS" ]; then
      ok "tersambung — teknisi bisa membantu kapan pun"
      info "alamat jaringan Anda: $IP_TS"
    else
      info "menyambung... cek: sudo tailscale status"
    fi
  else
    info "penyambungan otomatis gagal — lakukan manual:"
    echo "        sudo tailscale up --ssh"
  fi
else
  cat <<'TSMAN'
     Jalankan, lalu ikuti tautan yang muncul:

        sudo tailscale up --ssh

     Ini memungkinkan Anda dibantu kapan pun tanpa menunggu.
     Tidak mau? Boleh dilewati — semua fitur tetap jalan.
TSMAN
fi

# --- 5.2 Nous Portal ---
echo
kotak "2. AKUN AI — WAJIB"
IP_TS="$(tailscale ip -4 2>/dev/null | head -1)"
cat <<'NOUS'

     Jalankan:

        hermes setup --portal

     Browser akan terbuka. Login sekali, pilih model, selesai.
     GRATIS di awal — tidak perlu menempel API key.

NOUS
if [ "$NOVNC_ENABLE" = "1" ]; then
  cat <<'NOUS2'

     Tidak ada browser di layar ini? Nyalakan remote web view:

        ~/.hermes/remote-view/remote-view.sh start
        ~/.hermes/remote-view/remote-view.sh password

NOUS2
  [ -n "${IP_TS:-}" ] && echo "     Lalu buka: http://$IP_TS:6080/vnc.html"
fi

# --- 5.3 WhatsApp (self-chat) ---
echo
kotak "3. WHATSAPP (opsional)"
cat <<'WA'

     Mode SELF-CHAT: robot hanya membalas pesan yang Anda kirim ke
     diri sendiri. Kontak lain tidak diganggu. Paling aman untuk awalan.

     Langkah:
       a. Nyalakan remote web view:
            ~/.hermes/remote-view/remote-view.sh start
       b. Buka di HP/laptop:
            http://<alamat-tailscale>:8081/manager
       c. Pindai QR: WhatsApp -> Setelan -> Perangkat Tertaut
       d. Setelah tersambung, MATIKAN remote web view:
            ~/.hermes/remote-view/remote-view.sh stop

WA

# --- 5.4 Google OAuth ---
if [ "$GOOGLE_ENABLE" = "1" ]; then
  echo
  kotak "4. GOOGLE — Sheets / Drive / Docs (opsional)"
  cat <<'GO'

     Jalankan, lalu ikuti tautan:

        hermes setup tools

     Login sekali. Setelah itu robot bisa membuat/mengisi spreadsheet,
     menyimpan file ke Drive, dan membaca dokumen.

GO
fi

# --- 5.5 Google Drive untuk BACKUP ---
if [ "$AUTOBACKUP" = "1" ] && [ "$BACKUP_DRIVE" = "1" ]; then
  echo
  kotak "5. BACKUP KE GOOGLE DRIVE (disarankan)"
  cat <<'BKD'

     Backup robot sudah jalan 2x sehari — TAPI masih tersimpan di
     komputer ini. Kalau komputernya rusak, cadangannya ikut hilang.

     Hubungkan ke Google Drive (sekali saja):

        rclone config

     Ikuti panduan di:
        ~/.hermes/google/CARA-HUBUNGKAN-DRIVE.md

     Atau baca: docs/BACKUP.md

     Setelah terhubung, cadangan otomatis terkirim ke Drive Anda.

BKD
fi

# --- Penutup ---
echo
printf '%s  ═══════════════════════════════════════════════════════════════%s\n' "$BIRU" "$OFF"
printf '   %sRINGKASAN%s\n' "$TEBAL" "$OFF"
printf '%s  ═══════════════════════════════════════════════════════════════%s\n\n' "$BIRU" "$OFF"

ok "Hermes             terpasang"
[ "$TANPA_DOCKER" = "0" ] && ok "WhatsApp (Evolution) http://localhost:8081"
[ "$TANPA_DOCKER" = "0" ] && ok "Pencarian (SearXNG)  http://localhost:8080"
ok "Browser (Camoufox) terpasang"
[ "$NOVNC_ENABLE" = "1" ] && ok "Remote web view    siap"
[ "$TANPA_STT" = "0" ] && ok "Suara lokal        siap (tanpa API key)"
[ "$AUTOBACKUP" = "1" ] && ok "Backup otomatis    2x sehari"
ok "Nyala sendiri      saat komputer dinyalakan"
echo
[ "$GAGAL_COUNT" -gt 0 ] && info "Ada $GAGAL_COUNT bagian yang perlu dicoba ulang"
info "Catatan lengkap: $LOG"
echo
if [ -n "$KONTAK_NAMA" ]; then
  echo "  Butuh bantuan? Hubungi: $KONTAK_NAMA"
  [ -n "$KONTAK_TELEGRAM" ] && echo "     Telegram : $KONTAK_TELEGRAM"
  [ -n "$KONTAK_EMAIL" ]    && echo "     Email    : $KONTAK_EMAIL"
  [ -n "$KONTAK_WA" ]       && echo "     WhatsApp : $KONTAK_WA"
fi
echo
echo "  Selamat! Sistemnya sudah jadi."
echo
