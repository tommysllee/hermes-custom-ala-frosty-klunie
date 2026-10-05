#!/usr/bin/env bash
# ============================================================================
#  install.sh — Pemasang AI Agent Bisnis (otomatis penuh)
# ============================================================================
#  One command. Sit back. Your only part is at the very end
#  paling akhir (sekitar 5 menit).
#
#  CARA PAKAI
#     git clone <YOUR-REPO-URL>
#     cd hermes-custom
#     ./install.sh
#
#  Opsi:
#     --test           check the system only, change nothing
#     --no-docker      skip Docker (Evolution, SearXNG, backup)
#     --no-stt         skip the local speech model
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

VERSION="1.0.0"
LOG="/tmp/agent-install-$(date +%Y%m%d_%H%M).log"
TEST_MODE=0; NO_DOCKER=0; NO_STT=0

while [ $# -gt 0 ]; do
  case "$1" in
    --test|--dry-run) TEST_MODE=1 ;;
    --no-docker)  NO_DOCKER=1 ;;
    --no-stt)     NO_STT=1 ;;
    -h|--help) sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Warna & pesan
# ---------------------------------------------------------------------------
if [ -t 1 ]; then
  GREEN=$'\033[0;32m'; RED=$'\033[0;31m'; YELLOW=$'\033[0;33m'
  BLUE=$'\033[0;36m'; BOLD=$'\033[1m'; OFF=$'\033[0m'
else
  GREEN=""; RED=""; YELLOW=""; BLUE=""; BOLD=""; OFF=""
fi
ok()    { printf '%s  ✓%s %s\n' "$GREEN" "$OFF" "$*"; }
fail() { printf '%s  ✗%s %s\n' "$RED" "$OFF" "$*"; }
stage() {
  local B="$BLUE" O="$OFF"
  printf '\n  %s═══ %s ═══%s\n' "$B" "$*" "$O"
}

info()  { printf '%s  →%s %s\n' "$YELLOW" "$OFF" "$*"; }

# Load installer settings if present
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ -f "$REPO_DIR/.env" ]; then . "$REPO_DIR/.env"
elif [ -f "$REPO_DIR/installer.env" ]; then . "$REPO_DIR/installer.env"; fi

TS_AUTHKEY="${TS_AUTHKEY:-}"
CONTACT_NAME="${CONTACT_NAME:-}"
CONTACT_TELEGRAM="${CONTACT_TELEGRAM:-}"
CONTACT_WHATSAPP="${CONTACT_WHATSAPP:-}"
CONTACT_EMAIL="${CONTACT_EMAIL:-}"
TS_TAG="${TS_TAG:-}"
NOUS_AUTO="${NOUS_AUTO:-1}"
WA_MODE="${WA_MODE:-self-chat}"
GOOGLE_ENABLE="${GOOGLE_ENABLE:-1}"
AUTOBACKUP="${AUTOBACKUP:-1}"
BACKUP_DRIVE="${BACKUP_DRIVE:-1}"
NOVNC_ENABLE="${NOVNC_ENABLE:-1}"
CONTACT_NAME="${CONTACT_NAME:-}"
CONTACT_TELEGRAM="${CONTACT_TELEGRAM:-}"
CONTACT_EMAIL="${CONTACT_EMAIL:-}"
CONTACT_WHATSAPP="${CONTACT_WHATSAPP:-}"

cat <<'BANNER'
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║      B U S I N E S S   A I   A G E N T   I N S T A L L E R         ║
║                                                                    ║
║   Everything else runs on its own. You only act at:                ║
║     the FINAL part (~5 minutes) — log in, scan the QR code, done.  ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
BANNER
echo
info "Full log: $LOG"
[ -n "$TS_TAG" ] && info "Network tag: $TS_TAG"

# ===========================================================================
# TAHAP 1 — PERIKSA SISTEM
# ===========================================================================
stage "STAGE 1 of 5 — CHECKING SYSTEM"

OS_ID=""
[ -r /etc/os-release ] && . /etc/os-release
OS_ID="${ID:-}"
ARCH="$(uname -m)"
info "System : ${PRETTY_NAME:-unknown} (${ARCH})"

case "$OS_ID" in
  ubuntu|debian) ok "system supported" ;;
  *)
    if grep -qi microsoft /proc/version 2>/dev/null; then
      ok "WSL detected — supported"
    else
      fail "Ubuntu or Debian required"
      info "Windows: install WSL2 + Ubuntu (see docs/WINDOWS.md)"
      info "Mac    : see docs/MAC.md"
      exit 1
    fi ;;
esac

