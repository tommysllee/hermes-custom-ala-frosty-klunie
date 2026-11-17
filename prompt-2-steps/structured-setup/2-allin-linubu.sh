#!/usr/bin/env bash
# ============================================================================
# 2-allin-linubu.sh — SATU BARIS: jalankan 2a + 2b + 2c + 2e
# ============================================================================
# Untuk mesin Ubuntu/Debian yang SUDAH terinstall Hermes (tahap 2).
#
# MODE DEFAULT — SSH & Tailscale TIDAK disentuh, hostname TIDAK diubah:
#   curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/2-allin-linubu.sh -o /tmp/2allin.sh && bash /tmp/2allin.sh
#
# MODE LENGKAP — ikut set SSH + VNC + Tailscale (hostname 5 segmen):
#   curl -fsSL .../2-allin-linubu.sh -o /tmp/2allin.sh && SETEL_SSH_TAILSCALE=1 NAMA="Ayam Goreng" PANGGILAN=Kogun TEMPAT=Keputih bash /tmp/2allin.sh
#
# Interaksi: hanya password sudo (sekali, di awal).
#
# Opsi:
#   LEWATI=2a,2c              lewati tahap tertentu
#   SETEL_SSH_TAILSCALE=1     paksa ikut setel SSH + Tailscale (2d)
#   TANPA_DOCKER=1            lewati stack docker (dioper ke 2a)
# ============================================================================
set -uo pipefail

PUB_RAW="https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps"

# DEFAULT: SSH & Tailscale dilewati (dianggap sudah beres).
# Mode default hanya menyisakan timezone WIB + VNC dari tahap 2d.
if [ -z "${LEWATI+x}" ]; then LEWATI=""; fi
SETEL_SSH_TAILSCALE="${SETEL_SSH_TAILSCALE:-0}"
if [ "$SETEL_SSH_TAILSCALE" = "1" ]; then
  unset LEWATI_SSH LEWATI_TAILSCALE
else
  export LEWATI_SSH=1 LEWATI_TAILSCALE=1
fi

LOG="$HOME/.hermes/logs/2-allin.log"
mkdir -p "$(dirname "$LOG")" 2>/dev/null

ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }
fail() { printf '  ✗ %s\n' "$*"; }
banner() { printf '\n══════ %s ══════\n' "$*"; }

# ---- pra-syarat -----------------------------------------------------------
if ! command -v hermes >/dev/null 2>&1; then
  fail "hermes tidak ditemukan di PATH. Jalankan script ini SETELAH Hermes terinstall."
  exit 1
fi
if ! command -v curl >/dev/null 2>&1; then
  fail "curl tidak ada. Pasang dulu: sudo apt-get install -y curl"
  exit 1
fi

# ---- sudo di awal (sekali) supaya tidak diminta berulang ------------------
if [ "$(id -u)" != "0" ]; then
  if command -v sudo >/dev/null 2>&1; then
    echo "Script ini butuh sudo — masukkan password SEKALI di awal."
    sudo -v || { fail "sudo gagal"; exit 1; }
    ( while true; do sudo -n true 2>/dev/null || exit; sleep 50; done ) &
    SUDO_KEEPALIVE=$!
    trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null || true' EXIT
  fi
fi

skipped() {
  case ",${LEWATI:-}," in *",$1,"*) return 0 ;; *) return 1 ;; esac
}

FAILED=""
run_stage() {
  local id="$1" file="$2" label="$3"
  shift 3
  if skipped "$id"; then
    warn "$label — dilewati"
    return 0
  fi
  banner "$label"
  local tmp="/tmp/_2stage_$id.sh"
  if ! curl -fsSL "$PUB_RAW/$file" -o "$tmp"; then
    fail "gagal unduh $file"
    FAILED="$FAILED $label"
    return 0
  fi
  if bash "$tmp" "$@"; then
    ok "$label selesai"
  else
    warn "$label selesai dengan error (lihat log di ~/.hermes/logs/)"
    FAILED="$FAILED $label"
  fi
}

echo "══ TAHAP 2 — ALAT + AUTOSTART + MAINTENANCE + VNC + TOKEN ══"
echo "  log: $LOG"
if [ "$SETEL_SSH_TAILSCALE" = "1" ]; then
  echo "  SSH & Tailscale : IKUT disetel (mode lengkap)"
else
  echo "  SSH & Tailscale : tidak disentuh (sudah dipasang di langkah 1)"
  echo "  hostname server : tidak disentuh (sudah diset saat instalasi Ubuntu)"
fi

run_stage 2a 2a-tools-linubu.sh        "2a — alat dasar + stack docker + camofox + STT + routing web"
run_stage 2b 2b-autostart-linubu.sh    "2b — autostart system-level + linger"
run_stage 2c 2c-maintenance-linubu.sh  "2c — autoclean harian + autoupdate apt + restart gateway"
run_stage 2d 2d-remote-linubu.sh       "2d — timezone WIB + VNC (SSH/Tailscale dilewati)"
run_stage 2e 2e-token-monitor.sh       "2e — monitor token tiap 6 jam"

# ---- ringkasan ------------------------------------------------------------
banner "RINGKASAN AKHIR"
printf '  timezone    : %s\n' "$(timedatectl show -p Timezone --value 2>/dev/null || echo '?')"
printf '  gateway     : %s / %s\n' \
  "$(systemctl is-enabled hermes-gateway.service 2>/dev/null || echo '?')" \
  "$(systemctl is-active hermes-gateway.service 2>/dev/null || echo '?')"
printf '  linger      : %s\n' "$(loginctl show-user "${USER:-$(id -un)}" -p Linger --value 2>/dev/null || echo '?')"
printf '  ssh         : %s (tidak diubah script ini)\n' "$(systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null || echo '?')"
if command -v tailscale >/dev/null 2>&1; then
  printf '  tailscale   : %s\n' "$(tailscale ip -4 2>/dev/null | head -1 || echo 'no-ip')"
fi
printf '  docker      : %s\n' "$(command -v docker >/dev/null 2>&1 && docker ps --format '{{.Names}}' 2>/dev/null | tr '\n' ' ' || echo 'tidak ada')"
printf '  cron        : %s entri maintenance\n' "$(crontab -l 2>/dev/null | grep -c daily_clean || echo 0)"
printf '  token cron  : %s job\n' "$(hermes cron list 2>/dev/null | grep -ci 'token')"
printf '  remote view : bash ~/.hermes/remote-view/remote-view.sh start\n'

if [ -n "$FAILED" ]; then
  echo
  warn "TAHAP DENGAN ERROR:$FAILED"
  echo "  Cek log: ls -t ~/.hermes/logs/*.log | head"
  exit 1
fi

echo
ok "SEMUA TAHAP YANG DIPILIH SELESAI TANPA ERROR"
exit 0
