#!/usr/bin/env bash
# ============================================================================
# 2z-dokter.sh — CEK STATUS SEMUA SCRIPT (read-only, tidak mengubah apa pun)
# ============================================================================
# Dipakai kalau koneksi terminal putus dan kamu tidak tahu script all-in sudah
# sampai tahap mana. Script ini HANYA MEMERIKSA dan melaporkan.
#
# Jalankan (satu baris):
#   curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/2z-dokter.sh -o /tmp/2z.sh && bash /tmp/2z.sh
#
# Opsi:
#   RINGKAS=1   hanya tampilkan yang BELUM selesai (untuk layar HP)
#   NO_COLOR=1  tanpa warna
# ============================================================================
set -uo pipefail

# ---------- warna ----------
if [ "${NO_COLOR:-0}" = "1" ] || [ ! -t 1 ]; then
  C_OK=""; C_BAD=""; C_WARN=""; C_DIM=""; C_BOLD=""; C_OFF=""
else
  C_OK=$'\033[32m'; C_BAD=$'\033[31m'; C_WARN=$'\033[33m'
  C_DIM=$'\033[2m'; C_BOLD=$'\033[1m'; C_OFF=$'\033[0m'
fi

PASS=0; FAIL=0; WARN=0; SKIP=0
declare -a TODO=()
declare -a TAHAP_OK=()
declare -a TAHAP_BAD=()
tahap_ok()  { TAHAP_OK+=("$1"); }
tahap_bad() { TAHAP_BAD+=("$1"); }

ok()   { PASS=$((PASS+1)); printf '  %s✓%s %s\n' "$C_OK" "$C_OFF" "$*"; }
bad()  { FAIL=$((FAIL+1)); printf '  %s✗%s %s\n' "$C_BAD" "$C_OFF" "$*"; TODO+=("$*"); }
warn() { WARN=$((WARN+1)); printf '  %s!%s %s\n' "$C_WARN" "$C_OFF" "$*"; TODO+=("$*"); }
info() { printf '  %s·%s %s\n' "$C_DIM" "$C_OFF" "$*"; }
head2() { printf '\n%s%s%s\n' "$C_BOLD" "$*" "$C_OFF"; }

cmd_missing() { ! command -v "$1" >/dev/null 2>&1; }

# helper: tampilkan nilai atau "(kosong)"
val() { if [ -n "${1:-}" ]; then printf '%s' "$1"; else printf '(kosong)'; fi; }

echo "${C_BOLD}══════════════════════════════════════════════════════════════${C_OFF}"
echo "${C_BOLD}  DOKTER SCRIPT HERMES — status langkah 1 & 2${C_OFF}"
echo "${C_BOLD}══════════════════════════════════════════════════════════════${C_OFF}"
printf '  %smode: HANYA MEMERIKSA (tidak ada yang diubah)%s\n' "$C_DIM" "$C_OFF"
printf '  waktu: %s\n' "$(TZ=Asia/Jakarta date '+%A, %d %b %Y · %H:%M WIB')"
printf '  host : %s · %s\n' "$(hostname 2>/dev/null || echo '?')" "$(id -un)"
printf '  OS   : %s\n' "$(. /etc/os-release 2>/dev/null && echo "${PRETTY_NAME:-?}" || echo '?')"

# ============================================================ LANGKAH 0
head2 "LANGKAH 0 — Hermes terinstall"
if command -v hermes >/dev/null 2>&1; then
  ok "hermes ada: $(command -v hermes)"
  HB=$(command -v hermes)
  VER=$("$HB" --version 2>/dev/null | head -1 || true)
  info "versi: $(val "${VER:-tidak terbaca}")"
else
  bad "hermes TIDAK ditemukan di PATH — Langkah 2/3 belum bisa jalan"
fi
if [ -d "$HOME/.hermes" ]; then
  ok "~/.hermes ada ($(du -sh "$HOME/.hermes" 2>/dev/null | cut -f1))"
else
  warn "~/.hermes belum ada"
fi

# ============================================================ LANGKAH 1
head2 "LANGKAH 1 — infra (SSH, Tailscale, Docker, autostart dasar)"