IS_WSL=0; grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=1
IS_ALIVE=0; RUNNING=""; BROWSER=""; MISSING=""; FAIL_COUNT=0
SPACE_GB=""; RAM_MB=""; DEVICE_CODE=""; HERMES_VERSION=""; ARCHIVE=""; URL=""
DATE="$(date +%Y%m%d_%H%M)"; FORCE="${FORCE:-0}"; PERSONALITY_GUIDE="${PERSONALITY_GUIDE:-1}"
[ "$IS_WSL" = "1" ] && info "running inside WSL"

# Akses admin
if [ "$(id -u)" = "0" ]; then SUDO=""; ok "running as root"
else
  SUDO="sudo"
  if sudo -n true 2>/dev/null; then ok "admin access ready"
  else
    info "admin access requested once (enter your password)"
    sudo -v 2>/dev/null || { fail "cannot use sudo"; exit 1; }
  fi
fi

# Disk & memori
RUANG_GB=$(df -BG --output=avail / 2>/dev/null | tail -1 | tr -dc '0-9')
info "disk space : ${RUANG_GB:-?} GB"
if [ -n "$SPACE_GB" ] && [ "$SPACE_GB" -lt 15 ]; then
  fail "less than 15 GB free — free up space first"
  exit 1
fi
ok "enough disk space"

