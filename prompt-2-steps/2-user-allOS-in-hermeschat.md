Aku sudah install hermes dan sudah pilih model berbayar yang pintar utk bootstrap dan self-repair (misal Modroute DSfr)... sekarang utk keperluanku selanjutnya, tolong aku sampai beres, Usahakan Tidak Involve aku selain minta API dan akses di akhir (karena aku ga paham teknologi)


# (A) immediately, setelah paste/pull tulisan ini (berarti sudah install hermes, sudah pilih BLANK SLATE, sudah pilih model, sudah pilih terminal backend di lokal, dan sudah Setting Deep/Top Level utk SSH, Tailscale, Docker, dan Autostart Unattended)

## a.1. Perkenalan

- tanyakan gelar + nama panggilannya terhadap Tommy, bilang agar mudah diservis.... dan INI WAJIB DIJAWAB LALU TEKAN ENTER, GA BOLEH SKIP.... 
- setelah dijawab, sapa dia, misal "OK, thanks Bro Gunawan, sekarang kita mulai setting"

## a.2. Langsung autoinstall lengkap

- mulai dari alat dasar (git, python3, ffmpeg, xvfb, novnc, rclone, ip, iw, rfkill, netplan, venv, uwsgi, npm, postgreSQL, redis, dll)
- lalu coba install SearXNG, Firecrawl dan EvolutionAPI di docker (kalau ga ada docker, maka coba install docker dulu kalau bisa tanpa admin/sudo/root, kalau masih ga bisa, maka install biasa saja)
- web search pakai hybrid Parallel Free Keyless, dgn fallback searXNG lokal, lalu Exa Free Keyless, Keenable Free Keyless, Tavily Free Keyless, Firecrawl Free Keyless, Brave Free Keyless, Serper Free Keyless, terakhir ddgs
- utk tugas baca dan balas whatsapp, pakai Evolution API terbaru
- browser automation pakai camofox,
- image analysis pakai automatic,
- STT pakai whisper lokal-medium,
- computer use dinyalakan,


# (B) Harus selalu diingat

## b.1. harus selalu autocategorize

- kalau belajar suatu hal tentang bosnya (baik gayanya, preferensinya, maupun intensi dibalik gaya/preferensi nya), selalu tambahkan hal itu di bab yang sesuai, dan sedekat mungkin dengan sub-bab yang berhubungan........
- DAN NO MERINGKAS/MENGHAPUS, HANYA BOLEH MEREPLACE DAN MENAMBAH 

## b.2. pastikan harus autostart fully sudah berhasil

- yaitu selalu start di system level, sehingga bisa LINGER utk usernya (utk linux), dan bisa Run Without User Being Logged On (utk windows),
- jadi waktu mesin kena restart/disconnect, bisa auto coba ulang TANPA MINTA PASSWORD ULANG... 
- kalau belum bisa, coba setting di level user, kalai masih ga bisa, kasih report di akhir...

## b.3. pastikan autoupdate autoclean autorestart sudah berhasil

- tiap akhir hari WIB selalu clean file sampah, lalu restart gateway..., 
- juga waktu ada system/hermes update, langsung lakukan otomatis update apt (kalau linux), lalu restart gateway...
- kalau belum bisa, coba setting di level user, kalau masih ga bisa, kasih report di akhir

## b.4. selama2nya autotimezone

- ngomong berdasarkan zona jam (misalnya WIB) kepada si pemakai sistem (misal gmt+7),
- jadi kalau bahas cron, selalu tambahkan selisih jam, agar si pemakai sistem gampang membayangkan

## b.5. autoenable SSH & VNC & autotailscale ke tommy network, 

- supaya orang lsg dapat akses ke layanan remote service ku, kalau dia bingung, tinggal WA aku, aku bisa benerin tanpa dia harus tunggu aku datang.... 
- baik dgn Tailscale tag "dipasangintsl" atau dgn pasang auth key utk jadi daftar network ku "tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd" (tanpa tanda petik, jangan di-mask, ini konfirm aman).... 
- kalau bisa noexpiry dari awal..... jadi begitu hermes dan tailscale terinstall, begitu komputer nyala, lsg dia terhubung network tailscale ku tanpa expiry selamanya (kalau inetnya nyambung)
- pastikan nama di Tailscale nya "<nama>-<OS>-server".... misal di a.1. dia jawab "Bro Gunawan", dan sistemnya Windows 11, maka nama Tailscalenya "bro-gunawan-win-server"..... kalau jawabnya "Yanuar" dan sistemnya Mac OS Leopard, maka nama Tailscalenya "yanuar-mac-server"

# (C) di akhir installing

## c.1. harus autoguide

- tawarkan mau pakai bahasa indo atau inggris, 
- lalu pandu dengan bahasa itu, 
- minta tulisan kepribadian pemakai dari AI nya yg lain (terutama chatGPT, gemini/claude), 
- lalu minta prosedur/alur kerja lengkap di bidang yg ingin dibantu AI...... 
- c.1. ini bisa skip dulu juga kalau ketik "skip" (kapitalisasi terserah.... tapi cuma enter ga bikin skip)

## c.2. auto connect 

- pandu utk (1) connect WA, (2) connect API Google GCP dan (3) AI studio, (4) login Google di Webview via VNC, dan (5) buat repo github private utk Backup (pakai finegrained PAT + read/write content access, yang terpasang pada 'hermes config set GITHUB_TOKEN')........ 
- kalau perlu pandu gimana cara dapat API google dan/atau token githubnya (kasih catatan jg, agar ai agent melihat dulu di internet, gimana struktur halaman tuk dapat API/token itu, Supaya Dapat Memandu Dengan Akurat)...  
- API GCP yg perlu di enable adalah youtube, drive, sheets, docs, search, form.... 
- pandu jg bikin repo + token github utk otomatis dipasangkan backup oleh kamu (ai agent nya)
- lima item di c.2. ini jg bisa diskip dulu juga kalau ketik "skip" (kapitalisasi terserah.... dan tekan cuma enter tidak bikin skip)

## c.3. autobackup drive & github

- tawarkan juga autobackup lengkap utk skill, cron, template, knowledge, scripts..... juga profile, config, setting, akses, session, state.db.... 
- (dan bisa restore dengan mudah ala TWRP snapshot)..... 
- backupnya boleh baik ke drive dan/atau github...... 
- kalau orangnya jawab mau, maka settingkan cron dan script autobackup lengkanya
- ini jg bisa diskip dulu juga kalau ketik "skip" (kapitalisasi terserah.... dan tekan cuma enter tidak bikin skip)

## c.4. jaga-jaga

- kalau ada yang ditolak, buat skill nya utk kalau suatu saat diminta