# --- SSH
if systemctl is-active --quiet ssh 2>/dev/null || systemctl is-active --quiet sshd 2>/dev/null; then
  SVC=$(systemctl is-active ssh 2>/dev/null || systemctl is-active sshd 2>/dev/null)
  ENA=$(systemctl is-enabled ssh 2>/dev/null || systemctl is-enabled sshd 2>/dev/null)
  ok "SSH aktif ($SVC / enabled=$ENA, port 22)"
else
  if cmd_missing sshd && ! dpkg -l openssh-server >/dev/null 2>&1; then
    bad "SSH belum dipasang"
  else
    bad "SSH terpasang tapi TIDAK aktif"
  fi
fi

# --- user linux
info "user linux sekarang: $(id -un) (uid $(id -u))"
if id tommy >/dev/null 2>&1; then
  ok "user 'tommy' ada (akun default script langkah 1)"
  sudo -n -l -U tommy >/dev/null 2>&1 && ok "user 'tommy' punya sudo" || info "sudo user 'tommy' tidak bisa dicek tanpa password"
else
  info "user 'tommy' tidak ada (normal kalau kamu pakai user sendiri)"
fi

# --- Tailscale
if cmd_missing tailscale; then
  warn "tailscale belum terpasang (tidak wajib kalau kamu pakai SSH biasa)"
else
  TSIP=$(tailscale ip -4 2>/dev/null | head -1 || true)
  TSST=$(tailscale status 2>/dev/null | head -1 || true)
  if [ -n "$TSIP" ]; then
    ok "tailscale login, IP $TSIP"
    TSNAME=$(tailscale status --json 2>/dev/null | python3 -c "import sys,json;d=json.load(sys.stdin);print((d.get('Self') or {}).get('DNSName','').split('.')[0])" 2>/dev/null || true)
    [ -z "$TSNAME" ] && TSNAME=$(tailscale status 2>/dev/null | awk 'NR==1{print $2}' | cut -d. -f1)
    info "hostname tailscale: $(val "${TSNAME:-?}")"
    [ -n "$TSNAME" ] && case "$TSNAME" in *-server) ok "format hostname berakhiran -server" ;; *) warn "hostname tidak berakhiran -server: $TSNAME" ;; esac
    TSTAG=$(tailscale status --json 2>/dev/null | grep -o '"Tags":\[[^]]*\]' | head -1 || true)
    [ -n "$TSTAG" ] && info "tag: $TSTAG" || info "tag: tidak terbaca"
  else
    bad "tailscale terpasang tapi BELUM login/up"
  fi
fi

# --- Docker
if cmd_missing docker; then
  warn "docker belum ada"
else
  DV=$(docker --version 2>/dev/null | cut -d, -f1 || true)
  if docker info >/dev/null 2>&1; then
    ok "docker jalan ($DV)"
  else
    warn "docker ada tapi daemon tidak jalan / butuh sudo"
  fi
fi

# --- autostart dasar (system level)
head2 "LANGKAH 1/2 — autostart gateway"
SYS_UNIT="/etc/systemd/system/hermes-gateway.service"
if [ -f "$SYS_UNIT" ]; then
  A=$(systemctl is-active hermes-gateway 2>/dev/null || echo '?')
  E=$(systemctl is-enabled hermes-gateway 2>/dev/null || echo '?')
  if [ "$A" = "active" ] && [ "$E" = "enabled" ]; then
    ok "gateway SYSTEM: enabled + active"
  else
    bad "gateway SYSTEM ada tapi enabled=$E active=$A"
  fi
else
  bad "unit SYSTEM belum ada ($SYS_UNIT)"
fi
UA=$(systemctl --user is-active hermes-gateway 2>/dev/null | head -1)
UE=$(systemctl --user is-enabled hermes-gateway 2>/dev/null | head -1)
[ -z "$UA" ] && UA="none"
[ -z "$UE" ] && UE="none"
info "unit user: $UE / $UA (masked = normal & disengaja)"
LINGER=$(loginctl show-user "${USER:-$(id -un)}" -p Linger --value 2>/dev/null || echo '?')
[ "$LINGER" = "yes" ] && ok "linger=yes (jalan tanpa login)" || bad "linger=$LINGER (harus yes)"

# ============================================================ LANGKAH 2a
head2 "LANGKAH 2a — alat dasar + stack docker + browser + STT"

# --- paket dasar
MISSING_PKGS=""
for b in git curl jq ffmpeg Xvfb x11vnc websockify rclone psql redis-server npm rsync; do
  cmd_missing "$b" && MISSING_PKGS="$MISSING_PKGS $b"