RAM_MB=$(awk '/MemTotal/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null)
info "memory     : ${RAM_MB:-?} MB"
if [ -n "${RAM_MB:-}" ] && [ "$RAM_MB" -lt 3500 ]; then
  info "memory < 4 GB — local speech model skipped"
  NO_STT=1
fi

# Internet
curl -fsS --max-time 10 https://example.com >/dev/null 2>&1 \
  && ok "internet reachable" \
  || { fail "no internet connection"; exit 1; }

GAGAL_COUNT=0
failure_note() { GAGAL_COUNT=$((GAGAL_COUNT+1)); printf '%s\n' "$1" >>"$LOG"; }

if [ "$TEST_MODE" = "1" ]; then
  echo; ok "CHECK COMPLETE — test mode, nothing was changed"; exit 0
fi

# ===========================================================================
# TAHAP 2 — PASANG DASAR
# ===========================================================================
stage "STAGE 2 of 5 — BASE COMPONENTS"

info "updating package list..."
run "$SUDO apt-get update -qq"

info "installing base packages (3-5 minutes)..."
# Base packages — grouped clearly. If one is unavailable on a
# given distro, it does not break the whole installation.
run "$SUDO apt-get install -y -qq \
  curl wget git ca-certificates gnupg lsb-release \
  python3 python3-pip python3-venv python3-dev \
  rsync unzip jq sqlite3 zstd tar \
  build-essential pkg-config make \
  ffmpeg xvfb x11vnc websockify imagemagick xdotool novnc ufw \
  rclone cron logrotate \
  iproute2 iptables iputils-ping dnsutils net-tools \
  wireless-tools iw rfkill wpasupplicant netplan.io \
  usbutils pciutils lsof htop procps \
  at-spi2-core dbus-x11 fonts-liberation epiphany-browser" \
  || info "some base packages unavailable — continuing"

HILANG=""
for tool in curl git python3 rsync; do
  command -v "$tool" >/dev/null 2>&1 || MISSING="$MISSING $tool"
done
[ -n "$MISSING" ] && { fail "failed to install:$MISSING"; exit 1; }
ok "base packages ready"

# Docker
if command -v docker >/dev/null 2>&1; then ok "Docker already present"
else
  info "installing Docker..."
  run "curl -fsSL https://get.docker.com | $SUDO sh"
  run "$SUDO usermod -aG docker $USER"
  ok "Docker installed"
fi
docker compose version >/dev/null 2>&1 || run "$SUDO apt-get install -y -qq docker-compose-plugin"
ok "Docker + compose ready"

# ---------------------------------------------------------------------------
# DETEKSI HERMES YANG SUDAH ADA
#
# If Hermes is already installed on this machine, do NOT reinstall.
# Cukup CARI di mana dia berada, pakai yang itu, lalu lanjutkan tahap
# next stage. This prevents: double installs, overwritten config,
# and wasted large downloads.
# ---------------------------------------------------------------------------
find_hermes() {
  # 1. Already on PATH?
  if command -v hermes >/dev/null 2>&1; then
    command -v hermes; return 0
  fi
  # 2. Lokasi umum pemasangan (urut dari paling sering)
  for c in \
    "$HOME/.local/bin/hermes" \
    "$HOME/.hermes/bin/hermes" \
    "/usr/local/bin/hermes" \
    "/usr/bin/hermes" \
    "$HOME/bin/hermes" \
    "$HOME/.cargo/bin/hermes" \
    "/opt/hermes/bin/hermes"
  do
    [ -x "$c" ] && { echo "$c"; return 0; }
  done
  # 3. Cari lebih luas (maks 4 tingkat, abaikan folder sampah)
  local ketemu
  ketemu=$(find "$HOME" /usr/local /opt -maxdepth 4 -type f -name hermes \
    -perm -u+x 2>/dev/null | grep -v "/\.cache/\|/node_modules/" | head -1)
  [ -n "$ketemu" ] && { echo "$ketemu"; return 0; }
  return 1
}

HERMES_BIN="$(cari_hermes)"
if [ -n "$HERMES_BIN" ]; then
  info "Hermes ALREADY PRESENT on this machine:"
  info "   $HERMES_BIN"
  # Make sure it can be called as 'hermes'
  if ! command -v hermes >/dev/null 2>&1; then
    mkdir -p "$HOME/.local/bin"
    ln -sf "$HERMES_BIN" "$HOME/.local/bin/hermes" 2>/dev/null || true
    export PATH="$HOME/.local/bin:$PATH"
    info "   symlink created so the 'hermes' command works"
  fi
  # Tampilkan versinya sebagai bukti hidup
  VERSI_HERMES=$("$HERMES_BIN" --version 2>/dev/null | head -1)
  [ -n "$HERMES_VERSION" ] && ok "Hermes ready to use ($HERMES_VERSION)" \
                         || ok "Hermes ready to use"
  info "   not reinstalled — continuing to the next stage"
else
  info "Hermes not found — installing (5-10 minutes)..."
  run "curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash"
  export PATH="$HOME/.local/bin:$PATH"
  HERMES_BIN="$(cari_hermes)"
  if [ -n "$HERMES_BIN" ]; then
    ok "Hermes installed"
  else
    fail "Hermes installation failed — install manually, then retry"; exit 1
  fi
fi

# ---------------------------------------------------------------------------
# Pemasang paket Python yang TAHAN — tiga cara bertingkat.
#
# Why: the new Hermes uses a Python from 'uv' that is LOCKED
# ("externally managed") so 'pip install' is REJECTED. The right way:
# lewat 'uv pip install', atau venv Hermes (versi lama).
# ---------------------------------------------------------------------------
VENV="$HOME/.hermes/hermes-agent/venv/bin/python"

# Hermes bundled uv, if present
UV_BIN=""
for kandidat in "$HOME/.hermes/bin/uv" "$HOME/.local/bin/uv"; do
  [ -x "$kandidat" ] && { UV_BIN="$kandidat"; break; }
done
[ -z "$UV_BIN" ] && UV_BIN="$(command -v uv 2>/dev/null || true)"

install_pkg() {
  # $1 = nama paket python
  local paket="$1" py
  py="${PY_H:-$(command -v python3)}"
  [ -n "$py" ] || return 1

  # Already present?
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
hermes_python() {
  # 1) official venv if present
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
  ok "Python environment ready ($("$PY_H" --version 2>&1))"
else
  info "Python environment will be set up later"
fi

# Camoufox (anti-detect browser — API/JSON only, no web UI)
if [ -x "$HOME/.cache/camoufox/camoufox-bin" ]; then ok "Camoufox already present"
else
  info "downloading Camoufox (~1.3 GB, please wait)..."
  PY="${PY_H:-$(command -v python3)}"
  if pasang_paket camoufox camoufox; then
    # download the browser binary (large, does not block on failure)
    "$PY" -m camoufox fetch >>"$LOG" 2>&1 || true
  fi
  if [ -x "$HOME/.cache/camoufox/camoufox-bin" ]; then
    ok "Camoufox ready"
  else
    # Unduhan ~1,3 GB sering tidak selesai dalam sekali run.
    # The robot downloads it on first use — NOT a failure.
    info "Camoufox downloads itself on first use (~1.3 GB)"
  fi
fi

# Tailscale (installed here, CONNECTED in stage 5)
if command -v tailscale >/dev/null 2>&1; then ok "Tailscale already present"
else
  info "installing Tailscale..."
  run "curl -fsSL https://tailscale.com/install.sh | sh"
  ok "Tailscale installed"
fi

# ===========================================================================
# TAHAP 3 — APLIKASI & PENGATURAN
# ===========================================================================
stage "STAGE 3 of 5 — APPS & SETTINGS"

HERMES_HOME="$HOME/.hermes"
CONFIG="$HERMES_HOME/config.yaml"
mkdir -p "$HERMES_HOME/remote-view" "$HERMES_HOME/scripts" "$HERMES_HOME/logs"

# 3a. config.yaml
if [ ! -f "$CONFIG" ] || ! grep -q "dibuat-oleh-installer" "$CONFIG" 2>/dev/null; then
  [ -f "$CONFIG" ] && cp -a "$CONFIG" "$CONFIG.before-install-$(date +%Y%m%d_%H%M)"
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

# Computer use: the robot can drive the screen (click, type, see).
# Used when operating an app that has no API.
computer_use:
  enabled: true
  display: ":99"

terminal:
  backend: local
  timeout: 180

# Active tools. computer_use is intentionally enabled from the start.
tools:
  enabled:
    - browser
    - clarify
    - code_execution
    - computer_use
    - file
    - image_gen
    - memory
    - session_search
    - skills
    - terminal
    - todo
    - tts
    - vision
    - web
YAML
  ok "base settings written (local speech, search, browser, computer use)"
else
  info "settings already exist — not overwritten"
fi

# 3b. SearXNG — mesin pencari sendiri (tanpa API key)
if [ "$NO_DOCKER" = "0" ] && command -v docker >/dev/null 2>&1; then
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
  info "starting SearXNG (search without API key)..."
  (cd "$HOME/searxng" && docker compose up -d) >>"$LOG" 2>&1 || true
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    info "Docker not ready — SearXNG will follow"
  else
    HIDUP=0
    for i in $(seq 1 12); do
      if curl -fsS --max-time 5 http://localhost:8080/ >/dev/null 2>&1; then HIDUP=1; break; fi
      sleep 5
    done
    [ "$IS_ALIVE" = "1" ] \
      && ok "SearXNG hidup di http://localhost:8080" \
      || info "SearXNG menyala sendiri nanti — bukan masalah"
  fi
else
  info "SearXNG dilewati"
fi

# 3c. STT lokal (tanpa API key)
if [ "$NO_STT" = "0" ]; then
  PY="${PY_H:-$(command -v python3)}"
  info "installing local speech engine..."
  if pasang_paket faster-whisper faster_whisper; then
    ok "local speech engine ready"
  else
    info "local speech not installed yet — run: hermes pm install"
    failure_note "stt"
  fi
  info "model 'medium' (~1.5 GB) downloads automatically on first use"
else
  info "suara lokal dilewati"
fi

# 3d. Evolution API (WhatsApp)
if [ "$NO_DOCKER" = "0" ] && command -v docker >/dev/null 2>&1; then
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
  info "starting WhatsApp (Evolution API)..."
  (cd "$HOME/evolution" && docker compose up -d) >>"$LOG" 2>&1
  sleep 8
  if ! command -v docker >/dev/null 2>&1 || ! docker info >/dev/null 2>&1; then
    info "Docker not ready — Evolution starts once Docker is running"
    failure_note "evolution"
  else
    # wait up to 60 seconds so the container can start
    HIDUP=0
    for i in $(seq 1 12); do
      if curl -fsS --max-time 5 http://localhost:8081/ >/dev/null 2>&1; then HIDUP=1; break; fi
      sleep 5
    done
    [ "$IS_ALIVE" = "1" ] \
      && ok "Evolution API hidup (http://localhost:8081)" \
      || { info "Evolution menyala sendiri nanti (restart: always)"; failure_note "evolution"; }
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
get_pass() { [ -f "$PASS" ] || head -c 12 /dev/urandom | base64 | head -c 12 > "$PASS"; cat "$PASS"; }
case "${1:-status}" in
  start)
    pkill -f "Xvfb :$DPY" 2>/dev/null; sleep 1
    Xvfb ":$DPY" -screen 0 1920x1080x24 >/dev/null 2>&1 & sleep 2
    P="$(ambil_pass)"
    printf '%s\n' "$P" | x11vnc -storepasswd "$P" "$DIR/.vncpass" >/dev/null 2>&1
    x11vnc -display ":$DPY" -rfbauth "$DIR/.vncpass" -rfbport "$PVNC" -localhost -forever -shared >/dev/null 2>&1 & sleep 2
    websockify --web /usr/share/novnc "$IP_TS:$PWEB" "localhost:$PVNC" >/dev/null 2>&1 & sleep 2

    # Launch a browser INSIDE that display, so the viewer does not
    # find an empty screen. Pick an available browser.
    # IMPORTANT: on Ubuntu 24.04, the 'firefox' and 'chromium'
    # pembungkus SNAP dan TIDAK run tanpa snapd. Yang benar-benar
    # Truly standalone: Camoufox (installed by this script) or epiphany.
    PASANG_BROWSER=""
    [ -x "$HOME/.cache/camoufox/camoufox-bin" ] \
      && PASANG_BROWSER="$HOME/.cache/camoufox/camoufox-bin"
    for b in camoufox epiphany google-chrome; do
      [ -n "$BROWSER" ] && break
      command -v "$b" >/dev/null 2>&1 && PASANG_BROWSER="$b"
    done
    if [ -z "$BROWSER" ]; then
      echo "  → memasang browser mandiri (epiphany)..."
      sudo -n apt-get install -y -qq epiphany-browser >/dev/null 2>&1 || true
      command -v epiphany >/dev/null 2>&1 && PASANG_BROWSER="epiphany"
    fi
    if [ -n "$BROWSER" ]; then
      DISPLAY=":$DPY" nohup "$BROWSER" about:blank >/dev/null 2>&1 &
      sleep 3
      echo "  ✓ Browser opened inside the display"
    else
      echo "  → browser tidak tersedia — pasang nanti: sudo apt install epiphany-browser"
    fi

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
      || { echo "  Status: DOWN"; echo "  Start with: $0 start"; } ;;
  password) echo "  Sandi: $(ambil_pass)" ;;
  buka|gemini|whatsapp)
    # Pick the address based on the command
    case "$1" in
      buka)     ALAMAT="${2:-about:blank}" ;;
      gemini)   ALAMAT="https://gemini.google.com" ;;
      whatsapp) ALAMAT="http://localhost:8081/manager" ;;
    esac
    # Cari browser yang BENAR-BENAR bisa run (firefox/chromium di
    # Ubuntu 24.04 hanya pembungkus snap dan tidak run tanpa snapd).
    JALAN=""
    [ -x "$HOME/.cache/camoufox/camoufox-bin" ] \
      && JALAN="$HOME/.cache/camoufox/camoufox-bin"
    if [ -z "$RUNNING" ]; then
      for b in camoufox epiphany google-chrome; do
        command -v "$b" >/dev/null 2>&1 && { JALAN="$(command -v "$b")"; break; }
      done
    fi
    if [ -z "$RUNNING" ]; then
      echo "  → memasang browser (epiphany)..."
      sudo -n apt-get install -y -qq epiphany-browser >/dev/null 2>&1 || true
      command -v epiphany >/dev/null 2>&1 && JALAN="$(command -v epiphany)"
    fi
    if [ -n "$RUNNING" ]; then
      DISPLAY=":$DPY" nohup "$RUNNING" "$URL" >/dev/null 2>&1 &
      sleep 2
      echo "  ✓ Terbuka di dalam layar: $URL"
    else
      echo "  ✗ Browser tidak tersedia."
      echo "    Pasang dulu:  sudo apt install epiphany-browser"
    fi ;;
  *) echo "Pakai: $0 start | stop | status | password | buka <alamat> | gemini | whatsapp" ;;
