#!/usr/bin/env bash
# ============================================================================
# 2a-tools-linubu.sh — AUTOINSTALL ALAT DASAR + STACK DOCKER + SETTING MODEL ALAT
# ============================================================================
# Bagian (A) a.2 dari prompt-2-steps/2-user-allOS-in-hermeschat.md:
#   - alat dasar apt (git, ffmpeg, xvfb, novnc, rclone, postgres, redis, dll)
#   - SearXNG + Evolution API di Docker
#   - camofox (browser automation)
#   - STT lokal whisper-medium (faster-whisper)
#   - computer use dinyalakan
#   - routing web search: keyless free tier + SearXNG sebagai cadangan
#
# Jalankan:
#   curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/2a-tools-linubu.sh -o /tmp/2a.sh && bash /tmp/2a.sh
#
# Opsi:
#   TANPA_DOCKER=1     lewati semua stack docker
#   TANPA_FIRECRAWL=1  lewati Firecrawl (default: ikut, tapi gagal = warning saja)
#   TANPA_EVOLUTION=1  lewati Evolution API
#
# Aman dijalankan berulang (idempoten). Tidak pernah mengubah config profil lain.
# ============================================================================
set -uo pipefail

LOG="$HOME/.hermes/logs/2a-tools.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }
fail() { printf '  ✗ %s\n' "$*"; }
step() { printf '\n── %s\n' "$*"; }

SUDO=""
if [ "$(id -u)" = "0" ]; then SUDO=""
elif command -v sudo >/dev/null 2>&1; then SUDO="sudo"
fi

HERMES_BIN="$(command -v hermes || true)"
if [ -z "$HERMES_BIN" ]; then
  fail "hermes tidak ditemukan di PATH — jalankan setelah Hermes terinstall."
  exit 1
fi

echo "══ 2a: alat dasar + stack + setting ══"
echo "  log: $LOG"

# ---------------------------------------------------------------- 1. base apt
step "1/7 Paket dasar apt"
PKGS="git curl wget ca-certificates jq unzip build-essential python3 python3-venv python3-pip \
ffmpeg xvfb x11vnc novnc websockify rclone iproute2 iw rfkill netplan.io \
postgresql redis-server npm rsync htop"
if command -v apt-get >/dev/null 2>&1; then
  $SUDO apt-get update -qq || warn "apt update gagal (lanjut)"
  # shellcheck disable=SC2086
  if $SUDO DEBIAN_FRONTEND=noninteractive apt-get install -y -qq $PKGS; then
    ok "paket dasar terpasang"
  else
    warn "sebagian paket gagal dipasang — cek nama paket di distro ini"
  fi
else
  warn "bukan apt-based — lewati (script ini untuk Ubuntu/Debian)"
fi

for b in ffmpeg rclone x11vnc websockify; do
  command -v "$b" >/dev/null 2>&1 && ok "$b ada" || warn "$b TIDAK ada"
done

# ---------------------------------------------------------------- 2. docker
step "2/7 Docker"
if [ "${TANPA_DOCKER:-0}" = "1" ]; then
  warn "TANPA_DOCKER=1 — lewati"
elif command -v docker >/dev/null 2>&1; then
  ok "docker sudah ada ($(docker --version 2>/dev/null | cut -d, -f1))"
else
  if command -v apt-get >/dev/null 2>&1 && [ -n "$SUDO" -o "$(id -u)" = "0" ]; then
    curl -fsSL https://get.docker.com | $SUDO sh && ok "docker terpasang" || warn "install docker gagal"
  else
    warn "tanpa sudo — docker tidak bisa dipasang otomatis"
  fi
fi
if command -v docker >/dev/null 2>&1; then
  $SUDO systemctl enable --now docker >/dev/null 2>&1 || true
  $SUDO usermod -aG docker "$USER" >/dev/null 2>&1 || true
fi

# ---------------------------------------------------------------- 3. stack
step "3/7 Stack docker (SearXNG + Evolution API)"
STACK="$HOME/.hermes/stacks"
mkdir -p "$STACK/searxng"

