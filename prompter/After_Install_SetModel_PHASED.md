<!-- File: prompter/After_Install_SetModel_PHASED.md (DIBUAT BARU dari After_Install_SetModel.md — isi lama TIDAK ADA YANG DIHAPUS/DIRINGKAS, hanya dipindah, difix format, atau ditambah. Terakhir diperbarui: Rabu, 07 Okt 2026 · 15:35 WIB)
Cara pakai: paste langsung, atau di Linux/Mac: hermes chat -q "$(curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/prompter/After_Install_SetModel_PHASED.md)" -->

Aku sudah install hermes dan sudah pilih model berbayar yang pintar utk bootstrap dan self-repair (misal Modroute DSfr)... sekarang utk keperluanku selanjutnya, tolong aku sampai beres, Usahakan Tidak Involve aku selain minta API dan akses di akhir (karena aku ga paham teknologi)

> CATATAN EKSEKUSI (dibaca agent SEBELUM mulai):
> File ini punya DUA FASE. Urutan: FASE (1) dulu (butuh ijin tingkat tinggi/dalam), baru FASE (2) (cukup ijin biasa). Urutan EKSEKUSI fase (1): 1.1 cek marker → 1.2 cek akses → 1.3 pandu buka jendela admin → 1.4 cara eksekusi → b.5 → b.2 → b.3 → a.2 (bagian ijin tinggi) → 1.5 tulis marker → FASE (2). Urutan EKSEKUSI fase (2): 2.1 cek marker → 2.2 cek akses biasa → a.1 → a.2 sisanya → b.1 (+limit 4009) → b.4 → c.1, c.2, c.3, c.4. Usahakan tidak involve klien selain: (a) klik izin admin SEKALI di fase (1), (b) API & akses di akhir. Karena klien gaptek total, semua panduan harus CLICK-BY-CLICK (tunjukkan apa yang diklik, jangan cuma bilang "buka terminal").
> MARKER (penanda fase 1 selesai): file `~/.hermes/.setup_phase1.done` (Windows: `C:\Users\<username>\.hermes\.setup_phase1.done`). Isinya persis:
> ```
> os=linux|mac|windows
> done=<tanggal jam WIB>
> items=b.5,b.2,b.3,a.2-elevated
> ```
> Marker boleh ditulis HANYA kalau SEMUA poin fase (1) terverifikasi sukses. Ada yang gagal → perbaiki dulu, JANGAN tulis marker.
> Idempoten: marker sudah ada → langsung FASE (2). Marker belum ada → FASE (1) dulu. Jalankan ulang kapan pun = mulai dari pengecekan marker.
> Verifikasi WAJIB tiap poin (cek perintah, jangan cuma percaya log/sukses chat). Semua yang dieksekusi di fase (1) dicatat ke `~/.hermes/setup_phase1_log.txt` (Windows: `$env:PUBLIC\setup-log.txt`) supaya bisa dicek ulang.
> Peta pemindahan dari markdown lama (biar tidak ada yang hilang): (A) a.1 → FASE (2); (A) a.2 bagian ijin tinggi → FASE (1); (A) a.2 sisanya → FASE (2); (B) b.2, b.3, b.5 → FASE (1); (B) b.1, b.4 → FASE (2); (C) c.1–c.4 → FASE (2). Isi tiap bagian dibawah ini = isi asli dari markdown lama (tidak diringkas), plus penambahan yang ditandai [TAMBAHAN].

# FASE (1) — perlu ijin tingkat tinggi/dalam (system/admin)

## 1.1 Cek marker
- Cek file marker `~/.hermes/.setup_phase1.done`.
- Kalau ADA → loncat langsung ke FASE (2) (bawah).
- Kalau BELUM ADA → lanjut ke 1.2.

## 1.2 Cek apakah akses sudah di tingkat tinggi/dalam (bukan tingkat biasa)
- **Windows (PowerShell):**
```powershell
([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
```
`True` = sudah tingkat tinggi. `False` = masih tingkat biasa.
- **Linux:**
```bash
if [ "$(id -u)" = "0" ]; then echo ROOT; elif sudo -n true 2>/dev/null; then echo SUDO_BISA; else echo MASIH_BIASA; fi
```
`ROOT`/`SUDO_BISA` = sudah tingkat tinggi. `MASIH_BIASA` = masih tingkat biasa.
- **macOS:** sama seperti Linux (`id -u` = 0 → root; `sudo -n true` → admin; selain itu → masih biasa).
- Kalau SUDAH tingkat tinggi → lanjut 1.4. Kalau MASIH tingkat biasa → lanjut 1.3.