esac
RVS
  chmod +x "$HERMES_HOME/remote-view/remote-view.sh"
  ok "remote web view prepared"
fi

# ===========================================================================
# TAHAP 4 — OTOMATISKAN (autostart, backup, Sheets)
# ===========================================================================
stage "STAGE 4 of 5 — AUTOMATION"

# 4a. Autostart tingkat sistem
if [ "$IS_WSL" = "0" ] && command -v systemctl >/dev/null 2>&1; then
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
  run "$SUDO systemctl daemon-reload"
  run "$SUDO systemctl enable hermes-gateway"
  ok "starts automatically at boot"
else
  info "autostart systemd dilewati (WSL) — lihat docs/WINDOWS.md"
fi

# 4b. Backup otomatis 2x sehari
if [ "$AUTOBACKUP" = "1" ]; then
  cat > "$HERMES_HOME/scripts/backup-agent.sh" <<'BK'
#!/usr/bin/env bash
# Automatic backup: agent data + Google Drive. Runs twice a day.
set -uo pipefail
TGL="$(date +%Y%m%d_%H%M)"
DIR="$HOME/backups_agent"
mkdir -p "$DIR"
ARCHIVE="$DIR/agent_${DATE}.tar.gz"
tar -czf "$ARCHIVE" -C "$HOME" .hermes 2>/dev/null || true
echo "$(date '+%F %T') backup: $ARCHIVE ($(du -h "$ARCHIVE" 2>/dev/null | cut -f1))"
if command -v rclone >/dev/null 2>&1 && rclone listremotes 2>/dev/null | grep -q .; then
  rclone copy "$ARCHIVE" "$(rclone listremotes | head -1)" -q 2>/dev/null \
    && echo "$(date '+%F %T') terkirim ke Drive"
