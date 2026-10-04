#!/usr/bin/env bash
# ===========================================================================
#  PEMASANG SATU PERINTAH — AI Agent Bisnis
#
#  Cara pakai (satu baris, tinggal tempel di terminal):
#
#    curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/pasang.sh | bash
#
#  Skrip ini mengunduh pemasang lengkap lalu menjalankannya.
#  Tidak perlu tahu git, tidak perlu clone, tidak perlu apa pun.
# ===========================================================================

set -uo pipefail

REPO="https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main"
KERJA="$(mktemp -d /tmp/pasang-hermes-XXXXXX)"

bersih() { rm -rf "$KERJA" 2>/dev/null || true; }
trap bersih EXIT

echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │   PEMASANG AI AGENT — SATU PERINTAH                     │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""
echo "  Menyiapkan... (butuh 15–30 menit, bisa ditinggal)"
echo ""

# --- 1. Pastikan alat pengunduh ada -------------------------------------
if command -v curl >/dev/null 2>&1; then UNDUH="curl -fsSL"
elif command -v wget >/dev/null 2>&1; then UNDUH="wget -qO-"
else
  echo "  Perlu 'curl' atau 'wget' dulu."
  echo "  Jalankan:  sudo apt-get update && sudo apt-get install -y curl"
  exit 1
fi

# --- 2. Unduh seluruh berkas yang diperlukan ----------------------------
BERKAS="install.sh installer.env pasang.sh"
BERKAS="$BERKAS scripts/fitur-tambahan.sh"
BERKAS="$BERKAS docs/BACKUP.md docs/LINUX.md docs/TAILSCALE.md"
BERKAS="$BERKAS docs/GITHUB.md docs/PEMECAHAN.md docs/PROMPT_UNTUK_AI_AGENT.md"

mkdir -p "$KERJA/scripts" "$KERJA/docs"

GAGAL=0
for f in $BERKAS; do
  printf "  mengunduh %-38s" "$f"
  if $UNDUH "$REPO/$f" > "$KERJA/$f" 2>/dev/null && [ -s "$KERJA/$f" ]; then
    echo "✓"
  else
    echo "✗"
    GAGAL=$((GAGAL+1))
  fi
done

if [ "$GAGAL" -gt 2 ]; then
  echo ""
  echo "  Terlalu banyak berkas gagal diunduh."
  echo "  Periksa sambungan internet Anda, lalu coba lagi."
  exit 1
fi

# --- 3. Pastikan bisa dijalankan ----------------------------------------
chmod +x "$KERJA/install.sh" "$KERJA/scripts/fitur-tambahan.sh" 2>/dev/null || true

# --- 4. Jalankan --------------------------------------------------------
echo ""
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │   MEMULAI PEMASANGAN                                    │"
echo "  └─────────────────────────────────────────────────────────┘"
echo ""

cd "$KERJA" || exit 1

# Teruskan pilihan yang diberikan pengguna (mis. --tes, --tanpa-docker)
if [ $# -gt 0 ]; then
  bash "$KERJA/install.sh" "$@"
else
  bash "$KERJA/install.sh"
fi

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
  echo "  Pemasangan berhenti dengan kode $HASIL."
  echo "  Kirim tangkapan layar ini ke teknisi Anda."
fi
echo ""
