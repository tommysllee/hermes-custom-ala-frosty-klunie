# LANGKAH 0 — PERSIAPAN SEBELUM APA PUN

> **Terakhir update:** Senin, 23 November 2026 · 08:55 WIB
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

## A. Buat Gmail khusus + akun pendukung (15 menit)

**Jangan pakai email pribadi bos.** Akun Google ini akan dipegang AI agent untuk
Drive, Sheets, dan backup. Kalau tercampur email pribadi, riwayat dan berkas jadi
kacau dan susah dipisah.

### A.1 Format email — pakai pola ini, jangan dikarang sendiri

```
Pola  : cli.<nama>.<julukan>.<os>@gmail.com
       cli   = penanda akun ini dipakai untuk CLI/agent
       nama  = nama depan klien, huruf kecil
       julukan = panggilan singkat klien (boleh nama belakang)
       os    = sistem yang dipasang: win | mac | linubu

Contoh: cli.gunawan.gun.win@gmail.com
        cli.yanuar.yan.linubu@gmail.com
        cli.siti.siti.mac@gmail.com
```

Nama yang dipakai harus **konsisten dengan username sistem** (lihat bagian B):
kalau OS-nya Windows, akhiran `win`; macOS `mac`; Ubuntu/Linux `linubu`.

Yang perlu dicatat saat mendaftar:

```
  - nomor HP untuk verifikasi (boleh nomor bos atau nomor pemasang)
  - tanggal lahir  (jangan asal — dipakai kalau akun perlu dipulihkan)
  - password       → simpan di tempat aman, BUKAN di repo
```

**Setelah jadi, langsung aktifkan 2FA** dan simpan kode cadangannya. Akun ini
memegang backup seluruh sistem; kalau hilang, backup ikut hilang.

### A.2 Akun lain yang wajib dibuat di hari yang sama

Bikin semuanya sekarang, jangan dicicil. Kalau satu belum ada, langkah 3 akan
berhenti di tengah.

```
[ ] Gmail          → pola cli.<nama>.<julukan>.<os>@gmail.com  (bagian A.1)
[ ] GitHub         → akun baru (bukan akun pribadi bos)
                     + repo PRIVATE bernama "Pull Issue Content"
                     (nama ini yang dipakai script; jangan diganti)
[ ] Groq           → console.groq.com  → API key untuk STT
                     (Whisper large-v3, bahasa "id")
[ ] OpenRouter     → akun utama, beri label "tron"
                     → untuk model DeepSeek (dipakai di langkah 3)
[ ] Focused DeepSeek → sub-akun/API key terpisah di OpenRouter
                     (dibuat sekarang, tapi TIDAK dipakai di langkah 0)
```

> **Jangan tertukar:** langkah 0 memakai **OpenRouter DeepSeek (akun "tron")**.
> **Focused DeepSeek tidak dipakai di langkah 0** — sub-akun itu disiapkan
> sekarang supaya siap kalau nanti diperlukan, bukan untuk dipasang hari ini.

Semua kredensial (password, API key, token) disimpan **di luar repo**. Kalau
sampai masuk repo lalu repo ter-push, kredensial itu dianggap bocor.

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
Model yang dipakai : OpenRouter DeepSeek (akun "tron")
Cara memilih       : jalankan `hermes` lalu ikuti pemilih model,
                     pilih provider OpenRouter → model DeepSeek
Jangan pakai       : Focused DeepSeek (sub-akun itu disiapkan, belum dipasang)
```

Kalau ingin tahap awal tanpa biaya, boleh pakai model gratis lebih dulu — tapi
**target langkah 0 adalah Hermes jalan dengan OpenRouter DeepSeek**, karena
liputan `3-switch-focused-deepseek.md` menganggap model itu sudah aktif.

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
[ ] Kabel HDMI + Monitor  — minimal sampai instalasi selesai; setelah server
                            jalan dan SSH bisa, monitor tidak dipakai lagi
[ ] Keyboard USB          — keyboard bawaan laptop bermasalah di installer
[ ] Kemampuan Wi-Fi / LAN — salah satu wajib ada:
       - Wi-Fi bawaan mesin, ATAU
       - adapter Wi-Fi USB yang didukung Ubuntu
       - kabel LAN (paling stabil, langsung terdeteksi installer)
[ ] Flashdisk ≥ 8 GB      — untuk media instalasi Ubuntu Server LTS
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

### Urutan kerja — kerjakan dari atas ke bawah

```
a. [ ] Gmail + akun lainnya
       Gmail pola cli.<nama>.<julukan>.<os>@gmail.com
       + GitHub (repo private "Pull Issue Content")
       + Groq
       + OpenRouter (akun "tron")
       + sub-akun focused-deepseek
       → semua kredensial dicatat di luar repo

b. [ ] Ubuntu Server 24.04 LTS terpasang
       dari flashdisk, installer resmi

c. [ ] Username sistem = tslconsulting
       harus sama persis, huruf kecil semua

d. [ ] OpenSSH server DICENTANG saat instalasi
       kalau terlewat: sudo apt install openssh-server

e. [ ] Ganti zona waktu ke Jakarta
       sudo timedatectl set-timezone Asia/Jakarta
       timedatectl  → harus "Asia/Jakarta (WIB, +0700)"

f. [ ] Hermes terpasang + model OpenRouter DeepSeek
       catatan: pakai OpenRouter DeepSeek, BUKAN Focused DeepSeek
```

### Rincian

```
[ ] Gmail khusus sudah dibuat + 2FA aktif + kode cadangan disimpan
[ ] Akun GitHub baru + repo private "Pull Issue Content" sudah ada
[ ] Akun Groq + API key sudah ada (untuk STT bahasa "id")
[ ] Akun OpenRouter "tron" + API key sudah ada
[ ] Sub-akun focused-deepseek sudah dibuat (belum dipasang)
[ ] Ubuntu Server 24.04 LTS terpasang
[ ] Username sistem = tslconsulting
[ ] OpenSSH server dicentang saat instalasi
[ ] Hermes blank slate terpasang (`hermes --version` menjawab)
[ ] Model OpenRouter DeepSeek sudah dipilih dan bisa chat
[ ] timedatectl menunjukkan Asia/Jakarta  ← WAJIB
[ ] Kabel HDMI + monitor tersedia
[ ] Keyboard USB tersedia
[ ] Wi-Fi / kabel LAN tersedia dan tersambung
[ ] Flashdisk instalasi tersedia
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
