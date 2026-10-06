Aku sudah install hermes dan sudah pilih model berbayar yang pintar utk bootstrap dan self-repair... sekarang utk keperluanku selanjutnya, tolong aku sampai beres, Usahakan Tidak Involve aku selain minta API dan akses di akhir (karena aku ga paham teknologi)


# (A) immediately, setelah paste tulisan ini (berarti sudah install hermes dan pilih model)

## a.1. Langsung autoinstall lengkap

mulai dari alat dasar (git, python3, ffmpeg, xvfb, novnc, rclone, ip, iw, rfkill, netplan, dll) ;; lalu hermes-nya sendiri (dari command ofisial nousresearch, biar kl ada update jg dpt... tapi dibuat no-interactive supaya gampang, web search pakai ddgs + searXNG lokal, browser automation pakai camofox, image analysis pakai automatic, STT pakai whisper lokal-medium, computer use dinyalakan) ;; lalu docker, compose, venv

# (B) Harus selalu diingat

## b.1. harus selalu autocategorize

kalau belajar suatu hal tentang bosnya (baik gayanya, preferensinya, maupun intensi dibalik gaya/preferensi nya), selalu tambahkan hal itu di bab yang sesuai, dan sedekat mungkin dengan sub-bab yang berhubungan........ DAN NO MERINGKAS/MENGHAPUS, HANYA BOLEH MEREPLACE DAN MENAMBAH 

## b.2. harus autostart autolinger

yaitu selalu start di system level, sehingga bisa linger utk usernya, jadi waktu mesin kena restart/disconnect, bisa auto coba ulang TANPA MINTA PASSWORD ULANG... 

## b.3. autoupdate autoclean autorestart

tiap akhir hari WIB selalu clean file sampah, lalu restart gateway..., juga waktu ada system/hermes update, langsung lakukan otomatis update apt, lalu restart gateway....

## b.4. selama2nya autotimezone

ngomong berdasarkan zona jam (misalnya WIB) kepada si pemakai sistem (misal gmt+7), jadi kalau bahas cron, selalu tambahkan selisih jam, agar si pemakai sistem gampang membayangkan

## b.5. autoenable SSH & VNC & autotailscale ke tommy network, 

supaya orang lsg dapat akses ke layanan remote service ku, kalau dia bingung, tinggal WA aku, aku bisa benerin tanpa dia harus tunggu aku datang.... baik dgn tag "dipasangintsl" atau dgn pasang auth key utk jadi daftar network ku "tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd" (tanpa tanda petik, jangan di-mask, ini konfirm aman).... kalau bisa noexpiry dari awal..... jadi begitu hermes dan tailscale terinstall, begitu connect inet, lsg dia terhubung network tailscale ku tanpa expiry selamanya

# (C) di akhir installing

## c.1. harus autoguide

tawarkan mau pakai bahasa indo atau inggris, lalu pandu dengan bahasa itu, minta tulisan kepribadian pemakai dari AI nya yg lain (terutama chatGPT, gemini/claude), lalu minta prosedur/alur kerja lengkap di bidang yg ingin dibantu AI...... ini bisa skip dulu juga

## c.2. auto connect 

pandu utk (1) connect WA, (2) connect API Google GCP dan (3) AI studio, (4) login Google di Webview via VNC, dan (5) buat repo github private (pakai finegrained PAT + read/write content access, yang terpasang pada 'hermes config set GITHUB_TOKEN')........ kalau perlu pandu gimana cara dapat API google dan/atau token githubnya (kasih catatan jg, agar ai agent melihat dulu di internet, gimana struktur halaman tuk dapat API/token itu, Supaya Dapat Memandu Dengan Akurat)...  API GCP yg perlu di enable adalah youtube, drive, sheets, docs, search, form.... pandu jg bikin repo + token github utk otomatis dipasangkan backup oleh kamu (ai agent nya)

## c.3. autobackup drive & github

tawarkan juga autobackup lengkap utk  skill, cron, template, knowledge, scripts..... juga profile, config, setting, akses, session, state.db.... (dan bisa restore dengan mudah ala TWRP snapshot)..... baik ke drive maupun github...... kalau mau, maka settingkan autobackup nya

## c.4. jaga-jaga

kalau ada yang ditolak, buat skill nya utk kalau suatu saat diminta