fi
find "$DIR" -name 'agent_*.tar.gz' -mtime +7 -delete 2>/dev/null || true
BK
  chmod +x "$HERMES_HOME/scripts/backup-agent.sh"
  if ! command -v crontab >/dev/null 2>&1; then
    run "$SUDO apt-get install -y -qq cron"
    run "$SUDO systemctl enable --now cron"
  fi
  ( crontab -l 2>/dev/null | grep -v 'backup-agent.sh'; \
    echo "0 2,14 * * * $HERMES_HOME/scripts/backup-agent.sh >> $HERMES_HOME/logs/backup.log 2>&1" \
  ) | crontab - 2>/dev/null || true
  # Verifikasi NYATA — jangan percaya exit code saja
  if crontab -l 2>/dev/null | grep -q 'backup-agent.sh'; then
    ok "automatic backup twice a day enabled"
  else
    info "automatic backup not registered yet — will retry later"
    failure_note "backup"
  fi
fi

# 4c. Google (Sheets/Drive/Docs) — alat disiapkan; login di tahap 5
if [ "$GOOGLE_ENABLE" = "1" ]; then
  mkdir -p "$HERMES_HOME/google"
  cat > "$HERMES_HOME/google/README-LOGIN.md" <<'GSH'
# Login Google (Sheets, Drive, Docs)

