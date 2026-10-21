#!/usr/bin/env bash
# ============================================================================
# 2c-maintenance-linubu.sh — AUTOCLEAN HARIAN + AUTOUPDATE APT + RESTART GATEWAY
# ============================================================================
# Bagian (B) b.3 dari 2-user-allOS-in-hermeschat.md:
#   - tiap akhir hari WIB: buang file sampah, lalu restart gateway
#   - tiap ada update sistem/hermes: apt update + restart gateway
#
# Script ini memasang:
#   ~/.hermes/scripts/daily_clean.sh   (isi pekerjaan)
#   crontab 16:45 UTC = 23:45 WIB      (akhir hari WIB)
#
# Jalankan:
#   curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/2c-maintenance-linubu.sh -o /tmp/2c.sh && bash /tmp/2c.sh
#
# Opsi: RUN_NOW=1  → langsung jalankan sekali setelah dipasang
# ============================================================================
set -uo pipefail

LOG="$HOME/.hermes/logs/2c-maintenance.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }
step() { printf '\n── %s\n' "$*"; }

SUDO=""
[ "$(id -u)" = "0" ] || SUDO="sudo"
HERMES_BIN="$(command -v hermes || true)"

echo "══ 2c: maintenance harian ══"

step "1/3 Tulis pekerja harian"
cat > "$HOME/.hermes/scripts/daily_clean.sh" <<'EOS'
#!/usr/bin/env bash
# Pekerja harian Hermes — dipanggil cron 23:45 WIB.
set -uo pipefail
LOG="$HOME/.hermes/logs/daily_clean.log"
mkdir -p "$(dirname "$LOG")"
{
  echo "=== $(TZ=Asia/Jakarta date '+%Y-%m-%d %H:%M WIB') ==="

  # 1. cache & scratch > 7 hari
  find "$HOME/.hermes/cache" -mindepth 1 -mtime +7 -maxdepth 2 -exec rm -rf {} + 2>/dev/null || true

  # 2. log > 14 hari
  find "$HOME/.hermes/logs" -type f -name '*.log' -mtime +14 -exec truncate -s 0 {} \; 2>/dev/null || true

  # 3. docker sampah (volume TIDAK disentuh)
  if command -v docker >/dev/null 2>&1; then
    docker system prune -af --filter 'until=168h' >/dev/null 2>&1 || true
    docker builder prune -af --filter 'until=168h' >/dev/null 2>&1 || true
  fi

  # 4. apt
  if command -v apt-get >/dev/null 2>&1; then
    SUDO=""; [ "$(id -u)" = "0" ] || SUDO="sudo"
    $SUDO apt-get -qq clean >/dev/null 2>&1 || true
    $SUDO apt-get -qq autoremove -y >/dev/null 2>&1 || true
    # auto-update paket keamanan (tidak interaktif)
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get -qq update >/dev/null 2>&1 || true
    $SUDO DEBIAN_FRONTEND=noninteractive apt-get -qq -y -o Dpkg::Options::=--force-confdef \
      -o Dpkg::Options::=--force-confold upgrade >/dev/null 2>&1 || true
  fi

  # 5. sqlite checkpoint (bukan VACUUM — mahal)
  DB="$HOME/.hermes/state.db"
  if [ -f "$DB" ] && command -v sqlite3 >/dev/null 2>&1; then
    sqlite3 "$DB" 'PRAGMA wal_checkpoint(TRUNCATE);' >/dev/null 2>&1 || true
  fi

  # 6. restart gateway (system dulu, fallback user)
  if systemctl is-active --quiet hermes-gateway.service 2>/dev/null; then
    SUDO2=""; [ "$(id -u)" = "0" ] || SUDO2="sudo"
    $SUDO2 systemctl restart hermes-gateway.service >/dev/null 2>&1 || true
    echo "gateway: system restart"
  elif systemctl --user is-active --quiet hermes-gateway.service 2>/dev/null; then
    systemctl --user restart hermes-gateway.service >/dev/null 2>&1 || true
    echo "gateway: user restart"
  else
    echo "gateway: tidak aktif — dilewati"
  fi

  echo "selesai"
} >> "$LOG" 2>&1
EOS
chmod +x "$HOME/.hermes/scripts/daily_clean.sh"
ok "~/.hermes/scripts/daily_clean.sh ditulis"

step "2/3 Pasang crontab (23:45 WIB)"
LINE='45 16 * * * /bin/bash $HOME/.hermes/scripts/daily_clean.sh >/dev/null 2>&1'
CUR="$(crontab -l 2>/dev/null || true)"
if echo "$CUR" | grep -qF 'daily_clean.sh'; then
  ok "crontab sudah ada (tidak diduplikasi)"
else
  { echo "$CUR"; echo "$LINE"; } | grep -v '^$' | crontab - \
    && ok "crontab dipasang: 45 16 * * * (=23:45 WIB)" \
    || warn "gagal menulis crontab"
fi

step "3/3 Verifikasi"
crontab -l 2>/dev/null | grep daily_clean || warn "entri cron tidak terlihat"
if [ "${RUN_NOW:-0}" = "1" ]; then
  bash "$HOME/.hermes/scripts/daily_clean.sh" && ok "uji jalan selesai (lihat ~/.hermes/logs/daily_clean.log)"
fi

echo
echo "══ SELESAI 2c ══"
echo "  Catatan: auto-update apt ikut di pekerjaan harian ini (bukan event-driven)."
echo "  Log: ~/.hermes/logs/daily_clean.log"