done
[ -d /usr/share/novnc ] || MISSING_PKGS="$MISSING_PKGS novnc(dir)"
if [ -z "$MISSING_PKGS" ]; then
  ok "semua paket dasar ada (git, ffmpeg, xvfb, novnc, rclone, postgres, redis, npm, rsync)"
  tahap_ok "2a-paket"
else
  warn "paket belum ada:$MISSING_PKGS"
  tahap_bad "2a-paket"
fi

# --- stack docker (nama container dari 2a)
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  for c in wuku-searxng wuku-evolution wuku-evo-pg wuku-evo-redis; do
    ST=$(docker inspect -f '{{.State.Status}}' "$c" 2>/dev/null | head -1)
    [ -z "$ST" ] && ST="absent"
    if [ "$ST" = "running" ]; then ok "container $c: running"
    elif [ "$ST" = "absent" ]; then warn "container $c: belum ada"
    else bad "container $c: $ST"; fi
  done
  # searxng respon JSON?
  if curl -fsS -m 5 'http://127.0.0.1:8080/search?q=test&format=json' >/dev/null 2>&1; then
    ok "SearXNG menjawab di :8080 (JSON aktif)"
  else
    warn "SearXNG tidak menjawab di :8080"
  fi
  docker ps --format '{{.Names}}' 2>/dev/null | grep -qi firecrawl && ok "firecrawl jalan" || warn "firecrawl belum jalan (opsional, berat)"
else
  warn "docker tidak siap — stack tidak bisa dicek"
fi

# --- camofox
CF=""
for p in "$HOME/.cache/camoufox" "$HOME/.hermes/cache/camoufox"; do
  [ -d "$p" ] && CF="$p"
done
[ -n "$CF" ] && ok "camofox terpasang ($CF)" || warn "camofox belum terpasang (~/.cache/camoufox tidak ada)"

# --- STT lokal
PY=""
for c in "$HOME/.hermes/venv/bin/python" "$HOME"/.hermes/installs/*/environments/*/venv/bin/python; do
  [ -x "$c" ] && PY="$c" && break
done
if [ -n "$PY" ]; then
  "$PY" -c "import faster_whisper" 2>/dev/null && ok "faster-whisper (STT lokal) terpasang" || warn "faster-whisper belum terpasang"
else
  warn "venv Hermes tidak ditemukan — STT lokal tidak bisa dicek"
fi
if command -v hermes >/dev/null 2>&1; then
  SP=$(hermes config get stt.provider 2>/dev/null | tail -1 || true)
  SM=$(hermes config get stt.model 2>/dev/null | tail -1 || true)
  [ -z "$SM" ] && SM="(default)"
  info "stt.provider=$(val "${SP:-?}") stt.model=$SM"
  WB=$(hermes config get web.search_backend 2>/dev/null | tail -1 || true)
  info "web.search_backend=$(val "${WB:-?}")"
fi

# ============================================================ LANGKAH 2c
head2 "LANGKAH 2c — autoclean harian + autoupdate"
if crontab -l 2>/dev/null | grep -q 'daily_clean.sh'; then
  ok "crontab harian terpasang: $(crontab -l 2>/dev/null | grep 'daily_clean.sh' | head -1)"
  tahap_ok "2c"
else
  bad "crontab daily_clean.sh BELUM terpasang"
  tahap_bad "2c"
fi
[ -x "$HOME/.hermes/scripts/daily_clean.sh" ] && ok "script daily_clean.sh ada" || warn "script daily_clean.sh belum ada"
if [ -f "$HOME/.hermes/logs/daily_clean.log" ]; then
  LAST=$(TZ=Asia/Jakarta stat -c '%y' "$HOME/.hermes/logs/daily_clean.log" 2>/dev/null | cut -d. -f1 || true)
  info "terakhir jalan (log): $(val "${LAST:-?}")"
else
  info "belum pernah jalan (log belum ada)"
fi

# ============================================================ LANGKAH 2d
head2 "LANGKAH 2d — timezone + VNC"
TZNAME=$(timedatectl show -p Timezone --value 2>/dev/null || echo '?')
if [ "$TZNAME" = "Asia/Jakarta" ]; then ok "timezone sistem: $TZNAME"; tahap_ok "2d-tz"
else warn "timezone sistem: $TZNAME (belum Asia/Jakarta)"; tahap_bad "2d-tz"; fi