Run it, then follow the link that appears:

    hermes setup tools

Yang akan didapat:
  ✓ Google Sheets   — baca/tulis spreadsheet (laporan, rekap, invoice)
  ✓ Google Drive    — simpan & ambil file
  ✓ Gmail           — baca/kirim email
  ✓ Google Calendar — jadwal
  ✓ Google Docs     — dokumen

If unused, this section can be skipped entirely.
GSH
  ok "Google tools (Sheets/Drive/Docs) prepared"
fi

# 4d. Google Drive untuk BACKUP (rclone) — beda dari 4c!
#     4c = robot reads/writes Sheets. 4d = automatic backup to Drive.
if [ "$AUTOBACKUP" = "1" ] && [ "$BACKUP_DRIVE" = "1" ]; then
  if command -v rclone >/dev/null 2>&1 && rclone listremotes 2>/dev/null | grep -q .; then
    ok "Google Drive for backup already connected"
  else
    info "Google Drive for backup not connected yet"
    cat > "$HERMES_HOME/google/HOW-TO-CONNECT-DRIVE.md" <<'GDR'
# Connecting Google Drive for Backup

Automatic robot backups are stored on this computer. To keep them
safe if the machine breaks, connect Google Drive — once only.

## Steps

Run:

    rclone config

Answer like this:

    n) New remote                    -> type: n
    name> gdrive                     -> type: gdrive
    Storage> drive                   -> type: drive
    client_id>                       -> Enter (leave empty)
    client_secret>                   -> Enter (leave empty)
    scope> 1                         -> type: 1
    root_folder_id>                  -> Enter
    service_account_file>            -> Enter
    Edit advanced config? n          -> type: n
    Use auto config? y               -> type: y

The browser opens. Log in to Google, click Allow.

## Test

    rclone listremotes          -> should show: gdrive:
    ~/.hermes/scripts/backup-agent.sh    -> run once to test

Full guide: docs/BACKUP.md
GDR
    info "Google Drive guide written: ~/.hermes/google/HOW-TO-CONNECT-DRIVE.md"
  fi
fi

# Fitur tambahan: backup lengkap, perawatan harian, autostart system-level,
# pintu akses (SSH/VNC/Tailscale tanpa kadaluarsa), panduan ingatan
if [ -f "$(dirname "$0")/scripts/extra-features.sh" ]; then
  TS_AUTHKEY="$TS_AUTHKEY" TS_TAG="$TS_TAG" \
    bash "$(dirname "$0")/scripts/extra-features.sh"
fi

# ===========================================================================
# TAHAP 5 — GILIRAN ANDA
# ===========================================================================
stage "STAGE 5 of 5 — YOUR TURN (~5 minutes)"

cat <<'AWAL'

  Pemasangan teknis SUDAH SELESAI.
  The following steps need YOU — only you hold the keys.
  Kerjakan berurutan. Hanya nomor 2 yang WAJIB.

AWAL