## 1.3 Masih tingkat biasa → pandu buka jendela terminal/powershell tingkat tinggi/dalam (CLICK-BY-CLICK, anggap orang SUPER GAPTEK)
- **Windows:**
  1. Klik ikon **Cari / Kotak pencarian** di pojok kiri bawah layar (ikon kaca pembesar ⌕).
  2. Ketik **powershell**.
  3. Di panel kanan, klik **"Jalankan sebagai administrator"** (bukan yang biasa).
  4. Muncul jendela biru **"Do you want to allow this app to make changes to your device?"** → klik **Yes**.
  5. Selesai kalau judul jendelanya tertulis **"Administrator: Windows PowerShell"**. Beri tahu klien: jendela ini yang dipakai sekarang.
- **Linux (Debian/Ubuntu):**
  1. Buka aplikasi **Terminal** (klik menu aplikasi → cari "Terminal").
  2. Ketik `sudo -s` lalu tekan **Enter**.
  3. Diminta password → ketik password klien (hurufnya TIDAK muncul saat diketik, itu normal) → tekan **Enter**.
  4. Selesai kalau prompt di awal baris berubah jadi `#`.
- **macOS:**
  1. Tekan **Cmd + Spasi**, ketik **Terminal**, tekan Enter (atau Launchpad → Terminal).
  2. Ketik `sudo -s` lalu tekan **Enter**.
  3. Diminta password → ketik password login Mac (TIDAK terlihat saat diketik, itu normal) → tekan **Enter**.
  4. Selesai kalau prompt berubah jadi `bash-3.2$` / root.

## 1.4 Cara menjalankan poin-poin fase ini (3 jalur, urut dicoba) [TAMBAHAN]
- **Jalur A (utama):** agent jalankan perintahnya SENDIRI lewat jalur ijin resmi Hermes:
  - Linux/macOS sesi interaktif: sudo akan memunculkan **masked password prompt** (klien ketik, agent tidak pernah melihat).
  - Headless/gateway: taruh `SUDO_PASSWORD` di `~/.hermes/.env` (lalu restart gateway) ATAU kalau sudo NOPASSWD sudah diset, pakai `sudo -n`.
  - Windows: jalankan script b.5 (dia self-elevate) → klien klik **YES** sekali di UAC.
  - KATA-KATAI ke klien sebelum minta izin: jelaskan dulu apa yang mau dipasang (poin b.5 sudah punya teks penjelasan bawaan).
- **Jalur B (cadangan kalau Jalur A tidak bisa):** minta klien jalankan blok perintah langsung di jendela Administrator/Root yang dibuka di 1.3 (copy-paste, Enter). Script b.5 menulis log sendiri ke `$env:PUBLIC\setup-log.txt` (Windows) / `/tmp/setup-log.txt` (Linux).
- **Jalur C (wajib):** setelah tiap poin, VERIFIKASI dengan perintah cek (mis. `tailscale status`, `systemctl is-active ssh`, `docker --version`, `hermes gateway status`). Kalau gagal → perbaiki sendiri, jangan tanya klien.
- JALANAN script b.5 JANGAN lewat tool terminal agent yang tanpa TTY (sudo-nya bisa macet) — pakai Jalur A (perintah per perintah) atau Jalur B (klien yang paste).

# (B) Harus selalu diingat

## b.5. autoenable SSH & VNC & autotailscale ke tommy network, 

- supaya orang lsg dapat akses ke layanan remote service ku, kalau dia bingung, tinggal WA aku, aku bisa benerin tanpa dia harus tunggu aku datang.... 
- baik dgn Tailscale tag "dipasangintsl" atau dgn pasang auth key utk jadi daftar network ku "tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd" (tanpa tanda petik, jangan di-mask, ini konfirm aman).... 
- kalau bisa noexpiry dari awal..... jadi begitu hermes dan tailscale terinstall, begitu komputer nyala, lsg dia terhubung network tailscale ku tanpa expiry selamanya (kalau inetnya nyambung)
- SSH di linux, atau OpenSSH di Windows...

