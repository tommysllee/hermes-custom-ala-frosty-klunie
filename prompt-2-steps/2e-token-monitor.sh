#!/usr/bin/env bash
# ============================================================================
# 2e-token-monitor.sh — PASANG MONITOR TOKEN TIAP 6 JAM (mode no_agent)
# ============================================================================
# Bagian (B) b.6 [PER] dari 2-user-allOS-in-hermeschat.md.
# Aturan output (TIDAK BOLEH DIUBAH): satu baris, hanya tanggal + jam + angka
# token, tanpa label/merek/mata uang.
#
# Jalankan:
#   curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/2e-token-monitor.sh -o /tmp/2e.sh && bash /tmp/2e.sh
#
# Opsi:
#   TEST=1   jalankan script sekali untuk lihat format keluarannya
# ============================================================================
set -uo pipefail

LOG="$HOME/.hermes/logs/2e-token.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

ok()   { printf '  ✓ %s\n' "$*"; }
warn() { printf '  ! %s\n' "$*"; }
step() { printf '\n── %s\n' "$*"; }

HERMES_BIN="$(command -v hermes || true)"
[ -z "$HERMES_BIN" ] && { warn "hermes tidak ada di PATH"; exit 1; }

SRC="https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/3-token-monitor.py"
DST="$HOME/.hermes/scripts/3-token-monitor.py"

echo "══ 2e: monitor token 6 jam ══"

step "1/3 Unduh script"
mkdir -p "$HOME/.hermes/scripts"
if curl -fsSL "$SRC" -o "$DST"; then
  chmod +x "$DST"
  ok "$DST ($(wc -c < "$DST") byte)"
else
  warn "gagal unduh $SRC"
  exit 1
fi

step "2/3 Pasang cron (0 */6 * * * = tiap 6 jam, mode no_agent)"
if "$HERMES_BIN" cron list 2>/dev/null | grep -qi 'token'; then
  ok "job monitor token sudah ada (tidak diduplikasi)"
else
  "$HERMES_BIN" cron create "0 */6 * * *" \
    --name "Estimasi sisa token tiap 6 jam" \
    --script 3-token-monitor.py --no-agent --deliver origin \
    >/dev/null 2>&1 && ok "cron terpasang" || warn "cron create gagal"
fi

step "3/3 Verifikasi"
"$HERMES_BIN" cron list 2>/dev/null | grep -i -A2 token || warn "job tidak terlihat di daftar"
if [ "${TEST:-0}" = "1" ]; then
  echo "  --- keluaran uji ---"
  python3 "$DST" || warn "script gagal dijalankan"
  echo "  --------------------"
fi

echo
echo "══ SELESAI 2e ══"
echo "  Format yang benar: 'Tanggal 9 Okt 2026, jam 18.00, Estimasi Sisa Token 14.236.836'"
