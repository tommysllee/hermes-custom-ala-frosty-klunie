# PROMPT UNTUK AI AGENT — Membangun Repo Installer

> **Terakhir diperbarui: Sabtu, 03 Okt 2026 · 12:25 WIB**
>
> Cara pakai: salin SELURUH isi file ini ke AI agent Anda (Claude Code,
> Codex, Cursor, atau agent lain). Lalu suruh: "kerjakan sesuai prompt ini".

---

## PROMPT — mulai salin dari sini

```
TUGAS
Buatkan saya satu repository GitHub berisi installer AI agent yang bisa
dijalankan dengan SATU perintah di Ubuntu/Debian (termasuk WSL di Windows).
Repo ini akan saya bagikan ke klien lewat link.

KONDISI AWAL
Saya sudah punya satu file installer yang SUDAH TERUJI jalan:
  - install.sh  (sudah saya uji sampai tahap pemeriksaan sistem)

Yang saya minta: rapikan menjadi repo yang layak dibagikan, lengkapi
yang kurang, dan siapkan strukturnya.

--------------------------------------------------------------
BAGIAN 1 — STRUKTUR REPO YANG DIMINTA
--------------------------------------------------------------

Buat struktur seperti ini:

    <repo>/
    ├── install.sh              # installer utama (sudah ada, sempurnakan)
    ├── README.md               # panduan singkat untuk klien
    ├── LICENSE                 # MIT
    ├── docs/
    │   ├── LINUX.md            # panduan Ubuntu/Debian + WSL
    │   ├── WINDOWS.md          # panduan Windows (WSL2 + Task Scheduler)
    │   ├── MAC.md              # panduan MacBook (LaunchDaemon + FileVault)
    │   ├── TAILSCALE.md        # panduan tag & auth key (sudah ada)
    │   ├── GITHUB.md           # panduan public vs private (sudah ada)
    │   ├── PESANPASANG.md      # apa yang harus dilakukan klien setelahnya
    │   └── PEMECAHAN.md        # masalah umum & solusinya
    ├── scripts/
    │   ├── cek-sistem.sh       # bagian TAHAP 1 (dipisah dari install.sh)
    │   ├── pasang-dasar.sh     # bagian TAHAP 2
    │   ├── pasang-aplikasi.sh  # bagian TAHAP 3
    │   ├── pesan-akhir.sh      # bagian TAHAP 4
    │   └── pencatat.sh         # fungsi log bersama
    └── templates/
        ├── config.yaml.template
        ├── searxng-compose.yml
        ├── evolution-compose.yml
        └── systemd-hermes.service

Alasan dipisah: install.sh jadi mudah dibaca, dan tiap bagian bisa
diperbaiki sendiri.

--------------------------------------------------------------
BAGIAN 2 — YANG HARUS DIPASANG INSTALLER
--------------------------------------------------------------

Urutan WAJIB seperti ini (penting: yang butuh campur tangan manusia
ditaruh PALING AKHIR):

TAHAP 1 — Cek sistem (tanpa mengubah apa pun)
  1. Deteksi OS & arsitektur. Tolak kalau bukan Ubuntu/Debian
     (kecuali WSL).
  2. Deteksi WSL.
  3. Cek akses sudo/root. Kalau perlu sandi, minta SEKALI.
  4. Cek ruang disk (minimal 15 GB) dan memori.
  5. Cek koneksi internet.
  6. Laporkan zona waktu.
  7. Cek port yang mungkin bentrok (8080, 6080, 5909, 8081, 5432).

TAHAP 2 — Pasang dasar (otomatis penuh)
  8. Paket apt: curl, wget, git, ca-certificates, gnupg, python3,
     python3-pip, python3-venv, rsync, unzip, jq, sqlite3,
     build-essential, pkg-config, ffmpeg,
     xvfb, x11vnc, websockify, imagemagick, xdotool, novnc, ufw
  9. Docker + docker compose plugin.
 10. Hermes (installer resmi):
       curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
 11. Venv Python Hermes.
 12. Camoufox (browser anti-detect, ~1,3 GB):
       python3 -m camoufox fetch
 13. Tailscale: curl -fsSL https://tailscale.com/install.sh | sh

TAHAP 3 — Pasang aplikasi & pengaturan (otomatis penuh)
 14. Tulis ~/.hermes/config.yaml dengan pengaturan ini:
       stt.provider  : local          (tanpa API key)
       stt.model     : medium         (~1,5 GB, diunduh otomatis)
       stt.language  : id
       web.backend   : ddgs           (tanpa API key)
       web.searxng.url : http://localhost:8080
       browser.backend : camoufox
       terminal.backend: local
     ATURAN: jangan timpa config yang sudah ada — backup dulu.
 15. SearXNG lokal lewat Docker (mesin pencari sendiri, tanpa API key),
     port 8080, restart: unless-stopped.
 16. STT lokal: pasang faster-whisper. Kalau RAM < 4 GB, LEWATI dan
     beri tahu. Model 'medium' diunduh otomatis saat pertama dipakai.
 17. Evolution API (WhatsApp) lewat Docker: postgres + redis + evolution,
     port 8081, restart: always.
 18. Remote web view: Xvfb + x11vnc + noVNC lewat websockify,
     bind HANYA ke IP Tailscale, password acak otomatis.
     Sediakan skrip: remote-view.sh start|stop|status|password
     Service SENGAJA tidak di-enable (nyala manual saat perlu).
 19. Autostart tingkat SISTEM (bukan tingkat pengguna):
       /etc/systemd/system/hermes-gateway.service
       enabled, Restart=always

TAHAP 4 — Bagian manusia (PALING AKHIR, berurutan)
 20. Nous Portal (login OAuth — gratis di awal, tanpa API key):
       hermes setup --portal
 21. Tampilkan alamat noVNC: http://<IP-Tailscale>:6080/vnc.html
     (DITARUH DI SINI, sebelum QR WhatsApp — sesuai permintaan saya)
 22. Tailscale up (opsional, untuk dibantu teknisi):
       sudo tailscale up --ssh
 23. QR WhatsApp via Evolution manager di port 8081
 24. Ingatkan MATIKAN remote web view setelah selesai:
       remote-view.sh stop

--------------------------------------------------------------
BAGIAN 3 — ATURAN YANG TIDAK BOLEH DILANGGAR
--------------------------------------------------------------

A. TAHAP 4 HARUS PALING AKHIR. Yang butuh campur tangan manusia
   (login, QR, API key) tidak boleh menghambat pemasangan otomatis.

B. INSTALLER TIDAK BOLEH GAGAL TOTAL kalau satu komponen gagal.
   Contoh: Camoufox gagal unduh -> catat, lanjut. SearXNG gagal ->
   catat, lanjut. Selalu ada ringkasan di akhir: mana yang berhasil,
   mana yang perlu dicoba lagi.

C. JANGAN PERNAH menaruh kredensial di dalam repo:
   - tidak ada API key, token, atau sandi
   - file .env hanya berisi PLACEHOLDER
   - awali .gitignore dengan: .env, *.key, *.token

D. Auth key Tailscale (kalau ada) diambil dari VARIABEL LINGKUNGAN,
   bukan ditulis di file:
     HERMES_TAILSCALE_AUTHKEY="tskey-..." ./install.sh
   Kalau variabel kosong -> JANGAN paksa, cukup tampilkan instruksi
   `sudo tailscale up --ssh`.

E. Idempoten: aman dijalankan ULANG. Kalau sudah terpasang, lewati
   dengan pesan, jangan pasang dua kali.
   (Khusus: gateway Hermes — jangan sampai ada dua unit yang jalan
   bersamaan, itu merusak database. Satu unit tingkat sistem saja.)

F. Bahasa keluaran: Indonesia yang jelas. Hindari istilah teknis
   tanpa penjelasan. Klien mungkin tidak paham istilah.

G. Setiap langkah cetak indikator visual yang jelas:
     ✓ berhasil
     ✗ gagal
     → sedang dikerjakan
   Supaya klien tahu prosesnya masih jalan.

H. Log ke file: /tmp/hermes-install-<cap waktu>.log
   Pesan kesalahan teknis ke log, pesan ramah ke layar.

I. JANGAN pakai perintah yang menghapus file pengguna tanpa tanya.
   JANGAN `rm -rf` di luar folder yang installer buat sendiri.

J. Installer harus JALAN DI WSL. Deteksi WSL dan sesuaikan:
   - systemd mungkin tidak aktif -> lewati autostart, beri tahu caranya
   - Tailscale di WSL perlu langkah tambahan -> cantumkan di docs

--------------------------------------------------------------
BAGIAN 4 — DUKUNGAN WINDOWS (setelah Linux matang)
--------------------------------------------------------------

Windows TIDAK punya systemd. Cara yang benar:
  1. Pakai WSL2 + Ubuntu (persis seperti Linux)
  2. Autostart lewat Task Scheduler saat boot:
       schtasks /create /tn "Hermes Agent" /tr "wsl -d Ubuntu -u <user> \
         -e bash -lc 'hermes gateway'" /sc onstart /ru SYSTEM /rl HIGHEST
  3. Buat install.ps1 yang:
       - cek WSL2 ada; kalau tidak, pasang: wsl --install -d Ubuntu
       - jalankan install.sh di dalam WSL
       - daftarkan Task Scheduler
  4. noVNC di WSL: bind ke IP Tailscale Windows, bukan localhost WSL.
     Cantumkan langkah jembatan portnya di docs/WINDOWS.md

--------------------------------------------------------------
BAGIAN 5 — DUKUNGAN MAC (terakhir)
--------------------------------------------------------------

  PENTING — masalah yang harus ditangani di docs/MAC.md:
    FileVault membuat MacBook BERHENTI di layar login setelah reboot.
    LaunchDaemon TIDAK jalan sebelum ada yang login. Jadi agent mati.

  Yang harus ditulis di docs/MAC.md:
    1. Cara mengaktifkan auto-login:
         System Settings -> Users & Groups -> Automatically log in as
       Jelaskan: FileVault tetap aktif (sandi boot tetap diminta);
       auto-login hanya berlaku SETELAH disk terbuka.
    2. Cegah tidur saat colok listrik:
         sudo pmset -c sleep 0 disablesleep 1
    3. Pakai LaunchAgent (bukan LaunchDaemon) supaya jalan setelah login:
         ~/Library/LaunchAgents/com.hermes.gateway.plist
    4. JUJUR: MacBook bukan mesin yang cocok untuk agent 24/7.
       Kalau butuh yang selalu hidup, sarankan mini PC Ubuntu.

--------------------------------------------------------------
BAGIAN 6 — YANG HARUS ADA DI README.md
--------------------------------------------------------------

README harus singkat dan langsung:
  1. Apa ini (2 kalimat)
  2. Cara pakai (3 baris kode)
  3. Apa yang dipasang (daftar ringkas)
  4. APA YANG PERLU DILAKUKAN SETELAHNYA (4 langkah, urut)
  5. Pemecahan masalah singkat
  6. Tautan ke docs/ untuk detail

--------------------------------------------------------------
BAGIAN 7 — UJI SEBELUM MENYATAKAN SELESAI
--------------------------------------------------------------

WAJIB diuji, dan tunjukkan hasilnya:
  1. bash -n pada SEMUA file .sh (cek sintaks)
  2. ./install.sh --tes  -> harus jalan penuh tanpa mengubah apa pun
  3. Jalankan di Ubuntu bersih (VM/container) kalau bisa
  4. Pastikan installer bisa dijalankan DUA KALI tanpa error (idempoten)
  5. Pastikan TIDAK ADA kredensial di seluruh repo:
       grep -rE '(sk-[A-Za-z0-9]{24,}|ghp_|tskey-auth|AIza)' .
     -> hasilnya harus kosong

Jangan katakan "selesai" sebelum tujuh hal di atas terbukti.

--------------------------------------------------------------
YANG SUDAH SAYA PUNYA (pakai ini, jangan bikin dari nol)
--------------------------------------------------------------

Saya lampirkan:
  1. install.sh          — versi awal yang sudah jalan (uji: --tes lolos)
  2. docs/TAILSCALE.md   — panduan tag & auth key
  3. docs/GITHUB.md      — panduan public vs private repo

Pakai ketiganya sebagai dasar. Semurnikan, jangan ganti arah.

--------------------------------------------------------------
MULAI DARI MANA
--------------------------------------------------------------

1. Baca install.sh saya, pahami alurnya.
2. Pecah jadi scripts/ sesuai BAGIAN 1 (jangan ubah perilakunya).
3. Lengkapi yang kurang sesuai BAGIAN 2 dan 3.
4. Tulis README.md dan docs/ yang belum ada.
5. Jalankan uji BAGIAN 7, laporkan hasilnya apa adanya.
6. Baru sesudahnya kerjakan Windows (BAGIAN 4), lalu Mac (BAGIAN 5).

Kerjakan Linux dulu sampai matang dan terbukti.
```

## — selesai salin

---

## Catatan untuk pemilik repo (jangan ikut disalin)

**Kenapa prompt ini disusun begini:**

```
1. Struktur dipaksa jelas  -> agent tidak mengarang tata letak sendiri
2. Urutan tahap dipatok    -> permintaanmu (manusia di akhir) tidak dilanggar
3. Aturan larangan ditulis -> supaya tidak ada kredensial bocor ke repo
4. Uji wajib disebutkan    -> agent tidak bisa bilang "selesai" tanpa bukti
5. "Pakai yang sudah ada"  -> supaya tidak mengulang dari nol
```

**Yang mungkin perlu kamu ubah sebelum dikirim:**
```
- <ISI-KONTAK-ANDA> di install.sh bagian akhir
- Nama repo (di docs/GITHUB.md)
- Kalau kamu mau MIT diganti lisensi lain
```