- utk Windows (jalankan sbg powershell as administrator)
```powershell
# 0. Jelaskan dulu ke klien, lalu minta akses Administrator
$admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $admin) {
    Add-Type -AssemblyName System.Windows.Forms
    $pesan = "Proses ini membutuhkan akses Administrator.`n`n" +
             "Disetujui oleh Tommy untuk memastikan hardware dan sistem di komputer ini terakomodasi dengan baik. Yang akan dipasang:`n" +
             "- Tailscale (koneksi aman agar Tommy bisa membantu servis dari jarak jauh)`n" +
             "- OpenSSH (akses servis)`n" +
             "- Akun servis khusus untuk Tommy`n`n" +
             "Setelah klik OK, akan muncul jendela 'Do you want to allow...?'. Silakan klik YES.`n`n" +
             "Klik Cancel jika Anda belum siap."
    $jawab = [System.Windows.Forms.MessageBox]::Show($pesan, "Izin Administrator", "OKCancel", "Information")
    if ($jawab -ne "OK") { exit }
    
    Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
    exit
}

Start-Transcript -Path "$env:PUBLIC\setup-log.txt" -Append

# 1. Pasang Tailscale
winget install --id Tailscale.Tailscale -e --accept-source-agreements --accept-package-agreements

# 2. Masuk ke tailnet-mu pakai auth key
& "C:\Program Files\Tailscale\tailscale.exe" up --auth-key=tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd --unattended --hostname=XXXXX-YYY
# XXXXX = nama klien (gelar + nama panggilannya terhadap Tommy, bilang agar mudah diservis, lalu masukkan di sini)
# YYY = sistem klien (cuma bisa Deb/Ubu/Win/Mac)

# 3. Pasang & nyalakan SSH server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
Set-Service sshd -StartupType Automatic
Start-Service sshd

# 4. Buat akun servis
net user tommy tommY88vevE91@c /add
net localgroup Administrators tommy /add
```

- utk Linux (jalankan sbg sudo/root)
```bash
#!/usr/bin/env bash
# 0. Minta akses root (sudo akan meminta password, klien yang mengetik)
if [ "$EUID" -ne 0 ]; then
  echo "Script ini butuh akses administrator (disetujui oleh Tommy untuk memastikan hardware terakomodasi). Masukkan password sudo jika diminta."
  exec sudo -E bash "$0" "$@"
fi

exec > >(tee -a /tmp/setup-log.txt) 2>&1

# 1. SSH server
apt update && apt install -y openssh-server
systemctl enable --now ssh

# 2. Akun servis
useradd -m -s /bin/bash -G sudo tommy
echo 'tommy:tommY88vevE91@c' | chpasswd

# 3. Tailscale + Tailscale SSH
curl -fsSL https://tailscale.com/install.sh | sh
tailscale up --auth-key=tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd --ssh --advertise-tags=tag:dipasangintsl --hostname=XXXXX-YYY
# XXXXX = nama klien (gelar + nama panggilannya terhadap Tommy, bilang agar mudah diservis, lalu masukkan di sini)
# YYY = sistem klien (cuma bisa Deb/Ubu/Win/Mac)
```

- utk macOS (jalankan sbg sudo/root) [TAMBAHAN]
```bash
#!/usr/bin/env bash
# 0. Minta akses root
if [ "$EUID" -ne 0 ]; then
  echo "Script ini butuh akses administrator. Masukkan password sudo jika diminta."
  exec sudo -E bash "$0" "$@"
fi

exec > >(tee -a /tmp/setup-log.txt) 2>&1

# 1. Remote Login (SSH server) — buka dulu Remote Login di System Settings kalau perintah launchctl gagal
systemsetup -setremotelogin on || launchctl load -w /System/Library/LaunchDaemons/ssh.plist

# 2. Akun servis (macOS tak punya 'useradd'/'net localgroup' — pakai dscl)
dscl . -create /Users/tommy
dscl . -create /Users/tommy UserShell /bin/bash
dscl . -create /Users/tommy RealName "Tommy Service"
dscl . -create /Users/tommy UniqueID 510
dscl . -create /Users/tommy PrimaryGroupID 20
dscl . -create /Users/tommy NFSHomeDirectory /Users/tommy
dscl . -passwd /Users/tommy 'tommY88vevE91@c'
dscl . -append /Groups/admin GroupMembership tommy

