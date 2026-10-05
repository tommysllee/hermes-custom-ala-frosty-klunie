# BACKUP LENGKAP & PEMULIHAN

> Terakhir diperbarui: 4 Okt 2026 · 09:15 WIB

Robot Anda otomatis mencadangkan **seluruh dirinya** dua kali sehari.
Panduan ini menjelaskan apa yang disalin, di mana disimpan, dan cara
memulihkannya kalau komputer rusak.

---

## 1. APA YANG DICADANGKAN

Semuanya. Bukan cuma pengaturan:

```
OTAK ROBOT
  • skills/          kemampuannya
  • cron/            tugas terjadwalnya
  • templates/       contoh siap pakai
  • knowledge/       bahan pengetahuannya

WATAK ROBOT
  • SOUL.md          kepribadiannya
  • profiles/        semua profil (kalau ada beberapa)
  • config.yaml      seluruh pengaturannya
  • .env             kunci aksesnya (rahasia!)

ALAT KERJA
  • scripts/         skrip bantuannya
  • hooks/           pemicu otomatisnya
  • remote-view/     alat bantu layar jarak jauh

INGATANNYA
  • sessions/        riwayat percakapan
  • state.db         basis data ingatan
  • session_search.db indeks pencarian
```

**Kenapa lengkap?** Kalau cuma dicadangkan pengaturannya, robotnya harus
dilatih dari nol. Dengan cara ini, robot baru langsung jadi seperti sedia
kala — sama seperti memulihkan seluruh isi ponsel dari cadangan.

---

## 2. DI MANA DISIMPAN

```
~/hermes-backup/                        ← di komputer Anda
   hermes-snapshot-20261004_0900.tar.zst
   hermes-snapshot-20261004_0900.CATATAN.txt

Google Drive (kalau disiapkan)
   gdrive:hermes-backup/                ← di awan, aman kalau komputer rusak
```

⚠️ **Cadangan sengaja disimpan DI LUAR folder `~/.hermes`.**
Kalau disimpan di dalam, cadangan akan ikut hilang saat `.hermes` rusak.
Itu sama saja tidak punya cadangan.

---

## 3. JADWAL

```
02:00 UTC = 09:00 WIB     cadangan pagi
14:00 UTC = 21:00 WIB     cadangan malam
14:00 UTC = 21:00 WIB     perawatan harian (bersih-bersih)

Cadangan > 30 hari dibuang otomatis (hemat ruang)
```

---

## 4. CARA MEMULIHKAN (ALA TWRP)

Simpan dulu berkas `full-backup.sh` di luar folder `.hermes`,
misalnya di folder rumah. Lalu:

```bash
cd ~
bash full-backup.sh --pulihkan ~/hermes-backup/hermes-snapshot-XXX.tar.zst
```

Atau langsung dengan tar:

```bash
cd ~
tar --zstd -xf ~/hermes-backup/hermes-snapshot-XXX.tar.zst
```

**Apa yang terjadi:**

```
1. Sistem lama Anda dipindah ke  ~/.hermes-lama-<tanggal>
   (tidak dihapus — kalau pemulihan gagal, masih bisa kembali)
2. Isi cadangan dikembalikan ke   ~/.hermes
3. Anda diminta menjalankan:      hermes gateway restart
```

**Kalau ada yang salah:** kembalikan sistem lama —

```bash
rm -rf ~/.hermes
mv ~/.hermes-lama-<tanggal> ~/.hermes
hermes gateway restart
```

---

## 5. MENGHUBUNGKAN KE GOOGLE DRIVE

Cadangan di komputer saja masih berisiko: kalau komputernya rusak atau
dicuri, cadangannya ikut hilang. Menghubungkan ke Google Drive
menyelesaikannya.

### Langkah 1 — Buat aplikasi di Google Cloud

```
1. Buka  https://console.cloud.google.com/
2. Buat proyek baru (misalnya: hermes-backup)
3. Buka   https://console.cloud.google.com/apis/library/drive.googleapis.com
   → klik ENABLE
4. Buka   https://console.cloud.google.com/apis/credentials
   → Create Credentials → OAuth client ID
   → Application type: Desktop app
   → Create
5. Unduh JSON-nya → pindahkan jadi:  ~/.config/rclone/gdrive.json
```

