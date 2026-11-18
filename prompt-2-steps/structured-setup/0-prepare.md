# LANGKAH 0 — PERSIAPAN SEBELUM APA PUN

> **Terakhir update:** Selasa, 17 November 2026 · 23:10 WIB
> **Siapa yang mengerjakan:** orang yang memasang (bukan AI). Ini semua di luar sistem.
> **Jangan lewati satu pun.** Kalau langkah 0 belum beres, langkah 1 & 2 akan gagal
> dengan error yang membingungkan.

---

## Kenapa langkah ini ada

Script `1-*` dan `2-*` menganggap mesin **baru, bersih, dan tersambung internet**.
Kalau salah satu dari empat hal di bawah belum siap, script tetap jalan tapi
berhenti di tengah — dan sisa pekerjaannya harus diulang manual.

Empat hal itu: **email khusus**, **Ubuntu Server terpasang**, **Hermes blank slate
terpasang**, dan **perangkat fisik tersedia**.

---

## A. Buat Gmail khusus klien (5 menit)

**Jangan pakai email pribadi bos.** Akun Google ini akan dipegang AI agent untuk
Drive, Sheets, dan backup. Kalau tercampur email pribadi, riwayat dan berkas jadi
kacau dan susah dipisah.

```
Pola nama  : <nama-klien>.hermes@gmail.com
Contoh     : gunawan.hermes@gmail.com
             yanuar.hermes@gmail.com

Yang perlu dicatat saat mendaftar:
  - nomor HP untuk verifikasi (boleh nomor bos atau nomor pemasang)
  - tanggal lahir  (jangan asal — dipakai kalau akun perlu dipulihkan)
  - password       → simpan di tempat aman, BUKAN di repo
```

**Setelah jadi, langsung aktifkan 2FA** dan simpan kode cadangannya. Akun ini
memegang backup seluruh sistem; kalau hilang, backup ikut hilang.

---

## B. Pasang Ubuntu Server

### Yang perlu diunduh

```
Ubuntu Server 24.04 LTS  →  https://ubuntu.com/download/server
Rufus (Windows) atau balenaEtcher  →  untuk membuat USB bootable
```

### Saat instalasi — jawab seperti ini

| Pertanyaan installer | Jawaban |
|---|---|
| Nama & server name | **tslconsulting** (harus sama dengan username SSH) |
| Username | **tslconsulting** |
| Password | password yang kuat, catat |
| Install OpenSSH server | **YA — centang** |
| Docker / snaps | bebas; `1-*` script memasang Docker sendiri |

> **Penting:** username **harus `tslconsulting`**. Script `1-*` membuat user itu
> untuk akses remote. Kalau installer sudah membuatnya, script akan memakai yang ada.

---

## C. Pasang Hermes blank slate

Pilih **satu** sesuai OS mesin yang dipakai. Jangan pasang dua kali.

### C.1 Linux / Ubuntu Server

Jalankan **di terminal Ubuntu** (bukan lewat SSH):

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

### C.2 macOS

Buka **Terminal** (jangan pakai `sudo`), lalu:

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

### C.3 Windows 10 / 11 — native, tanpa WSL

Buka **PowerShell** atau Windows Terminal (tidak perlu admin), lalu:

```powershell
iex (irm https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.ps1)
```

Pemasang menaruh Hermes di `%LOCALAPPDATA%\hermes`, menambahkan `hermes` ke
PATH pengguna, dan **terminal harus ditutup lalu dibuka lagi** agar perintah
`hermes` dikenali.

> **Untuk ketiga OS:** selalu benar kan jam lebih dulu. Di Ubuntu/macOS:
> `sudo timedatectl set-timezone Asia/Jakarta` (Linux) atau
> System Settings → General → Date & Time (macOS). Di Windows:
> Settings → Time & language → Date & time → **Time zone: (UTC+07:00) Jakarta**.
> Kalau zona waktu salah, semua jadwal cron akan meleset 7 jam.

> Kalau tautan di atas berubah, ambil yang berlaku dari
> https://hermes-agent.nousresearch.com/docs/getting-started/installation
> dan **cek dulu isi skripnya** sebelum dijalankan
> (`curl -fsSL <url> -o /tmp/x.sh && less /tmp/x.sh`).