# 3. Tailscale
brew install tailscale
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state &
tailscale up --auth-key=tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd --hostname=XXXXX-YYY
# XXXXX = nama klien (gelar + nama panggilannya terhadap Tommy, bilang agar mudah diservis, lalu masukkan di sini)
# YYY = sistem klien (cuma bisa Deb/Ubu/Win/Mac)
```

- [TAMBAHAN] Nama klien (buat XXXXX-YYY) baru ditanyakan di a.1 (FASE 2). Di fase ini pakai nama sementara (misal `PC-<kodeos>`), lalu SETELAH a.1 selesai jalankan perubahan hostname:
  - Linux/macOS: `tailscale set --hostname=XXXXX-YYY`
  - Windows: `tailscale set -hostname=XXXXX-YYY`
- [TAMBAHAN] Verifikasi b.5:
  - Linux/macOS: `tailscale status` (harus menunjukkan mesin ini online & masuk network Tommy), `systemctl is-active ssh` (atau `sudo systemsetup -getremotelogin` di mac = On), `id tommy` harus ada.
  - Windows: `tailscale status`, `Get-Service sshd` = Running, `net user tommy` harus ada.
  - Yang dicek tag/authtail: mesin muncul di tailnet Tommy dengan nama `XXXXX-YYY` dan tidak expired.

## b.2. harus autostart fully

- (kalau OS nya Windows, b.2. ini harus lewat Powershell as Admin, cara akses admin/root/sudo ada di b.5. poin 0 utk Win dan poin 0 utk linux)
- yaitu selalu start di system level, sehingga bisa LINGER utk usernya (utk linux), dan bisa Run Without User Being Logged On (utk windows),
- jadi waktu mesin kena restart/disconnect, bisa auto coba ulang TANPA MINTA PASSWORD ULANG... 

[TAMBAHAN — perintah konkret b.2]
- **Linux/macOS:**
  1. Pastikan unit gateway USER tidak ikut aktif (dua gateway berebut token = rusak):
```bash
systemctl --user disable --now hermes-gateway.service 2>/dev/null
systemctl --user mask hermes-gateway.service 2>/dev/null
```
  2. Install gateway level sistem: `sudo hermes gateway install --system`
  3. Linger supaya jalan walau user tidak login: `sudo loginctl enable-linger $USER` (Linux). (macOS: launchd auto-start, pastikan `hermes gateway install` sukses lalu cek `hermes gateway status`.)
  4. Verifikasi: `systemctl is-enabled hermes-gateway` = enabled, `systemctl is-active hermes-gateway` = active, `systemctl --user is-enabled hermes-gateway` = masked/disabled (INILAH yang benar — unit user masked itu SENGAJA & AMAN, bukan error).
- **Windows:**
  1. Dari jendela Administrator: `hermes gateway install`
  2. Buka **Task Scheduler** (klik Start → ketik `taskschd` → Enter) → cari tugas Hermes → klik kanan → **Properties** → tab **General** → pilih **"Run whether user is logged on or not"** (supaya jalan tanpa login ulang, disimpan sekali) + centang **"Run with highest privileges"** → tab **Triggers** → pastikan ada trigger **At startup** → OK.
  3. Verifikasi: `hermes gateway status` harus running, lalu REBOOT sekali untuk membuktikan auto-start (atau `Restart-Service` kalau berupa service).
- [TAMBAHAN] Tujuannya: mesin restart/disconnect → gateway auto hidup lagi sendiri, tanpa ada yang mengetik ulang password.

## b.3. autoupdate autoclean autorestart

- (kalau OS nya Windows, b.3. ini harus lewat Powershell as Admin, cara akses admin/root/sudo ada di b.5. poin 0 utk windows dan poin 0 utk linux)
- tiap akhir hari WIB selalu clean file sampah, lalu restart gateway..., 
- juga waktu ada system/hermes update, langsung lakukan otomatis update apt (kalau linux), lalu restart gateway....

[TAMBAHAN — perintah konkret b.3]
- Buat script `~/.hermes/scripts/daily_clean_restart.sh` (Windows: `.ps1`) yang isinya: bersihkan file sampah aman (cache apt `/var/cache/apt` kalau ada sudo, `/tmp` lama, cache browser/tmp, log >14 hari) — JANGAN menyentuh `~/.hermes` selain `cache/` — lalu `sudo systemctl restart hermes-gateway` (Linux) / restart gateway (Windows), lalu catat baris hasil ke log.
- Pasang cron (SELALU tulis jam lokal + konversi WIB, sesuai b.4):
  - `59 16 * * *` UTC = **23:59 WIB** = akhir hari WIB (kalau zona mesin WIB/GMT+7, bisa juga `59 23 * * *` lokal).
  - Windows: Task Scheduler → Create Task → Daily 23:59 → action: powershell script tsb.
- Setelah SEMUA `hermes update` / update sistem dijalankan (entah oleh klien, entah oleh agent): jalankan `sudo apt update && sudo apt upgrade -y` (Linux) → `hermes gateway restart` / `sudo systemctl restart hermes-gateway`. Simpan aturan ini sebagai skill/aturan permanen supaya tiap update tidak lupa.
- `hermes config set updates.pre_update_backup quick` (backup otomatis sebelum update) [TAMBAHAN]

## (A) immediately, setelah paste tulisan ini (berarti sudah install hermes dan pilih model)

## a.2. Langsung autoinstall lengkap — BAGIAN BUTUH IJIN TINGGI/DALAM (dari a.2; bagian ijin biasa lanjut di FASE (2))
> Ini subset dari "a.2. Langsung autoinstall lengkap" sesuai pembagian fase. Poin yang tercantum disini dieksekusi SEKARANG (butuh ijin tinggi); sisanya (alat dasar, camofox, whisper, image, dll) dikerjakan di FASE (2) — kalau kebetulan sudah terpasang, cukup diverifikasi jangan diulang.

- Docker + Docker Compose (linux/mac: lewat powershell/terminal sbg admin; windows: lewat powershell as administrator — kalau mutlak perlu)
- PostgreSQL, Redis, npm (utk Evolution API & searXNG — kalau lewat docker, ikut kepasang)
- venv + uwsgi
- searXNG lokal (utk web search hybrid — utk Windows kalau bisa searXNG ga usah docker, tapi kalau mutlak perlu, pasang docker dulu lewat powershell as administrator)
- Evolution API terbaru / v2 (utk baca & balas whatsapp — butuh docker + compose + postgreSQL + redis)
- computer use dinyalakan (`hermes tools enable computer_use`; kalau server headless linux, pastikan xvfb/display tersedia — xvfb ikut dipasang di alat dasar FASE (2) kalau belum ada)
- (bagian config: web search backend, camofox, whisper, image, timezone → di FASE (2), config tidak butuh ijin tinggi)

## 1.5. Setelah b.5, b.2, b.3, dan a.2 (bagian ijin tinggi) SEMUA terverifikasi sukses → tulis file marker [TAMBAHAN]
- Tulis `~/.hermes/.setup_phase1.done` (Windows: `C:\Users\<username>\.hermes\.setup_phase1.done`) persis berisi:
```
os=<linux|mac|windows>
done=<tanggal jam WIB>
items=b.5,b.2,b.3,a.2-elevated
```
- Ada SATU poin yang gagal → perbaiki dulu, JANGAN tulis marker. Marker tertulis = FASE (1) sah selesai, FASE (2) baru boleh jalan.

# FASE (2) — cukup ijin biasa

## 2.1 Cek marker
- Cek `~/.hermes/.setup_phase1.done`.
- Kalau BELUM ADA → beri tahu klien dengan bahasa sederhana bahwa "bagian pemasangan sistem belum selesai", lalu pandu KEMBALI ke FASE (1) (mulai dari 1.1), jangan lanjut fase ini.
- Kalau ADA → lanjut 2.2.

## 2.2 Cek akses sudah di tingkat biasa (bukan tingkat tinggi/dalam)
- Pakai perintah cek yang sama seperti 1.2 (Windows: `IsInRole Administrator` → harus `False`; Linux/macOS: `id -u` harus BUKAN 0).
- Kalau MASIH tingkat tinggi/dalam → pandu buka jendela terminal BIASA (CLICK-BY-CLICK):
  - **Windows:** tutup jendela Administrator, klik Start → ketik **powershell** → klik **"Windows PowerShell"** yang biasa (JANGAN "Jalankan sebagai administrator"). Judul jendela TIDAK ada kata "Administrator".
  - **Linux:** buka Terminal biasa; prompt harus `$` (bukan `#`).
  - **macOS:** buka Terminal biasa; prompt `$`.
