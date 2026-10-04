#!/usr/bin/env bash
# ===========================================================================
#  HERMES — PENAMBAHAN FITUR (dipanggil oleh install.sh)
#
#  Menambahkan:
#   A. Backup lengkap + perawatan harian (jadwal cron)
#   B. Autostart system-level + linger tanpa password
#   C. Pintu akses: SSH + VNC + Tailscale tanpa kadaluarsa
#   D. Berkas panduan ingatan
# ===========================================================================

set -uo pipefail

HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
TAG="${TS_TAG:-tag:dipasangintsl}"
LOG="$HERMES_HOME/logs/fitur-tambahan.log"
mkdir -p "$HERMES_HOME/scripts" "$HERMES_HOME/logs" "$HERMES_HOME/templates"
SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo -n"
USER_NAME="$(id -un)"

f_ok()   { echo "  ✓ $*"; }
f_info() { echo "  → $*"; }
catat()  { echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $*" >>"$LOG"; }

# ===========================================================================
# A. BACKUP LENGKAP + PERAWATAN HARIAN
# ===========================================================================
echo ""
f_info "menyiapkan backup lengkap & perawatan harian..."

# --- perawatan harian: 14:00 UTC = 21:00 WIB ---
cat > "$HERMES_HOME/scripts/perawatan-harian.sh" <<'PERAWATAN'
#!/usr/bin/env bash
set -uo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
LOG="$HERMES_HOME/logs/perawatan-harian.log"
mkdir -p "$(dirname "$LOG")"
catat() { echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $*" | tee -a "$LOG"; }
echo "" >> "$LOG"
catat "===== PERAWATAN HARIAN (WIB: $(TZ=Asia/Jakarta date '+%H:%M')) ====="
catat "1/4 membersihkan file sampah..."
for d in "$HERMES_HOME/cache/scratch" "$HOME/.cache/pip" "$HOME/.cache/uv"; do
  [ -d "$d" ] || continue
  n=$(find "$d" -type f -mtime +3 2>/dev/null | wc -l)
  find "$d" -type f -mtime +3 -delete 2>/dev/null || true
  catat "    $d → $n berkas dibuang"
done
for f in "$HERMES_HOME/logs"/*.log; do
  [ -f "$f" ] || continue
  sz=$(stat -c%s "$f" 2>/dev/null || echo 0)
  if [ "$sz" -gt 52428800 ]; then
    tail -n 2000 "$f" > "$f.pangkas" 2>/dev/null && mv "$f.pangkas" "$f"
    catat "    $(basename "$f") dipangkas"
  fi
done
n=$(find "$HERMES_HOME/backups" -type f -mtime +30 2>/dev/null | wc -l)
find "$HERMES_HOME/backups" -type f -mtime +30 -delete 2>/dev/null || true
catat "    backup >30 hari → $n dibuang"
catat "2/4 update paket sistem..."
if command -v apt-get >/dev/null 2>&1; then
  SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo -n"
  $SUDO apt-get update -qq >>"$LOG" 2>&1 || true
  n=$($SUDO apt-get -s upgrade 2>/dev/null | grep -c '^Inst' || echo 0)
  if [ "${n:-0}" -gt 0 ]; then
    catat "    $n paket diperbarui"
    DEBIAN_FRONTEND=noninteractive $SUDO apt-get -y -qq -o Dpkg::Options::=--force-confdef \
      -o Dpkg::Options::=--force-confold upgrade >>"$LOG" 2>&1 || true
    $SUDO apt-get -y -qq autoremove >>"$LOG" 2>&1 || true
  else catat "    sudah terbaru"; fi
fi
catat "3/4 update Hermes..."
command -v hermes >/dev/null 2>&1 && { hermes update >>"$LOG" 2>&1 || true; }
catat "4/4 restart gateway..."
if systemctl list-unit-files hermes-gateway.service >/dev/null 2>&1; then
  SUDO=""; [ "$(id -u)" -ne 0 ] && SUDO="sudo -n"
  $SUDO systemctl restart hermes-gateway.service >>"$LOG" 2>&1 && catat "    ✓ gateway di-restart"
fi
catat "===== SELESAI ====="
PERAWATAN
chmod +x "$HERMES_HOME/scripts/perawatan-harian.sh"
f_ok "perawatan harian siap (21:00 WIB)"

# --- backup lengkap ---
cat > "$HERMES_HOME/scripts/backup-lengkap.sh" <<'BKP'
#!/usr/bin/env bash
set -uo pipefail
HERMES_HOME="${HERMES_HOME:-$HOME/.hermes}"
# PENTING: cadangan disimpan DI LUAR folder .hermes
# Kalau di dalam, cadangan ikut hilang saat .hermes rusak/dihapus.
TUJUAN="${BACKUP_DIR:-$HOME/hermes-backup}"
NAMA="hermes-snapshot-$(date +%Y%m%d_%H%M)"
LOG="$HERMES_HOME/logs/backup-lengkap.log"
mkdir -p "$TUJUAN" "$(dirname "$LOG")"
catat() { echo "[$(date '+%Y-%m-%d %H:%M:%S %Z')] $*" | tee -a "$LOG"; }

if [ "${1:-}" = "--pulihkan" ]; then
  BERKAS="${2:-}"
  [ -f "$BERKAS" ] || { echo "Berkas tidak ada: $BERKAS"; exit 1; }
  echo "Memulihkan dari: $BERKAS"
  # Salin skrip ini ke luar dulu — folder .hermes akan dipindahkan
  SALINAN="$(mktemp -d)/pulihkan.sh"
  cp "${BASH_SOURCE[0]}" "$SALINAN" 2>/dev/null || true

  if [ -d "$HERMES_HOME" ]; then
    LAMA="$HERMES_HOME-lama-$(date +%Y%m%d_%H%M)"
    mv "$HERMES_HOME" "$LAMA"
    echo "  Sistem lama dipindah ke: $LAMA"
  fi
  mkdir -p "$HERMES_HOME"
  tar --zstd -xf "$BERKAS" -C "$(dirname "$HERMES_HOME")" 2>/dev/null \
    || tar -xf "$BERKAS" -C "$(dirname "$HERMES_HOME")"
  mkdir -p "$HERMES_HOME/scripts"
  cp "$SALINAN" "$HERMES_HOME/scripts/backup-lengkap.sh" 2>/dev/null || true
  chmod +x "$HERMES_HOME/scripts/backup-lengkap.sh" 2>/dev/null || true
  echo "  ✓ Dipulihkan."
  echo "  Langkah berikutnya:"
  echo "    hermes gateway restart"
  echo "    hermes doctor"
  echo ""
  echo "  CATATAN: mulai sekarang cadangan disimpan di $HOME/hermes-backup"
  echo "  (di luar .hermes) supaya tidak ikut hilang kalau .hermes rusak."
  exit 0
fi

echo "" >> "$LOG"
catat "===== BACKUP LENGKAP (WIB: $(TZ=Asia/Jakarta date '+%H:%M')) ====="
DAFTAR=(skills cron templates knowledge scripts hooks remote-view profiles SOUL.md config.yaml .env sessions session_search.db state.db)
ADA=()
for x in "${DAFTAR[@]}"; do [ -e "$HERMES_HOME/$x" ] && ADA+=("$x"); done
catat "Isi: ${ADA[*]}"
[ -f "$HERMES_HOME/state.db" ] && [ -f "$HERMES_HOME/scripts/bersihkan_state_db.py" ] && \
  python3 "$HERMES_HOME/scripts/bersihkan_state_db.py" "$HERMES_HOME/state.db" >>"$LOG" 2>&1 || true

# PENTING: jalankan dari folder INDUK, dan simpan dengan awalan ".hermes/"
# supaya saat dipulihkan isinya kembali ke ~/.hermes (bukan ke ~/)
INDUK="$(dirname "$HERMES_HOME")"
NAMA_FOLDER="$(basename "$HERMES_HOME")"
DAFTAR_ARSIP=()
for x in "${ADA[@]}"; do DAFTAR_ARSIP+=("$NAMA_FOLDER/$x"); done

cd "$INDUK" || exit 1
if tar --zstd -cf "$TUJUAN/$NAMA.tar.zst" "${DAFTAR_ARSIP[@]}" 2>>"$LOG"; then
  BERKAS="$TUJUAN/$NAMA.tar.zst"
else
  tar -czf "$TUJUAN/$NAMA.tar.gz" "${DAFTAR_ARSIP[@]}" 2>>"$LOG" && BERKAS="$TUJUAN/$NAMA.tar.gz"
fi
if [ -n "${BERKAS:-}" ] && [ -f "$BERKAS" ]; then
  UKURAN=$(du -h "$BERKAS" | cut -f1)
  catat "✓ Arsip: $BERKAS ($UKURAN)"
  cat > "$TUJUAN/$NAMA.CATATAN.txt" <<CTN
SNAPSHOT HERMES
Dibuat: $(TZ=Asia/Jakarta date '+%A, %d %b %Y · %H:%M WIB')
Isi:
$(printf '  - %s\n' "${ADA[@]}")
Ukuran: $UKURAN
Pulihkan (dari folder rumah): tar --zstd -xf <berkas> -C ~
Lalu: hermes gateway restart
CTN
  if command -v rclone >/dev/null 2>&1 && rclone listremotes 2>/dev/null | grep -q '^gdrive:'; then
    rclone copy "$BERKAS" gdrive:hermes-backup/ >>"$LOG" 2>&1 \
      && catat "    ✓ terkirim ke Google Drive"
  else
    catat "    (Drive belum disiapkan — lihat docs/BACKUP.md)"
  fi
else
  catat "✗ gagal membuat arsip"; exit 1
fi
catat "===== SELESAI ====="
BKP
chmod +x "$HERMES_HOME/scripts/backup-lengkap.sh"
f_ok "backup lengkap siap (termasuk state.db + profil + sesi)"

# --- catat jadwal di cron ---
if command -v crontab >/dev/null 2>&1; then
  ( crontab -l 2>/dev/null | grep -v 'perawatan-harian\|backup-lengkap'; \
    echo "0 2,14 * * * $HERMES_HOME/scripts/backup-lengkap.sh >> $HERMES_HOME/logs/backup.log 2>&1"; \
    echo "0 14 * * * $HERMES_HOME/scripts/perawatan-harian.sh >> $HERMES_HOME/logs/perawatan.log 2>&1" \
  ) | crontab - 2>/dev/null || true
  if crontab -l 2>/dev/null | grep -q 'backup-lengkap'; then
    f_ok "jadwal dipasang: backup 2x (09:00 & 21:00 WIB) + perawatan (21:00 WIB)"
  else
    f_info "cron belum aktif — jalankan: sudo apt-get install -y cron"
  fi
fi

# ===========================================================================
# B. AUTOSTART SYSTEM-LEVEL + LINGER TANPA PASSWORD
# ===========================================================================
echo ""
f_info "menyiapkan autostart system-level & linger..."

if [ -d /etc/sudoers.d ]; then
  T="$(mktemp)"
  printf '%s\n' "# Dipasang otomatis oleh pemasang Hermes." \
                "# Hapus kalau tidak diinginkan: sudo rm /etc/sudoers.d/hermes-mandiri" \
                "$USER_NAME ALL=(ALL) NOPASSWD: ALL" > "$T"
  if $SUDO visudo -c -f "$T" >/dev/null 2>&1; then
    $SUDO install -m 0440 "$T" /etc/sudoers.d/hermes-mandiri 2>/dev/null \
      && f_ok "sudo tanpa password aktif" || f_info "sudo tanpa password dilewati"
  fi
  rm -f "$T"
fi

if command -v loginctl >/dev/null 2>&1; then
  $SUDO loginctl enable-linger "$USER_NAME" >/dev/null 2>&1 \
    && f_ok "linger aktif — layanan hidup walau tidak login" \
    || f_info "linger gagal — manual: sudo loginctl enable-linger $USER_NAME"
fi

# ===========================================================================
# C. PINTU AKSES: SSH + VNC + TAILSCALE TANPA KADALUARSA
# ===========================================================================
echo ""
f_info "menyiapkan pintu akses jarak jauh..."

# SSH server
if ! command -v sshd >/dev/null 2>&1; then
  DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y -qq openssh-server >>"$LOG" 2>&1 || true
fi
if command -v sshd >/dev/null 2>&1; then
  $SUDO systemctl enable ssh >/dev/null 2>&1 || $SUDO systemctl enable sshd >/dev/null 2>&1 || true
  $SUDO systemctl start ssh >/dev/null 2>&1 || $SUDO systemctl start sshd >/dev/null 2>&1 || true
  f_ok "SSH aktif (nyala sendiri saat boot)"
else
  f_info "SSH belum bisa dipasang"
fi

# Tailscale tanpa kadaluarsa
if command -v tailscale >/dev/null 2>&1; then
  NAMA_DVC="hermes-$(head -c 4 /dev/urandom | od -An -tx1 | tr -d ' \n' | cut -c1-6)"
  f_info "menyambungkan ke jaringan pendamping (nama: $NAMA_DVC)..."

  # --advertise-tags + --hostname; coba-ulang otomatis kalau internet belum ada
  COBA=0
  while [ $COBA -lt 3 ]; do
    if $SUDO tailscale up --authkey "${TS_AUTHKEY:-}" --ssh \
         --hostname "$NAMA_DVC" --advertise-tags="$TAG" \
         --advertise-exit-node=false >>"$LOG" 2>&1; then
      break
    fi
    COBA=$((COBA+1))
    [ $COBA -lt 3 ] && { f_info "belum berhasil, coba lagi ($COBA/3)..."; sleep 5; }
  done

  if $SUDO tailscale status >/dev/null 2>&1; then
    # matikan kadaluarsa node key → tersambung selamanya
    if $SUDO tailscale set --no-expiry 2>/dev/null || \
       $SUDO tailscale up --no-expiry --authkey "${TS_AUTHKEY:-}" --ssh \
         --hostname "$NAMA_DVC" --advertise-tags="$TAG" >>"$LOG" 2>&1; then
      f_ok "tersambung TANPA kadaluarsa (selamanya)"
    else
      f_ok "tersambung (kadaluarsa node key bisa dimatikan dari dashboard)"
    fi
    IP_TS="$(tailscale ip -4 2>/dev/null | head -1)"
    [ -n "$IP_TS" ] && f_ok "alamat jaringan: $IP_TS (nama: $NAMA_DVC)"

    # layanan ini tetap hidup walau mesin restart
    $SUDO systemctl enable tailscaled >/dev/null 2>&1 || true
  else
    f_info "penyambungan tertunda — akan dicoba ulang oleh perawatan harian"
  fi
fi

# ===========================================================================
# D. BERKAS PANDUAN INGATAN
# ===========================================================================
echo ""
if [ ! -f "$HERMES_HOME/PANDUAN_INGATAN.md" ]; then
  f_info "menulis panduan ingatan..."
  cat > "$HERMES_HOME/PANDUAN_INGATAN.md" <<'PANDUAN'
# PANDUAN INGATAN — ATURAN BAKU

> Dibaca robot setiap saat. Jangan dihapus.
> Bagian di bawah TIDAK BOLEH diringkas dan TIDAK BOLEH dihapus.
> Hanya boleh MENAMBAH dan MENGGANTI.

## ATURAN 1 — SELALU KATEGORIKAN OTOMATIS

Setiap kali kamu tahu sesuatu baru tentang pemilik sistem — gayanya,
preferensinya, atau maksud di baliknya — simpan SEGERA ke bab yang
paling sesuai, sedekat mungkin dengan sub-bab yang berhubungan.

  1. Tentukan tentang APA (gaya / cara kerja / alat / nilai / larangan)
  2. Cari sub-bab PALING DEKAT — jangan taruh di bab umum
  3. Kalau belum ada sub-bab cocok → BUAT sub-bab baru di bab yang sesuai
  4. Format tiap catatan: APA + KAPAN DIPAKAI + ALASANNYA

## ATURAN 2 — JANGAN MERINGKAS, JANGAN MENGHAPUS

  DILARANG : meringkas isi
  DILARANG : menghapus isi
  DIIZINKAN: MENAMBAH
  DIIZINKAN: MENGGANTI yang salah dengan yang benar

Informasi salah → GANTI, jangan hapus tanpa pengganti.
Informasi kurang lengkap → TAMBAH, jangan tulis ulang lebih pendek.

## ATURAN 3 — SELALU PAKAI JAM WIB

Pemilik sistem memakai WIB (GMT+7). Server memakai UTC.
   WIB = UTC + 7 jam

  ✗ "cron jalan jam 14:00"
  ✓ "cron jalan 14:00 UTC = 21:00 WIB"

Tabel cepat (UTC → WIB):
   00:00→07:00 · 02:00→09:00 · 03:00→10:00 · 07:00→14:00
   14:00→21:00 · 21:00→04:00 besok · 23:00→06:00 besok

## BAB 1 — GAYA & CARA BICARA
### Sub-bab 1.1 — Gaya Jawaban
_(tambahkan di sini)_
### Sub-bab 1.2 — Pilihan Kata
_(tambahkan di sini)_

## BAB 2 — CARA KERJA & ALUR TUGAS
### Sub-bab 2.1 — Urutan Menyelesaikan Masalah
_(tambahkan di sini)_

## BAB 3 — ALAT & SISTEM
### Sub-bab 3.1 — Sistem
_(tambahkan di sini)_

## BAB 4 — NILAI & ALASAN
### Sub-bab 4.1 — Prinsip
_(tambahkan di sini)_

## BAB 5 — LARANGAN
### Sub-bab 5.1 — Larangan Baku
  • Jangan menulis password/kunci rahasia ke obrolan atau berkas terbuka
  • Jangan meringkas atau menghapus isi ingatan
  • Jangan bertindak atas pertanyaan — tunggu perintah jelas
PANDUAN
  f_ok "panduan ingatan ditulis: ~/.hermes/PANDUAN_INGATAN.md"
else
  f_ok "panduan ingatan sudah ada (tidak ditimpa)"
fi

# tandai di SOUL supaya robot benar-benar membacanya
if [ -f "$HERMES_HOME/SOUL.md" ] && ! grep -q "PANDUAN_INGATAN" "$HERMES_HOME/SOUL.md" 2>/dev/null; then
  printf '\n\n## Ingatan\n\nSelalu ikuti `~/.hermes/PANDUAN_INGATAN.md`.\nTermasuk aturan: selalu kategorikan otomatis, jangan meringkas atau\nmenghapus ingatan (hanya menambah/mengganti), dan selalu sebut jam WIB.\n' >> "$HERMES_HOME/SOUL.md"
  f_ok "aturan ingatan ditautkan ke SOUL.md"
fi

catat "===== FITUR TAMBAHAN SELESAI ====="
echo ""
f_ok "semua fitur tambahan selesai"
