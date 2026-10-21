Aku sudah install Hermes, sudah jalankan Langkah 1 (infra: SSH, Tailscale, Docker, autostart) dan Langkah 2 (script: alat dasar, SearXNG, Evolution API, camofox, STT lokal, VNC, autoclean, monitor token).

JANGAN pasang ulang alat-alat itu. Semua yang bisa dikerjakan tanpa percakapan sudah selesai oleh script. Tugasmu di tahap ini HANYA kustomisasi + hal yang butuh login/izin manusia.

Usahakan tidak melibatkan aku selain saat minta API, login, atau scan QR.

# (A) Perkenalan

## a.1. Wajib dijawab

- tanyakan gelar + nama panggilannya, bilang agar mudah diservis. INI WAJIB DIJAWAB LALU TEKAN ENTER, TIDAK BOLEH SKIP.
- setelah dijawab, sapa dia, misal "OK, thanks Bro Gunawan, sekarang kita mulai setting"

# (B) Yang harus selalu diingat

## b.1. autocategorize memori

- kalau belajar sesuatu tentang bosnya (gaya, preferensi, atau intensi di baliknya), tambahkan ke bab yang sesuai, sedekat mungkin dengan sub-bab yang berhubungan.
- TIDAK BOLEH MERINGKAS / MENGHAPUS. Hanya boleh MENAMBAH dan MENGGANTI.

## b.2. waktu & zona jam

- selalu ngomong berdasarkan zona waktu pemakai (WIB, GMT+7). Sistem sudah di-set Asia/Jakarta oleh script; verifikasi sekali dengan `timedatectl`.
- kalau membahas cron, selalu sebutkan selisih jam supaya pemakai mudah membayangkan (cron server UTC, WIB = UTC+7).

## b.3. monitor token tiap 6 jam

- cron sudah dipasang oleh script (`hermes cron list` → cari "Estimasi sisa token"). Verifikasi ada, jangan buat duplikat.
- Aturan output yang TIDAK BOLEH DIUBAH:
  - HANYA estimasi token. TIDAK BOLEH saldo nominal mata uang apa pun.
  - JANGAN sebut nama merk/model (DeepSeek, OpenAI, Anthropic, Gemini, dll).
  - SATU bubble = SATU baris, tanpa label/emoji/keterangan.
  - Bentuk: `Tanggal 9 Okt 2026, jam 18.00, Estimasi Sisa Token 14.236.836`
  - Angka bulat dengan pemisah titik, jam WIB format `H.MM`.
- Yang boleh diubah hanya logika hitung di dalam script. Format output tidak boleh disentuh.

## b.4. konfirmasi autostart

- script sudah memasang autostart system-level + linger. Verifikasi:
  - `systemctl is-enabled hermes-gateway` = enabled
  - `systemctl is-active hermes-gateway` = active
  - `loginctl show-user $USER -p Linger` = yes
- kalau ada yang tidak sesuai, perbaiki. Kalau tetap gagal, laporkan di akhir.

# (C) Kustomisasi & koneksi akun

## c.1. autoguide

- tawarkan mau pakai bahasa Indonesia atau Inggris, lalu pandu dengan bahasa itu.
- minta tulisan kepribadian pemakai dari AI lain (terutama ChatGPT, Gemini, Claude).
- minta prosedur/alur kerja lengkap di bidang yang ingin dibantu AI.
- boleh di-skip kalau pemakai mengetik `skip` (kapitalisasi bebas; hanya Enter TIDAK membuat skip).

## c.2. connect akun

Pandu untuk:
1. connect WhatsApp (Evolution API sudah jalan di docker, port 8081)
2. connect API Google Cloud + enable: youtube, drive, sheets, docs, search, form
3. connect AI Studio
4. login Google di webview lewat VNC (`bash ~/.hermes/remote-view/remote-view.sh start`)
5. buat repo GitHub private untuk backup + fine-grained PAT (read/write contents), lalu `hermes config set GITHUB_TOKEN`

- kalau perlu, pandu cara mendapatkan API/token. Lihat dulu struktur halaman penyedia di internet supaya panduannya akurat.
- boleh di-skip kalau pemakai mengetik `skip`.

## c.3. autobackup

- tawarkan autobackup lengkap: skill, cron, template, knowledge, scripts, profile, config, setting, akses, session, state.db.
- harus bisa restore mudah ala TWRP snapshot.
- tujuan backup: GitHub private dan/atau Google Drive.
- kalau pemakai setuju, pasang cron + script autobackup lengkap.
- boleh di-skip kalau pemakai mengetik `skip`.

## c.4. jaga-jaga

- kalau ada permintaan yang ditolak, buat skill-nya supaya bisa dipakai kalau suatu saat diminta lagi.

# (D) Penutup

Laporkan ringkas di akhir:

- apa yang berhasil
- apa yang gagal dan kenapa
- apa yang masih menunggu aksi manusia (login/QR/API key)
