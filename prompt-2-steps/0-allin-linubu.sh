#!/usr/bin/env bash
# ============================================================================
# 0-allin-linubu.sh — SATU LANGKAH: persiapan infra + restore penuh
# ============================================================================
# Untuk mesin Ubuntu/Debian BARU setelah Hermes di-install (blank slate,
# local terminal backend, everything disabled).
#
# JALANKAN (copy-paste satu baris ini di terminal):
#   curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/0-allin-linubu.sh -o /tmp/0-allin-linubu.sh && bash /tmp/0-allin-linubu.sh
#
# Interaksi yang dibutuhkan (hanya 2, semuanya di awal):
#   1. password sudo  — momen "kasih yes" (sudo cache 15 menit cukup utk sesi)
#   2. token GitHub   — repo backup private butuh autentikasi PERTAMA kali;
#                       diminta sekali, input tersembunyi, TIDAK disimpan di
#                       internet. (Alternatif tanpa prompt: set GH_TOKEN=xxx)
#
# KERAS: tahap 2 (restore) TIDAK PERNAH jalan kalau tahap 1 (infra) gagal —
# set -e + pengecekan eksplisit. Sama amannya dengan alur 2-langkah lama.
#
# Variabel uji (tidak dipakai di pemakaian normal):
#   LEWATI_PREP=1        lewati tahap infra (hanya utk simulasi)
#   GH_TOKEN=xxx         token tanpa prompt
#   WUKU_REPO_URL=...    override URL repo backup (utk uji lokal)
#   RESTORE_ARGS="..."   argumen tambahan utk restore.sh (utk uji simulasi)
# ============================================================================
set -euo pipefail

PUB_RAW="https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps"
REPO_PRIV="${WUKU_REPO_URL:-https://github.com/tommysllee/wuku-private-auto-backup.git}"
# token clone: lewat VARIABEL saja (tidak masuk riwayat shell, tidak tertulis
# di URL permanen — remote repo dibersihkan setelah clone)
TOK="${GH_TOKEN:-}"

echo "══════ TAHAP 1/2 — PERSIAPAN INFRA (SSH, Tailscale, Docker, gateway) ══════"

if [ "${LEWATI_PREP:-0}" = "1" ]; then
  echo "  (LEWATI_PREP=1 — mode simulasi, tahap infra dilewati)"
else
  # unduh ke file dulu (BUKAN curl|bash) supaya `read` tetap bisa baca terminal
  curl -fsSL "$PUB_RAW/1-deep-linubu-terminal.sh" -o /tmp/1-deep-linubu-terminal.sh
  bash /tmp/1-deep-linubu-terminal.sh    # <- password sudo diminta di sini
fi

echo "══════ TAHAP 2/2 — RESTORE PENUH DARI SNAPSHOT ══════"

# Repo backup PRIVATE butuh kredensial untuk clone PERTAMA kali (sudah dibuktikan:
# clone tanpa kredensial = "fatal: could not read Username"). Ambil dari GH_TOKEN
# atau minta sekali (input tersembunyi). URL override (uji lokal) = tanpa token.
NEED_TOK=0
case "$REPO_PRIV" in https://github.com/*) NEED_TOK=1 ;; esac
if [ "$NEED_TOK" = "1" ] && [ -z "$TOK" ]; then
  printf 'Token GitHub PAT (repo backup — sekali saja, input tersembunyi): '
  IFS= read -rs TOK
  echo
fi
if [ "$NEED_TOK" = "1" ] && [ -z "$TOK" ]; then
  echo "ERROR: token kosong — restore tidak jalan (tahap 1 tetap selesai)." >&2
  exit 1
fi

CLONE_URL="$REPO_PRIV"
[ "$NEED_TOK" = "1" ] && CLONE_URL="https://x-access-token:${TOK}@github.com/tommysllee/wuku-private-auto-backup.git"

# TMPDIR bisa diarahkan (mis. VPS dengan /tmp kecil). Bawaan: ~/.cache
TMPBASE="${TMPDIR:-$HOME/.cache}"
mkdir -p "$TMPBASE" 2>/dev/null || TMPBASE=/tmp
WORK="$(mktemp -d "$TMPBASE/restore-wuku.XXXXXX")"
echo "  meng-clone snapshot ke $WORK/repo ..."
if ! git clone -q "$CLONE_URL" "$WORK/repo" 2>"$WORK/clone.err"; then
  echo "ERROR: clone gagal — token salah/kedaluwarsa atau jaringan." >&2
  cat "$WORK/clone.err" >&2
  rm -rf "$WORK"
  exit 1
fi
cd "$WORK/repo"
# bersihkan token dari remote URL — sesudah ini kredensial datang dari
# ~/.git-credentials yang dipulihkan restore itu sendiri
git remote set-url origin "https://github.com/tommysllee/wuku-private-auto-backup.git" 2>/dev/null || true

# RESTORE_ARGS dipakai HANYA untuk uji simulasi (mis. --tanpa-docker)
# shellcheck disable=SC2086
./restore.sh ${RESTORE_ARGS:-}

echo "══════ SELESAI — cek laporan VERIFIKASI 9/9 di atas ══════"