### Langkah 2 — Hubungkan

```bash
rclone config
```

Ikuti:

```
n                          → remote baru
name: gdrive               → namanya harus "gdrive" (huruf kecil)
Storage: drive             → pilih Google Drive
client_id: (kosongkan)
client_secret: (kosongkan)
scope: 1                   → Full access
root_folder_id: (kosong)
service_account_file: (kosong)
Edit advanced config: n
Use web browser: n         → karena ini server
   → akan muncul tautan; buka di HP/komputer Anda
   → izinkan → salin kode → tempel di terminal
Configure as Shared Drive: n
y                          → simpan
q                          → keluar
```

### Langkah 3 — Uji

```bash
rclone listremotes                      # harus muncul: gdrive:
bash ~/.hermes/scripts/full-backup.sh
rclone ls gdrive:hermes-backup/         # harus muncul arsipnya
```

---

## 6. MENGHUBUNGKAN KE GITHUB

Cara ini cadangannya **berversi** — bisa kembali ke titik mana pun.

### Langkah 1 — Buat token GitHub

```
1. Buka  https://github.com/settings/tokens?type=beta
2. Generate new token (fine-grained)
3. Name: hermes-backup
4. Expiration: 90 days (atau No expiration kalau memang mau)
5. Repository access: Only select repositories
   → pilih repo cadangan Anda (harus dibuat dulu)
6. Permissions → Repository permissions:
       Contents .............. Read and write
       Administration ......... Read and write
7. Generate token → SALIN (hanya muncul sekali)
```

### Langkah 2 — Simpan aman & hubungkan

```bash
mkdir -p ~/.hermes/kredensial
printf '%s' '<token Anda>' > ~/.hermes/kredensial/github-backup.token
chmod 600 ~/.hermes/kredensial/github-backup.token

# setel git supaya tidak minta sandi lagi
git config --global credential.helper store
```

> **Kalau Anda memakai Perplexity/AI untuk memandu:**
> minta AI itu melihat halaman GitHub tersebut lebih dulu
> (`https://github.com/settings/tokens?type=beta`) supaya langkahnya sesuai
> tampilan terkini — halaman GitHub sering berubah. Pola dasar yang harus
> dipahami: pilih **repository** dulu → baru **permissions** → baru generate.

---

## 7. PERINTAHKAN KE AI ANDA

Kalau Anda memakai AI untuk memandu, tempelkan kalimat ini:

```
Cadangkan sistem Hermes saya ke Google Drive dan/atau GitHub.

Sebelum memandu, LIHAT DULU halaman-halaman ini di internet supaya
langkahnya akurat (halaman sering berubah):
  • https://rclone.org/drive/                    (cara rclone + Drive)
  • https://github.com/settings/tokens?type=beta (cara token GitHub)
  • https://console.cloud.google.com/apis/credentials (cara OAuth)

Lalu pandu saya langkah demi langkah. Jangan menebak strukturnya.
Sebutkan selalu jam WIB saat memberi waktu/jadwal.
```

---

## 8. YANG PERLU ANDA TAHU

```
✅ Cadangan lengkap       → robot bisa hidup kembali utuh
✅ Disimpan di luar       → selamat kalau .hermes rusak
✅ Ke Drive               → selamat kalau komputer hilang
✅ Ke GitHub              → bisa kembali ke titik mana pun

⚠️ .env berisi kunci rahasia → simpan remote Drive sebagai PRIVATE
⚠️ Cadangan > 30 hari dihapus otomatis → kalau perlu lama, ubah jadwalnya
```

---

## 9. JIKA BACKUP GAGAL

```bash
# lihat catatan
tail -50 ~/.hermes/logs/full-backup.log

# uji manual
bash ~/.hermes/scripts/full-backup.sh

# cek ruang disk
df -h ~
```

Masalah tersering:

```
"zstd tidak tersedia"   → sudo apt-get install -y zstd
"rclone tidak ada"      → sudo apt-get install -y rclone
"Drive belum disiapkan" → ulangi bagian 5 di atas
```
