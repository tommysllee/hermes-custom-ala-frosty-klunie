# Backup Otomatis & Google Drive

> **Terakhir diperbarui: Sabtu, 03 Okt 2026 · 16:50 WIB**

Robot Anda otomatis mencadangkan dirinya **2x sehari**. Panduan ini
menjelaskan cara memastikan cadangannya benar-benar tersimpan.

---

## Apa yang dicadangkan

```
~/.hermes/          <- seluruh pengaturan, obrolan, keterampilan
   ↓
~/backups_agent/agent_YYYYMMDD_HHMM.tar.gz
   ↓
Google Drive Anda (kalau sudah dihubungkan)
```

- **Kapan:** 2x sehari (jam 02:00 dan 14:00)
- **Disimpan:** 7 hari terakhir (yang lebih lama dihapus otomatis)
- **Ukuran:** biasanya 10–100 MB per arsip

---

## Cek apakah backup jalan

```bash
# Lihat arsip yang sudah dibuat
ls -lh ~/backups_agent/

# Lihat catatan backup
cat ~/.hermes/logs/backup.log

# Cek jadwalnya terdaftar
crontab -l | grep backup-agent
```

**Sehat** kalau: ada file `.tar.gz` di `~/backups_agent/` dan
`backup.log` berisi baris tanggal.

---

## Menghubungkan Google Drive (rclone)

**Ini perlu Anda lakukan sekali.** Tanpa ini, cadangan hanya tersimpan
di komputer — kalau komputernya rusak, cadangan ikut hilang.

### Langkah 1 — Jalankan penyiapan

```bash
rclone config
```

Ikuti tanya-jawabnya:

```
n) New remote                    <- ketik: n  lalu Enter
name> gdrive                     <- ketik: gdrive  lalu Enter
Storage> drive                   <- ketik: drive (atau nomor untuk Google Drive)
client_id>                       <- Enter saja (kosongkan)
client_secret>                   <- Enter saja (kosongkan)
scope> 1                         <- ketik: 1 (akses penuh)
root_folder_id>                  <- Enter saja
service_account_file>            <- Enter saja
Edit advanced config? n          <- ketik: n
Use auto config? y               <- ketik: y
```

### Langkah 2 — Login Google

Browser akan terbuka (atau tautan muncul di layar). Login dengan akun
Google Anda, lalu klik **Allow**.

**Server tanpa layar?** Setelah `Use auto config? y`, akan muncul pesan
bahwa browser tidak bisa dibuka — pilih **n** untuk cara manual, lalu
buka tautan yang muncul di HP/laptop Anda, salin kodenya, tempel balik.

### Langkah 3 — Uji

```bash
# Cek 'gdrive' sudah terdaftar
rclone listremotes

# Uji kirim
rclone lsd gdrive:
```

Kalau muncul daftar folder Drive Anda → **berhasil**.

### Langkah 4 — Backup berikutnya otomatis ke Drive

Backup jam 14:00 (atau 02:00 berikutnya) akan otomatis mengirim ke Drive.
Untuk menguji sekarang tanpa menunggu:

```bash
~/.hermes/scripts/backup-agent.sh
```

---

## Ke mana cadangannya pergi di Drive

```
gdrive:/
  └── agent_20261003_1400.tar.gz
      agent_20261003_0200.tar.gz
      ...
```

Kalau ingin dirapikan ke dalam folder, edit `~/.hermes/scripts/backup-agent.sh`
dan ubah bagian `rclone copy` menjadi:

```bash
rclone copy "$ARSIP" "gdrive:AI-Agent-Backup/" -q 2>/dev/null
```

---

## Memulihkan dari cadangan

```bash
# 1. Lihat isi arsip dulu (jangan langsung timpa)
tar -tzf ~/backups_agent/agent_20261003_1400.tar.gz | head -20

# 2. Pulihkan
cd ~
tar -xzf ~/backups_agent/agent_20261003_1400.tar.gz

# 3. Nyalakan ulang robot
sudo systemctl restart hermes-gateway
```

**Peringatan:** langkah 2 akan **menimpa** pengaturan yang ada. Kalau
ragu, pindahkan dulu folder lama:

```bash
mv ~/.hermes ~/.hermes.lama
tar -xzf ~/backups_agent/agent_20261003_1400.tar.gz
```

---

## Backup ke GitHub (nanti, kalau sudah diajari)

Saat ini cadangan **hanya ke Google Drive** — sesuai permintaan.

Kalau nanti ingin cadangan juga ke GitHub (lebih tahan lama), teknisi
Anda akan mengajari caranya. Yang dibutuhkan:

```
1. Akun GitHub
2. Repository private
3. Kunci akses (Personal Access Token)
4. Skrip tambahan untuk mengirim cadangan
```

Bagian ini **tidak** perlu sekarang. Drive sudah cukup.

---

## Pemecahan masalah

| Gejala | Sebab | Perbaikan |
|---|---|---|
| Tidak ada file di `~/backups_agent/` | Cron belum jalan | `crontab -l \| grep backup-agent` |
| Ada file lokal, tidak sampai Drive | rclone belum disiapkan | Ikuti panduan di atas |
| `rclone: command not found` | Belum terpasang | `sudo apt install rclone` |
| Gagal login Google | Tautan kedaluwarsa | Ulangi `rclone config` |
| Disk penuh | Arsip menumpuk | Arsip >7 hari otomatis dihapus |
| Ingin ubah jam backup | Jadwal tidak cocok | `crontab -e` lalu ubah `0 2,14 * * *` |

---

## Yang perlu diingat

```
1. Backup jalan otomatis 2x sehari (02:00 dan 14:00).
2. Tanpa Google Drive, cadangan hanya di komputer — rawan hilang.
3. Menghubungkan Drive = sekali saja, lewat 'rclone config'.
4. Arsip lebih dari 7 hari dihapus otomatis (hemat disk).
5. GitHub belum aktif — hanya Drive. Sesuai permintaan.
6. Uji pemulihan SEKALI supaya Anda tahu caranya sebelum panik.
```