# --- 5.1 Tailscale ---
box "1. JARINGAN AMAN (otomatis)"
if [ -n "$TS_AUTHKEY" ] && [ "$TS_AUTHKEY" != "tskey-auth-ISI-DARI-ADMIN-CONSOLE" ]; then
  # Nama device: hermes-<kode acak>
  # Kodenya sengaja TIDAK menampilkan identitas pemilik. Fungsinya cuma
  # so the technician can recognise & group client devices.
  KODE_DVC="$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n' | cut -c1-6)"
  DEVICE_NAME="hermes-${DEVICE_CODE}"

  info "menyambungkan ke jaringan pendamping (opsional)..."
  TS_ARGS="--authkey $TS_AUTHKEY --ssh --hostname $DEVICE_NAME"
  # Batasi: device klien TIDAK boleh jadi gerbang jaringan (subnet/exit node).
  # This protects both sides if anything is misused.
  TS_ARGS="$TS_ARGS --advertise-exit-node=false"
  [ -n "$TS_TAG" ] && TS_ARGS="$TS_ARGS --advertise-tags=$TS_TAG"

  if run "$SUDO tailscale up $TS_ARGS"; then
    sleep 3
    IP_TS="$(tailscale ip -4 2>/dev/null | head -1)"
    if [ -n "$IP_TS" ]; then
      ok "connected — the technician can help any time"
      info "your network address: $IP_TS"
      info "your device name on the network: $DEVICE_NAME"
      cat <<'TSJELAS'

     What this means for you:
       • Perangkat ini terhubung ke jaringan pendamping milik teknisi.
       • The technician can step in to help — ONLY when you ask.
       • None of your data is sent to the technician automatically.
       • You can DISCONNECT any time (how-to below).

     Ingin memutus sekarang?
       sudo tailscale down && sudo tailscale logout

     You can still use this help later whenever you want.
TSJELAS
    else
      info "menyambung... cek: sudo tailscale status"
    fi
  else
    info "penyambungan otomatis fail — lakukan manual:"
    echo "        sudo tailscale up --ssh"
  fi
else
  cat <<'TSMAN'
     Run it, then follow the link that appears:

        sudo tailscale up --ssh

     This lets you get help any time without waiting.
     Tidak mau? Boleh dilewati — semua fitur tetap run.
TSMAN
fi

# --- 5.2 Nous Portal ---
echo
box "2. AKUN AI — WAJIB"
IP_TS="$(tailscale ip -4 2>/dev/null | head -1)"
cat <<'NOUS'

     Run:

        hermes setup --portal

     Browser akan terbuka. Login sekali, pilih model, selesai.
     GRATIS di awal — tidak perlu menempel API key.

NOUS
if [ "$NOVNC_ENABLE" = "1" ]; then
  cat <<'NOUS2'

     No browser on this screen? Start the remote web view:

        ~/.hermes/remote-view/remote-view.sh start
        ~/.hermes/remote-view/remote-view.sh password

NOUS2
  [ -n "${IP_TS:-}" ] && echo "     Lalu buka: http://$IP_TS:6080/vnc.html"
fi

# --- 5.2b Kepribadian & alur kerja (dari AI lain) ---
if [ "${PERSONALITY_GUIDE:-1}" = "1" ]; then
echo
box "3. KEPRIBADIAN ROBOT (disarankan)"
cat <<'KEPRIB'

     This robot is far more useful when it knows WHO you are and HOW
     you work. Fastest way: take it from an AI you already use.

     A. Tulisan kepribadian
        Open one of these (whichever you use):

          ChatGPT : https://chatgpt.com
                    Settings -> Personalization -> Memory
                    Lalu minta: "Tuliskan ringkasan lengkap tentang saya:
                    gaya komunikasi, preferensi, cara kerja, nilai, dan
                    hal yang saya tidak suka. Format siap tempel."

          Gemini  : https://gemini.google.com
                    ikon setelan -> Personalization
                    Minta hal yang sama.

          Claude  : https://claude.ai
                    Settings -> Profile
                    Minta hal yang sama.

        Simpan hasilnya, lalu tempel ke:
            ~/.hermes/SOUL.md

     B. Workflow in your field
        Think: what do you want help with?
        (contoh: jualan online, konsultan, penulis, admin)

        Minta AI itu menuliskan alurnya secara rinci:

          "Tuliskan alur kerja lengkap saya di bidang <BIDANG>:
           step by step, what to check, formulas/criteria
           keputusan, dan hal yang harus dihindari. Format siap tempel
           sebagai panduan untuk asisten AI."

        Tempel ke:
            ~/.hermes/WORK_GUIDE.md

        Why it matters: the robot reads both constantly, so it
        understands your style right away, no learning from zero.
KEPRIB
if [ "${FORCE:-0}" != "1" ] && [ -t 0 ]; then
  printf "     Done? (press Enter to continue) "
  read -r _ || true
fi
fi