if [ "${TANPA_DOCKER:-0}" != "1" ] && command -v docker >/dev/null 2>&1; then
  # --- SearXNG (JSON API aktif, dipakai Hermes sebagai fallback lokal)
  cat > "$STACK/searxng/settings.yml" <<'YAML'
use_default_settings: true
server:
  secret_key: "wuku-searxng-local-change-me"
  limiter: false
  image_proxy: true
search:
  safe_search: 0
  formats:
    - html
    - json
YAML
  cat > "$STACK/docker-compose.yml" <<'YAML'
services:
  searxng:
    image: searxng/searxng:latest
    container_name: wuku-searxng
    restart: unless-stopped
    ports:
      - "127.0.0.1:8080:8080"
    volumes:
      - ./searxng/settings.yml:/etc/searxng/settings.yml:ro
    environment:
      - SEARXNG_BASE_URL=http://127.0.0.1:8080/
YAML

  if [ "${TANPA_EVOLUTION:-0}" != "1" ]; then
    EVO_KEY="${EVOLUTION_API_KEY:-$(head -c 24 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 32)}"
    cat >> "$STACK/docker-compose.yml" <<YAML
  evolution-postgres:
    image: postgres:16-alpine
    container_name: wuku-evo-pg
    restart: unless-stopped
    environment:
      - POSTGRES_USER=evolution
      - POSTGRES_PASSWORD=evolution
      - POSTGRES_DB=evolution
    volumes:
      - ./evo-pg:/var/lib/postgresql/data
  evolution-redis:
    image: redis:7-alpine
    container_name: wuku-evo-redis
    restart: unless-stopped
    command: redis-server --appendonly yes
  evolution-api:
    image: atendai/evolution-api:v2.2.3
    container_name: wuku-evolution
    restart: unless-stopped
    depends_on:
      - evolution-postgres
      - evolution-redis
    ports:
      - "127.0.0.1:8081:8080"
    environment:
      - AUTHENTICATION_API_KEY=${EVO_KEY}
      - DATABASE_ENABLED=true
      - DATABASE_PROVIDER=postgresql
      - DATABASE_CONNECTION_URI=postgresql://evolution:evolution@evolution-postgres:5432/evolution?schema=public
      - CACHE_REDIS_ENABLED=true
      - CACHE_REDIS_URI=redis://evolution-redis:6379/6
      - CACHE_REDIS_PREFIX_KEY=evolution
      - CACHE_LOCAL_ENABLED=false
      - SERVER_URL=http://127.0.0.1:8081
YAML
    if ! grep -q '^EVOLUTION_API_KEY=' "$HOME/.hermes/.env" 2>/dev/null; then
      printf '\nEVOLUTION_API_KEY=%s\n' "$EVO_KEY" >> "$HOME/.hermes/.env"
      chmod 600 "$HOME/.hermes/.env"
      ok "EVOLUTION_API_KEY dibuat & disimpan di ~/.hermes/.env"
    else
      ok "EVOLUTION_API_KEY sudah ada di .env"
    fi
  else
    warn "TANPA_EVOLUTION=1 — Evolution API dilewati"
  fi

  ( cd "$STACK" && docker compose pull -q && docker compose up -d ) \
    && ok "stack naik (searxng :8080, evolution :8081)" \
    || warn "docker compose gagal — cek 'docker compose logs' di $STACK"

  # --- Firecrawl (opsional, berat: butuh ~2GB RAM)
  if [ "${TANPA_FIRECRAWL:-0}" != "1" ]; then
    if [ ! -d "$STACK/firecrawl" ]; then
      if git clone --depth 1 -q https://github.com/mendableai/firecrawl "$STACK/firecrawl" 2>/dev/null; then
        ok "firecrawl source terunduh"
      else
        warn "firecrawl gagal diunduh (lewati)"
      fi
    fi
    if [ -f "$STACK/firecrawl/docker-compose.yaml" ]; then
      ( cd "$STACK/firecrawl" && docker compose up -d ) >/dev/null 2>&1 \
        && ok "firecrawl naik (:3002)" || warn "firecrawl gagal naik (bukan fatal)"
    fi
  fi
