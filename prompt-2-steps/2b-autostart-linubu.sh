#!/usr/bin/env bash
# ============================================================================
# 2b-autostart-linubu.sh — AUTOSTART SYSTEM-LEVEL + LINGER (tanpa login)
# ============================================================================
# Bagian (B) b.2 dari 2-user-allOS-in-hermeschat.md:
#   gateway start di SYSTEM level, linger aktif, jalan tanpa user login,
#   dan setelah reboot/disconnect tidak minta password lagi.
#
# Jalankan:
#   curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/2b-autostart-linubu.sh -o /tmp/2b.sh && bash /tmp/2b.sh
#
# Idempoten. Kalau system-level gagal → fallback user-level → kalau dua-duanya
# gagal, cetak laporan (bukan exit senyap).
# ============================================================================
set -uo pipefail

LOG="$HOME/.hermes/logs/2b-autostart.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }
fail() { printf '  ✗ %s\n' "$*"; }
step() { printf '\n── %s\n' "$*"; }

SUDO=""
[ "$(id -u)" = "0" ] || SUDO="sudo"

HERMES_BIN="$(command -v hermes || true)"
[ -z "$HERMES_BIN" ] && { fail "hermes tidak ada di PATH"; exit 1; }

SYSTEM_UNIT="/etc/systemd/system/hermes-gateway.service"
STATE="GAGAL"

echo "══ 2b: autostart ══"

step "1/5 Matikan unit USER supaya tidak rebutan token"
systemctl --user disable --now hermes-gateway.service >/dev/null 2>&1 || true
systemctl --user mask hermes-gateway.service >/dev/null 2>&1 || true
ok "unit user di-mask (disengaja — cegah dua gateway jalan bersamaan)"

step "2/5 Pasang unit SYSTEM"
if [ -f "$SYSTEM_UNIT" ] && systemctl is-active --quiet hermes-gateway.service; then
  ok "unit system sudah ada & aktif"
else
  if $SUDO "$HERMES_BIN" gateway install --system --start-now >/dev/null 2>&1; then
    ok "units system dipasang"
  else
    warn "gateway install --system gagal"
  fi
fi

step "3/5 Enable + start"
$SUDO systemctl enable --now hermes-gateway.service >/dev/null 2>&1 || true

step "4/5 Linger"
$SUDO loginctl enable-linger "$USER" >/dev/null 2>&1 || true
LINGER="$(loginctl show-user "$USER" -p Linger --value 2>/dev/null || echo no)"
[ "$LINGER" = "yes" ] && ok "linger=yes (user service tetap hidup tanpa login)" || warn "linger=$LINGER"

step "5/5 Verifikasi"
ACTIVE="$(systemctl is-active hermes-gateway.service 2>/dev/null || echo inactive)"
ENABLED="$(systemctl is-enabled hermes-gateway.service 2>/dev/null || echo disabled)"
CGROUP="$(systemctl show -p ControlGroup --value hermes-gateway.service 2>/dev/null || true)"

echo "  system unit : enabled=$ENABLED active=$ACTIVE"
echo "  cgroup      : ${CGROUP:-?}"
echo "  user unit   : $(systemctl --user is-enabled hermes-gateway.service 2>/dev/null || echo masked)"
echo "  linger      : $LINGER"

if [ "$ACTIVE" = "active" ] && [ "$ENABLED" = "enabled" ] && [ "$LINGER" = "yes" ]; then
  STATE="SYSTEM_OK"
  ok "AUTOSTART SYSTEM-LEVEL BERHASIL"
else
  step "Fallback: user-level"
  systemctl --user unmask hermes-gateway.service >/dev/null 2>&1 || true
  "$HERMES_BIN" gateway install --user >/dev/null 2>&1 || true
  systemctl --user enable --now hermes-gateway.service >/dev/null 2>&1 || true
  U_ACTIVE="$(systemctl --user is-active hermes-gateway.service 2>/dev/null || echo inactive)"
  if [ "$U_ACTIVE" = "active" ] && [ "$LINGER" = "yes" ]; then
    STATE="USER_OK"
    warn "hanya user-level yang berhasil (system butuh sudo)"
  else
    fail "GAGAL dua-duanya — perlu laporan manual"
  fi
fi

echo
echo "══ SELESAI 2b — status: $STATE ══"
[ "$STATE" = "GAGAL" ] && exit 1
exit 0