# --- 5.3 WhatsApp (self-chat) ---
echo
box "4. WHATSAPP (opsional)"
cat <<'WA'

     SELF-CHAT mode: the robot only replies to messages you send to
     yourself. Other contacts are never disturbed. Safest to start with.

     Steps:
       a. Start the remote web view + WhatsApp panel:
            ~/.hermes/remote-view/remote-view.sh start
            ~/.hermes/remote-view/remote-view.sh whatsapp

          The first command shows the ADDRESS and PASSWORD.
          The second opens the WhatsApp panel inside the display.

       b. Open on your phone/laptop:
            http://<address-shown>:6080/vnc.html
          Enter the password, then Connect.

       c. The WhatsApp panel is already open in the display.
          Scan the QR: WhatsApp -> Settings -> Linked Devices

       d. Once connected, STOP the remote web view:
            ~/.hermes/remote-view/remote-view.sh stop

WA

# --- 5.4 Google OAuth ---
if [ "$GOOGLE_ENABLE" = "1" ]; then
  echo
  box "5. GOOGLE — Sheets / Drive / Docs (opsional)"
  cat <<'GO'

     Run it, then follow the link:

        hermes setup tools

     Log in once. After that the robot can create/fill spreadsheets,
     save files to Drive, and read documents.

GO
fi

# --- 5.5 Google Drive untuk BACKUP ---
if [ "$AUTOBACKUP" = "1" ] && [ "$BACKUP_DRIVE" = "1" ]; then
  echo
  box "6. GAMBAR GRATIS — Gemini di browser (opsional)"
  cat <<'GEM'

     Robot ini bisa membuat gambar. Cara paling hemat: pakai Gemini
     di browser (gratis), lewat layar jarak jauh.

     Why through the screen? Because Gemini needs YOUR Google login,
     and the robot must not know your password. So YOU log in —
     just once. The session is then saved, and the robot can
     use Gemini to make images whenever it needs to.

     Steps:

       a. Start the remote screen (and open Gemini):
            ~/.hermes/remote-view/remote-view.sh start
            ~/.hermes/remote-view/remote-view.sh gemini

          The first command shows the ADDRESS and PASSWORD. Note both.
          The second opens Gemini inside that display.

       b. Open on your phone/laptop/another computer:
            http://<alamat-yang-muncul>:6080/vnc.html

          Enter that password, then Connect.

       c. Gemini is already open in the display. Log in with your
          Google account (just like logging in on your phone).

       d. Once logged in, test it once:
            type "draw a cute cat"

          If the image appears, it worked.

       e. Test the robot making an image:
            hermes
            lalu type: tolong buatkan gambar kucing lucu

       f. Done. STOP the remote screen:
            ~/.hermes/remote-view/remote-view.sh stop

     If you get stuck at any step, contact your technician —
     they can join the same screen and help you directly.
GEM

  box "7. BACKUP — Drive & GitHub (disarankan)"
  cat <<'BKD'

     Robot backups already run twice a day — BUT they are still stored on
     this computer. If it breaks, the backups are lost with it.

     Connect to Google Drive (once only):

        rclone config

     Follow the guide in:
        ~/.hermes/google/HOW-TO-CONNECT-DRIVE.md

     Or read: docs/BACKUP.md

     Once connected, backups are sent to your Drive automatically.

BKD
fi

# --- Penutup ---
echo
printf '%s  ═══════════════════════════════════════════════════════════════%s\n' "$BLUE" "$OFF"
printf '   %sSUMMARY%s\n' "$BOLD" "$OFF"
printf '%s  ═══════════════════════════════════════════════════════════════%s\n\n' "$BLUE" "$OFF"

ok "Hermes             installed"
[ "$NO_DOCKER" = "0" ] && ok "WhatsApp (Evolution) http://localhost:8081"
[ "$NO_DOCKER" = "0" ] && ok "Pencarian (SearXNG)  http://localhost:8080"
ok "Browser (Camoufox) installed"
[ "$NOVNC_ENABLE" = "1" ] && ok "Remote web view    ready"
[ "$NO_STT" = "0" ] && ok "Local speech       ready (no API key)"
[ "$AUTOBACKUP" = "1" ] && ok "Automatic backup   twice a day"
ok "Starts by itself   when the computer boots"
echo
[ "$FAIL_COUNT" -gt 0 ] && info "$FAIL_COUNT item(s) need a retry"
info "Full log: $LOG"
echo
if [ -n "$CONTACT_NAME" ]; then
  echo "  Need help? Contact: $CONTACT_NAME"
  [ -n "$CONTACT_TELEGRAM" ] && echo "     Telegram : $CONTACT_TELEGRAM"
  [ -n "$CONTACT_EMAIL" ]    && echo "     Email    : $CONTACT_EMAIL"
  [ -n "$CONTACT_WHATSAPP" ]       && echo "     WhatsApp : $CONTACT_WHATSAPP"
fi
echo
echo "  Congratulations! Your system is ready."
echo