RV="$HOME/.hermes/remote-view/remote-view.sh"
if [ -x "$RV" ]; then
  ok "helper remote-view ada ($RV)"
  VPNIP=$(tailscale ip -4 2>/dev/null | head -1 || true)
  [ -n "$VPNIP" ] && info "buat login web nanti: bash $RV start → http://$VPNIP:6080/vnc.html"
else
  warn "helper remote-view belum ada"
fi

# ============================================================ LANGKAH 2e
head2 "LANGKAH 2e — monitor token 6 jam"
if command -v hermes >/dev/null 2>&1; then
  if hermes cron list 2>/dev/null | grep -qi 'token'; then
    ok "cron monitor token terdaftar"
    tahap_ok "2e"
    hermes cron list 2>/dev/null | grep -i 'token' | head -3 | sed 's/^/     /'
  else
    bad "cron monitor token BELUM terdaftar"
  fi
fi
[ -x "$HOME/.hermes/scripts/3-token-monitor.py" ] && ok "script 3-token-monitor.py ada" || warn "script 3-token-monitor.py belum ada"

# ============================================================ LOG TERAKHIR
head2 "LOG — script terakhir yang berjalan"
LOGD="$HOME/.hermes/logs"
if [ -d "$LOGD" ]; then
  FOUND=0
  for f in 2-allin.log 2a-tools.log 2b-autostart.log 2c-maintenance.log 2d-remote.log 2e-token.log; do
    if [ -f "$LOGD/$f" ]; then
      FOUND=1
      MT=$(TZ=Asia/Jakarta stat -c '%y' "$LOGD/$f" 2>/dev/null | cut -d. -f1)
      SZ=$(stat -c '%s' "$LOGD/$f" 2>/dev/null)
      ERRC=$(grep -c '✗' "$LOGD/$f" 2>/dev/null || echo 0)
      printf '  %-22s %s  %sB  error:%s\n' "$f" "$MT" "$SZ" "$ERRC"
    fi
  done
  [ "$FOUND" = "0" ] && info "belum ada log — Langkah 2 mungkin belum pernah jalan"
  # tahap terakhir yang disentuh
  LASTLOG=$(ls -t "$LOGD"/2*.log 2>/dev/null | head -1 || true)
  if [ -n "$LASTLOG" ]; then
    info "paling baru: $(basename "$LASTLOG")"
    echo "  ${C_DIM}--- 12 baris terakhir ---${C_OFF}"
    tail -12 "$LASTLOG" 2>/dev/null | sed 's/^/     /'
  fi
else
  info "folder log belum ada"
fi

# ============================================================ RINGKASAN
echo
echo "${C_BOLD}══════════════════════════════════════════════════════════════${C_OFF}"
printf '  %s✓ %d selesai%s   %s✗ %d belum%s   %s! %d perlu cek%s\n' \
  "$C_OK" "$PASS" "$C_OFF" "$C_BAD" "$FAIL" "$C_OFF" "$C_WARN" "$WARN" "$C_OFF"

echo
echo "  ${C_BOLD}STATUS PER TAHAP:${C_OFF}"
for t in 2a-paket 2c 2d-tz 2e; do
  if printf '%s\n' "${TAHAP_OK[@]:-}" | grep -qx "$t"; then
    printf '   %s[OK]%s  %s\n' "$C_OK" "$C_OFF" "$t"
  else
    printf '   %s[--]%s  %s\n' "$C_BAD" "$C_OFF" "$t"
  fi
done

if [ ${#TODO[@]} -gt 0 ]; then
  echo
  echo "  ${C_BOLD}YANG MASIH PERLU DIKERJAKAN:${C_OFF}"
  printf '   - %s\n' "${TODO[@]}"
  echo
  echo "  ${C_DIM}kalau yang kurang cuma bagian langkah 2, jalankan ulang (aman, idempoten):${C_OFF}"
  echo "  curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/2-allin-linubu.sh -o /tmp/2allin.sh && bash /tmp/2allin.sh"
else
  echo
  echo "  ${C_OK}${C_BOLD}SEMUA BERES — tidak ada yang perlu dijalankan ulang.${C_OFF}"
fi
echo "${C_BOLD}══════════════════════════════════════════════════════════════${C_OFF}"

[ "$FAIL" -gt 0 ] && exit 1
exit 0