### Pilih model saat pertama dijalankan

```
Model yang dipakai : StepFun (gratis)
Cara memilih       : jalankan `hermes` lalu ikuti pemilih model,
                     pilih penyedia StepFun
```

StepFun gratis dipakai untuk **langkah awal saja**, supaya bisa masuk ke chat dan
menyelesaikan langkah berikutnya tanpa biaya. Nanti bisa diganti ke model berbayar
(lihat `3-switch-focused-deepseek.md`).

### Verifikasi sebelum lanjut

```bash
hermes --version          # harus keluar nomor versi, bukan "command not found"
timedatectl               # Linux: Time zone harus Asia/Jakarta (WIB, +0700)
```

```powershell
# Windows
hermes --version
Get-TimeZone | Select-Object Id      # harus: SE Asia Standard Time (WIB)
```

Kalau dua pemeriksaan ini belum benar, **jangan lanjut ke Langkah 1**.

---

## D. Perangkat fisik yang wajib ada

Script tidak bisa bekerja tanpa ini. Siapkan **sebelum** mulai:

```
[ ] Kabel HDMI            — untuk menyambung ke monitor saat instalasi
[ ] Keyboard USB          — keyboard bawaan laptop bermasalah di installer
[ ] Kemampuan Wi-Fi       — kalau tidak ada kabel LAN:
       - Wi-Fi bawaan mesin, ATAU
       - adapter Wi-Fi USB yang didukung Ubuntu
[ ] Kabel LAN (disarankan) — lebih stabil dan langsung terdeteksi installer
[ ] Flashdisk ≥ 8 GB      — untuk media instalasi
[ ] Monitor               — minimal untuk melihat proses instalasi
```

> **Kalau mesin tidak punya Wi-Fi dan tidak ada kabel LAN**, instalasi tidak bisa
> menyelesaikan pembaruan paket. Sediakan adapter Wi-Fi USB atau kabel LAN.

---

## E. Set jam ke WIB — WAJIB, jangan dilewati

Ini yang paling sering terlewat dan akibatnya berantakan: **semua jadwal cron
jadi meleset 7 jam**, dan pesan terjadwal terkirim di jam yang salah.

```bash
sudo timedatectl set-timezone Asia/Jakarta
timedatectl
```

Keluaran yang benar:

```
               Local time: ... WIB
           Time zone: Asia/Jakarta (WIB, +0700)
```

> Di Windows/Mac, zona waktu diatur lewat Settings sistem masing-masing.
> Script `1-deep-win-powershell.ps1` dan `1-deep-mac-spotlightterminal.sh`
> tidak mengubah zona waktu — atur manual sebelum menjalankan Langkah 2.

---

## Checklist langkah 0

Centang satu per satu. Jangan mulai Langkah 1 sebelum semuanya tercentang.

```
[ ] Gmail khusus klien sudah dibuat + 2FA aktif + kode cadangan disimpan
[ ] Ubuntu Server 24.04 LTS terpasang
[ ] Username sistem = tslconsulting
[ ] OpenSSH server dicentang saat instalasi
[ ] Hermes blank slate terpasang (`hermes --version` menjawab)
[ ] Model StepFun (gratis) sudah dipilih dan bisa chat
[ ] timedatectl menunjukkan Asia/Jakarta  ← WAJIB
[ ] Kabel HDMI tersedia
[ ] Keyboard USB tersedia
[ ] Wi-Fi / kabel LAN tersedia dan tersambung
[ ] Monitor tersedia
[ ] Password sistem dicatat di tempat aman (bukan di repo)
```

---

## Setelah semua tercentang

```
Langkah 1  →  1-deep-linubu-terminal.sh     (Linux/Ubuntu, superuser)
              1-deep-win-powershell.ps1      (Windows, admin)
              1-deep-mac-spotlightterminal.sh (Mac, sudo)

Langkah 2  →  2-allin-linubu.sh              (Linux/Ubuntu; jalankan 2a–2e)
              Windows/macOS: belum ada jalur otomatis — lihat README

Langkah 3  →  3-switch-focused-deepseek.md
Langkah 4  →  4-mandatory-offer.md
```
