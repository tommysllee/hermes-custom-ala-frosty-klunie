#!/usr/bin/env bash
# ============================================================================
# 2d-remote-linubu.sh — TIMEZONE WIB + SSH + VNC(noVNC) + TAILSCALE AUTO
# ============================================================================
# Bagian (B) b.4 + b.5 dari 2-user-allOS-in-hermeschat.md:
#   - server ngomong dalam WIB (sistem di-set Asia/Jakarta)
#   - SSH hidup
#   - VNC/noVNC siap untuk login web manual (Google, marketplace, dsb)
#   - Tailscale nyambung ke network Tommy, tag dipasangintsl, auth key
#     no-expiry, hostname 5 segmen:
#       <panggilan> <nama> <kecamatan/tempat> <OS> server
#     Contoh: panggilan "Kogun", nama "Ayam Goreng", kecamatan "Keputih",
#     OS Ubuntu  ->  kogun-ayam-goreng-keputih-ubuntu-server
#
# Jalankan:
#   curl -fsSL .../2d-remote-linubu.sh -o /tmp/2d.sh
#   NAMA="Ayam Goreng" PANGGILAN=Kogun TEMPAT=Keputih bash /tmp/2d.sh
#
# Opsi:
#   NAMA="Ayam Goreng"  nama orang (boleh multi-kata)
#   PANGGILAN=Kogun     panggilan akrab (default: kata pertama NAMA)
#   TEMPAT=Keputih      kecamatan/kota tempat tinggal (opsional)
#   OS_LABEL=ubuntu     label OS (default: dideteksi otomatis)
#   TS_AUTHKEY=tskey-.. override auth key
#   LEWATI_TAILSCALE=1  hanya SSH+VNC+TZ
# ============================================================================
set -uo pipefail

LOG="$HOME/.hermes/logs/2d-remote.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }
step() { printf '\n── %s\n' "$*"; }

SUDO=""
[ "$(id -u)" = "0" ] || SUDO="sudo"

slugify() { printf '%s' "$1" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-//;s/-*$//'; }

# --- deteksi OS -----------------------------------------------------------
detect_os() {
  if [ -n "${OS_LABEL:-}" ]; then printf '%s' "$OS_LABEL"; return; fi
  local id="" ver=""
  [ -r /etc/os-release ] && . /etc/os-release 2>/dev/null
  id="$(printf '%s' "${ID:-linux}" | tr '[:upper:]' '[:lower:]')"
  ver="${VERSION_ID:-}"
  case "$id" in
    ubuntu)        [ -n "$ver" ] && printf 'ubuntu-%s' "$ver" || printf 'ubuntu' ;;
    debian)        printf 'debian' ;;
    linuxmint)     printf 'mint' ;;
    rhel|centos|rocky|almalinux|fedora) printf '%s' "$id" ;;
    arch)          printf 'arch' ;;
    opensuse*)     printf 'opensuse' ;;
    raspi*|raspbian) printf 'raspbian' ;;
    *)             printf 'linux' ;;
  esac
}

# --- susun hostname 5 segmen ---------------------------------------------
NAMA_RAW="${NAMA:-}"
PANGGILAN_RAW="${PANGGILAN:-}"
TEMPAT_RAW="${TEMPAT:-}"

if [ -z "$NAMA_RAW" ] && [ -z "$PANGGILAN_RAW" ]; then
  NAMA_RAW="$(id -un)"
fi
[ -z "$PANGGILAN_RAW" ] && PANGGILAN_RAW="${NAMA_RAW%% *}"

P_SLUG="$(slugify "$PANGGILAN_RAW")"
N_SLUG="$(slugify "$NAMA_RAW")"
T_SLUG="$(slugify "$TEMPAT_RAW")"
O_SLUG="$(slugify "$(detect_os)")"

PARTS="$P_SLUG"
if [ -n "$N_SLUG" ] && [ "$N_SLUG" != "$P_SLUG" ] && [ "${N_SLUG#"$P_SLUG"-}" = "$N_SLUG" ]; then
  PARTS="$PARTS-$N_SLUG"
