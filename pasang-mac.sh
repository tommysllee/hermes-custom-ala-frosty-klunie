#!/usr/bin/env bash
# ===========================================================================
#  PEMASANG SATU PERINTAH — Mac
#
#  Cara pakai (tempel SATU baris di Terminal):
#
#    curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/pasang-mac.sh | bash
# ===========================================================================

set -uo pipefail

REPO="https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main"
KERJA="$(mktemp -d /tmp/pasang-hermes-XXXXXX)"

bersih() { rm -rf "$KERJA" 2>/dev/null || true; }
trap bersih EXIT

echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │   PEMASANG AI AGENT — MAC                               │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""
echo "  Butuh 20–40 menit. Bisa ditinggal."
echo ""

# --- 1. Pastikan macOS ---------------------------------------------------
if [ "$(uname -s)" != "Darwin" ]; then
  echo "  ✗ Skrip ini untuk Mac. Untuk Linux pakai pasang.sh"
  exit 1
fi
echo "  ✓ macOS $(sw_vers -productVersion) terdeteksi"

# --- 2. Cegah Mac tidur selama pemasangan ---------------------------------
if command -v caffeinate >/dev/null 2>&1; then
  caffeinate -i -w $$ &
  echo "  ✓ Mac dicegah tidur selama pemasangan"
fi

# --- 3. Unduh berkas -----------------------------------------------------
BERKAS="install-mac.sh installer.env pasang-mac.sh"
BERKAS="$BERKAS scripts/fitur-tambahan.sh"
BERKAS="$BERKAS docs/BACKUP.md docs/MAC.md docs/TAILSCALE.md docs/GITHUB.md"

mkdir -p "$KERJA/scripts" "$KERJA/docs"
GAGAL=0
for f in $BERKAS; do
  printf "  mengunduh %-38s" "$f"
  if curl -fsSL "$REPO/$f" > "$KERJA/$f" 2>/dev/null && [ -s "$KERJA/$f" ]; then
    echo "✓"
  else
    echo "✗"; GAGAL=$((GAGAL+1))
  fi
done

if [ "$GAGAL" -gt 2 ]; then
  echo ""
  echo "  Terlalu banyak berkas gagal diunduh. Periksa internet."
  exit 1
fi

chmod +x "$KERJA/install-mac.sh" "$KERJA/scripts/fitur-tambahan.sh" 2>/dev/null || true

# --- 4. Jalankan ---------------------------------------------------------
echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │   MEMULAI PEMASANGAN                                    │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""

cd "$KERJA" || exit 1
if [ $# -gt 0 ]; then bash "$KERJA/install-mac.sh" "$@"; else bash "$KERJA/install-mac.sh"; fi
HASIL=$?

echo ""
if [ "$HASIL" -eq 0 ]; then
  echo "  ┌─────────────────────────────────────────────────────────┐"
  echo "  │   SELESAI                                               │"
  echo "  └─────────────────────────────────────────────────────────┘"
  echo ""
  echo "  Ikuti langkah terakhir yang muncul di atas."
  echo "  Kalau bingung, hubungi teknisi Anda."
else
  echo "  Pemasangan berhenti dengan kode $HASIL. Kirim tangkapan layar ke teknisi."
fi
echo ""