else
  warn "docker tidak tersedia — stack dilewati"
fi

# ---------------------------------------------------------------- 4. env web
step "4/7 Routing web search (keyless free tier + SearXNG lokal)"
ENVF="$HOME/.hermes/.env"
touch "$ENVF"; chmod 600 "$ENVF"
add_env_if_missing() {
  local k="$1" v="$2"
  grep -q "^${k}=" "$ENVF" 2>/dev/null || printf '%s=%s\n' "$k" "$v" >> "$ENVF"
}
add_env_if_missing SEARXNG_URL "http://127.0.0.1:8080"
add_env_if_missing FIRECRAWL_API_URL "http://127.0.0.1:3002"
ok "SEARXNG_URL & FIRECRAWL_API_URL siap"

# Primary = Parallel (punya free keyless), semua vendor keyless dipin "free"
# supaya Hermes memakai jalur keyless, bukan menuntut API key berbayar.
"$HERMES_BIN" config set web.search_backend parallel  >/dev/null 2>&1 && ok "web.search_backend=parallel"
"$HERMES_BIN" config set web.extract_backend firecrawl >/dev/null 2>&1 && ok "web.extract_backend=firecrawl"
for v in parallel exa firecrawl keenable; do
  "$HERMES_BIN" config set "web.provider_tier.$v" free >/dev/null 2>&1 || warn "gagal set tier $v"
done
ok "tier keyless: parallel, exa, firecrawl, keenable = free"
warn "urutan rantai 9-langkah TIDAK bisa dipaksakan lewat config (ring keyless Hermes urutannya tetap: exa→parallel→firecrawl→keenable, lalu SearXNG)"

# ---------------------------------------------------------------- 5. camofox
step "5/7 Camofox (browser automation)"
if "$HERMES_BIN" tools post-setup camofox >/dev/null 2>&1; then
  ok "camofox terpasang"
else
  warn "post-setup camofox gagal — coba manual: hermes tools post-setup camofox"
fi
"$HERMES_BIN" config set browser.cloud_provider camofox >/dev/null 2>&1 && ok "browser.cloud_provider=camofox"

# ---------------------------------------------------------------- 6. STT lokal
step "6/7 STT lokal (faster-whisper medium)"
PY=""
for c in "$HOME/.hermes/venv/bin/python" "$HOME/.hermes"/installs/*/environments/*/venv/bin/python; do
  [ -x "$c" ] && PY="$c" && break
done
if [ -n "$PY" ]; then
  if "$PY" -c "import faster_whisper" 2>/dev/null; then
    ok "faster-whisper sudah ada"
  else
    "$PY" -m pip install -q faster-whisper 2>/dev/null && ok "faster-whisper terpasang" || warn "pip install faster-whisper gagal"
  fi
  "$HERMES_BIN" config set stt.provider local >/dev/null 2>&1 && ok "stt.provider=local"
  "$HERMES_BIN" config set stt.model medium  >/dev/null 2>&1 && ok "stt.model=medium"
  "$HERMES_BIN" config set stt.enabled true  >/dev/null 2>&1 || true
else
  warn "venv Hermes tidak ditemukan — STT lokal dilewati"
fi

# ---------------------------------------------------------------- 7. computer use
step "7/7 Computer use + image analysis"
"$HERMES_BIN" tools enable computer_use >/dev/null 2>&1 && ok "toolset computer_use aktif" || warn "gagal enable computer_use"
"$HERMES_BIN" tools post-setup cua_driver >/dev/null 2>&1 && ok "cua-driver siap" || warn "cua_driver post-setup gagal (bisa manual)"
warn "image analysis: Hermes otomatis memilih model vision — tidak perlu di-set"

echo
echo "══ SELESAI 2a ══"
echo "  Verifikasi cepat:"
echo "    docker ps --format '{{.Names}}\t{{.Status}}' | grep wuku"
echo "    curl -s 'http://127.0.0.1:8080/search?q=test&format=json' | head -c 80"
echo "    hermes config get web.search_backend"