fi
[ -n "$T_SLUG" ] && [ "$T_SLUG" != "$P_SLUG" ] && PARTS="$PARTS-$T_SLUG"
PARTS="$PARTS-$O_SLUG"
HOSTNAME_TS="${PANGGILAN_TS:-$PARTS-server}"

TS_KEY="${TS_AUTHKEY:-tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd}"
VNC_PASS_FILE="$HOME/.hermes/remote-view/.vncpass"
RV="$HOME/.hermes/remote-view/remote-view.sh"

echo "══ 2d: timezone + remote access ══"
echo "  hostname tailscale : $HOSTNAME_TS"
echo "  (panggilan=$P_SLUG nama=$N_SLUG tempat=${T_SLUG:-—} os=$O_SLUG)"

step "1/5 Timezone WIB"
$SUDO timedatectl set-timezone Asia/Jakarta >/dev/null 2>&1 || warn "timedatectl gagal"
ok "sistem: $(TZ=Asia/Jakarta date '+%Z %z · %A, %d %b %Y %H:%M')"

step "2/5 SSH"
if ! command -v sshd >/dev/null 2>&1 && ! dpkg -l openssh-server >/dev/null 2>&1; then
  $SUDO apt-get install -y -qq openssh-server >/dev/null 2>&1 || warn "install ssh gagal"
fi
$SUDO systemctl enable --now ssh >/dev/null 2>&1 || $SUDO systemctl enable --now sshd >/dev/null 2>&1 || true
systemctl is-active --quiet ssh 2>/dev/null && ok "SSH aktif" || warn "SSH tidak aktif"
$SUDO ufw allow 22/tcp >/dev/null 2>&1 || true

step "3/5 VNC + noVNC"
PKGS=""
command -v Xvfb >/dev/null 2>&1 || PKGS="$PKGS xvfb"
command -v x11vnc >/dev/null 2>&1 || PKGS="$PKGS x11vnc"
command -v websockify >/dev/null 2>&1 || PKGS="$PKGS websockify"
[ -d /usr/share/novnc ] || PKGS="$PKGS novnc"
if [ -n "$PKGS" ]; then
  # shellcheck disable=SC2086
  $SUDO apt-get install -y -qq $PKGS >/dev/null 2>&1 || warn "sebagian paket VNC gagal"
fi
[ -d /usr/share/novnc ] || warn "/usr/share/novnc tidak ada — noVNC butuh paket 'novnc'"

mkdir -p "$HOME/.hermes/remote-view/log"
if [ ! -f "$VNC_PASS_FILE" ]; then
  head -c 12 /dev/urandom | base64 | tr -dc 'A-Za-z0-9' | head -c 10 > "$VNC_PASS_FILE"
  chmod 600 "$VNC_PASS_FILE"
fi
x11vnc -storepasswd "$(cat "$VNC_PASS_FILE")" "$HOME/.hermes/remote-view/.vncpass.enc" >/dev/null 2>&1 || true

cat > "$RV" <<'EOS'
#!/usr/bin/env bash
# remote-view.sh — nyalakan/matikan layar VNC untuk login web manual.
# start | stop | status | password
set -uo pipefail
DISP=":9"; VNC_PORT=5909; WEB_PORT=6080
DIR="$HOME/.hermes/remote-view"; LOG="$DIR/log"
mkdir -p "$LOG"
PASSF="$DIR/.vncpass"
VPN_IP="$(tailscale ip -4 2>/dev/null | head -1)"