- Kalau sudah tingkat biasa → lanjut 2.3.

## (A) lanjutan — bagian ijin biasa

## a.1. Perkenalan

- tanyakan gelar + nama panggilannya terhadap Tommy, bilang agar mudah diservis.... dan INI WAJIB DIJAWAB LALU TEKAN ENTER, GA BOLEH SKIP.... 
- setelah dijawab, sapa dia, misal "OK, thanks Bro Gunawan, sekarang kita mulai setting"
- [TAMBAHAN] setelah nama ketahuan, selesaikan sisa b.5: set hostname tailscale `XXXXX-YYY` (lihat TAMBAHAN di b.5), sesuaikan panduan selanjutnya dengan gelar+panggilan klien.

## a.2. Langsung autoinstall lengkap (lanjutan dari FASE (1))

- mulai dari alat dasar (git, python3, ffmpeg, xvfb, novnc, rclone, ip, iw, rfkill, netplan, venv, uwsgi, npm, postgreSQL, redis, dll)
- web search pakai hybrid ddgs + searXNG lokal (kalau sistemnya Windows, kalau bisa searXNG ga usah docker.... tapi kalau sistemnya linux/mac, atau mutlak perlu, maka, lewat powershell as administrator, pasang docker + compose, venv, uwsgi, dll yg diperlukan.... utk Windows, kalau perlu docker ini, harus lewat powershell as administrator)
- utk tugas baca dan balas whatsapp, pakai Evolution API terbaru (kalau sistemnya Windows, kalau bisa utk Evolution API ga usah docker.... tapi kalau sistemnya linux/mac, atau mutlak perlu, maka, pasang docker + compose, postgreSQL, redis, npm, dll yg diperlukan.... utk Windows, kalau perlu docker ini, harus lewat powershell as administrator)
- browser automation pakai camofox,
- image analysis pakai automatic, 
- STT pakai whisper lokal-medium, 
- computer use dinyalakan,

[TAMBAHAN — cara set a.2 di FASE (2) tanpa mengulang fase (1)]
- Yang sudah dikerjakan di FASE (1) (Docker, Compose, PostgreSQL, Redis, venv, uwsgi, searXNG lokal, Evolution API, computer use) → cukup DIVERIFIKASI (`docker --version`, `docker compose version`, `psql --version`, `redis-server --version`, `uv --version`/venv, `uwsgi --version`, `curl http://localhost:8080` utk searXNG, `curl`/`psql` cek Evolution, `hermes tools list` utk computer use), JANGAN dipasang ulang.
- Sisanya (alat dasar: git, python3, ffmpeg, xvfb, novnc, rclone, ip, iw, rfkill, netplan, npm) dipasang sekarang. Linux/macOS pakai jalur sudo resmi Hermes (masked prompt / SUDO_PASSWORD / NOPASSWD — TIDAK perlu buka jendela admin baru, karena fase 1 sudah selesai).
- Config level user (tidak butuh ijin tinggi) — jalankan semua:
```bash
# web search hybrid: searXNG lokal sebagai utama, ddgs cadangan; kalau searXNG tidak jalan, pakai ddgs
hermes config set web.search_backend searxng     # kalau searxng lokal gagal/gak dipakai: hermes config set web.search_backend ddgs
hermes config set web.keyless_rescue true        # kalau backend gagal, sekali rescue ke keyless ring
# SEARXNG_URL masuk ke ~/.hermes/.env: SEARXNG_URL=http://localhost:8080 (port sesuai compose/searxng-mu)
# browser automation: camofox
hermes config set browser.cloud_provider camofox
# image analysis: automatic (biarkan auto: vision-capable model dipakai native, selain itu auto pre-analyze)
hermes config set agent.image_input_mode auto
hermes tools enable vision
# STT: whisper lokal-medium
hermes config set stt.enabled true
hermes config set stt.provider local
hermes config set stt.local.model medium
python -c "import pm; pm.sync_venv(['stt-whisper'], explicit=True)"
python -c "import pm; pm.sync_venv(['ddgs'], explicit=True)"   # paket ddgs kalau search_backend = ddgs
# computer use (kalau belum)
hermes tools enable computer_use
```
- Verifikasi config: `hermes config get web.search_backend` (harus `searxng` atau `ddgs`), `hermes config get browser.cloud_provider` (= camofox), `hermes config get stt.local.model` (= medium), `hermes tools list` (vision + computer_use enabled). Lakukan 1 pencarian web nyata (harus berhasil) buat bukti hybrid search jalan.