start() {
  pgrep -f "Xvfb $DISP" >/dev/null || { Xvfb "$DISP" -screen 0 1440x900x24 >"$LOG/xvfb.log" 2>&1 & sleep 2; }
  pgrep -f "x11vnc.*$VNC_PORT" >/dev/null || { x11vnc -display "$DISP" -rfbauth "$DIR/.vncpass.enc" -rfbport $VNC_PORT -localhost -forever -shared >"$LOG/x11vnc.log" 2>&1 & sleep 2; }
  if [ -n "$VPN_IP" ]; then
    pgrep -f "websockify.*$WEB_PORT" >/dev/null || { websockify --web /usr/share/novnc "$VPN_IP:$WEB_PORT" "localhost:$VNC_PORT" >"$LOG/websockify.log" 2>&1 & sleep 2; }
    echo "URL      : http://$VPN_IP:$WEB_PORT/vnc.html"
  else
    echo "URL      : tailscale belum aktif — jalankan 'tailscale up' dulu"
  fi
  echo "Password : $(cat "$PASSF" 2>/dev/null)"
  echo "Layar    : DISPLAY=$DISP (jalankan app dengan DISPLAY=$DISP)"
}
stop() {
  pgrep -f "websockify.*$WEB_PORT" >/dev/null && pkill -f "websockify.*$WEB_PORT"
  pgrep -f "x11vnc.*$VNC_PORT"     >/dev/null && pkill -f "x11vnc.*$VNC_PORT"
  pgrep -f "Xvfb $DISP"            >/dev/null && pkill -f "Xvfb $DISP"
  echo "remote-view dimatikan"
}
case "${1:-status}" in
  start) start ;;
  stop) stop ;;
  password) cat "$PASSF" ;;
  status)
    pgrep -f "Xvfb $DISP" >/dev/null && echo "Xvfb: ON" || echo "Xvfb: OFF"
    pgrep -f "x11vnc.*$VNC_PORT" >/dev/null && echo "x11vnc: ON" || echo "x11vnc: OFF"
    pgrep -f "websockify.*$WEB_PORT" >/dev/null && echo "websockify: ON" || echo "websockify: OFF"
    echo "IP tailscale: ${VPN_IP:-none}" ;;
  *) echo "pakai: $0 start|stop|status|password" ;;
esac
EOS
chmod +x "$RV"
ok "helper: $RV (start|stop|status|password)"

step "4/5 Tailscale"
if [ "${LEWATI_TAILSCALE:-0}" = "1" ]; then
  warn "LEWATI_TAILSCALE=1 — dilewati"
else
  if ! command -v tailscale >/dev/null 2>&1; then
    curl -fsSL https://tailscale.com/install.sh | sh >/dev/null 2>&1 || warn "install tailscale gagal"
  fi
  if command -v tailscale >/dev/null 2>&1; then
    # auth key dianggap no-expiry oleh Tailscale; tag wajib kalau key bertag
    $SUDO tailscale up \
      --auth-key="$TS_KEY" \
      --ssh \
      --advertise-tags=tag:dipasangintsl \
      --hostname="$HOSTNAME_TS" \
      --accept-routes=false >/dev/null 2>&1 \
      && ok "tailscale up (hostname=$HOSTNAME_TS, tag=dipasangintsl)" \
      || warn "tailscale up gagal — cek key/tag"
    # pastikan hostname benar walau sudah pernah login
    $SUDO tailscale set --hostname="$HOSTNAME_TS" >/dev/null 2>&1 || true
  else
    warn "tailscale tidak terpasang"
  fi
fi

step "5/5 Verifikasi"
echo "  hostname : $(hostname)"
echo "  tz       : $(timedatectl show -p Timezone --value 2>/dev/null || echo '?')"
echo "  ssh      : $(systemctl is-active ssh 2>/dev/null || echo '?')"
if command -v tailscale >/dev/null 2>&1; then
  echo "  tailscale: $(tailscale status --json 2>/dev/null | grep -o '\"DNSName\":\"[^\"]*\"' | head -1 || echo '?')"
  echo "  ip       : $(tailscale ip -4 2>/dev/null | head -1)"
fi

echo
echo "══ SELESAI 2d ══"
echo "  Login web manual: bash $RV start  → buka URL di atas (lewat Tailscale)"
echo "  Matikan setelah selesai: bash $RV stop"