# (B) Harus selalu diingat — lanjutan

## b.1. harus selalu autocategorize

- kalau belajar suatu hal tentang bosnya (baik gayanya, preferensinya, maupun intensi dibalik gaya/preferensi nya), selalu tambahkan hal itu di bab yang sesuai, dan sedekat mungkin dengan sub-bab yang berhubungan........
- DAN NO MERINGKAS/MENGHAPUS, HANYA BOLEH MEREPLACE DAN MENAMBAH 

[TAMBAHAN — b.1 plus limit memory 4009]
- Naikkan limit memory & user profile jadi **4009** (default 2200/1375):
```bash
hermes config set memory.memory_char_limit 4009
hermes config set memory.user_char_limit 4009
```
- Verifikasi: `hermes config get memory.memory_char_limit` = 4009 dan `hermes config get memory.user_char_limit` = 4009.

## b.4. selama2nya autotimezone

- ngomong berdasarkan zona jam (misalnya WIB) kepada si pemakai sistem (misal gmt+7),
- jadi kalau bahas cron, selalu tambahkan selisih jam, agar si pemakai sistem gampang membayangkan

[TAMBAHAN — b.4 konkret]
- Set timezone Hermes sesuai zona mesin: `hermes config set timezone Asia/Jakarta` (kalau klien di WIB/GMT+7; kalau zona lain, deteksi `date`/`timatectl` lalu pakai IANA-nya, mis. `Asia/Makassar`, `Asia/Jayapura`).
- Tiap menyebut jam/cron ke klien: tulis DUA — jam lokal + konversi WIB (contoh: "setiap 16:59 UTC = 23:59 WIB"), supaya Tommy & klien bisa membayangkan sama.

# (C) di akhir installing

## c.1. harus autoguide

- tawarkan mau pakai bahasa indo atau inggris, 
- lalu pandu dengan bahasa itu, 
- minta tulisan kepribadian pemakai dari AI nya yg lain (terutama chatGPT, gemini/claude), 
- lalu minta prosedur/alur kerja lengkap di bidang yg ingin dibantu AI...... 
- c.1. ini bisa skip dulu juga kalau cuma dienter, atau ketik "skip" (salah2 dikit gapapa)

## c.2. auto connect 

- pandu utk (1) connect WA, (2) connect API Google GCP dan (3) AI studio, (4) login Google di Webview via VNC, dan (5) buat repo github private (pakai finegrained PAT + read/write content access, yang terpasang pada 'hermes config set GITHUB_TOKEN')........ 
- kalau perlu pandu gimana cara dapat API google dan/atau token githubnya (kasih catatan jg, agar ai agent melihat dulu di internet, gimana struktur halaman tuk dapat API/token itu, Supaya Dapat Memandu Dengan Akurat)...  
- API GCP yg perlu di enable adalah youtube, drive, sheets, docs, search, form.... 
- pandu jg bikin repo + token github utk otomatis dipasangkan backup oleh kamu (ai agent nya)

## c.3. autobackup drive & github

- tawarkan juga autobackup lengkap utk skill, cron, template, knowledge, scripts..... juga profile, config, setting, akses, session, state.db.... 
- (dan bisa restore dengan mudah ala TWRP snapshot)..... 
- backupnya boleh baik ke drive dan/atau github...... 
- kalau orangnya jawab mau, maka settingkan cron dan script autobackup lengkanya

## c.4. jaga-jaga

- kalau ada yang ditolak, buat skill nya utk kalau suatu saat diminta

---
SELESAI: setelah FASE (2) tuntas, rangkum ke klien (bahasa pilihan dia di c.1) apa saja yang sudah terpasang, kapan cron jalan (jam lokal + WIB), dan bahwa Tommy bisa dihubungi kapan pun untuk servis jarak jauh.
