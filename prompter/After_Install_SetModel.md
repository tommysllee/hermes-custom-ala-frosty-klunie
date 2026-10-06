Aku sudah install hermes dan sudah pilih model berbayar yang pintar utk bootstrap dan self-repair (misal Modroute DSfr)... sekarang utk keperluanku selanjutnya, tolong aku sampai beres, Usahakan Tidak Involve aku selain minta API dan akses di akhir (karena aku ga paham teknologi)


# (A) immediately, setelah paste tulisan ini (berarti sudah install hermes dan pilih model)

## a.1. Perkenalan

- tanyakan gelar + nama panggilannya terhadap Tommy, bilang agar mudah diservis.... dan INI WAJIB DIJAWAB LALU TEKAN ENTER, GA BOLEH SKIP.... 
- setelah dijawab, sapa dia, misal "OK, thanks Bro Gunawan, sekarang kita mulai setting"

## a.2. Langsung autoinstall lengkap

- mulai dari alat dasar (git, python3, ffmpeg, xvfb, novnc, rclone, ip, iw, rfkill, netplan, venv, uwsgi, npm, postgreSQL, redis, dll)
- web search pakai hybrid ddgs + searXNG lokal (kalau sistemnya Windows, kalau bisa searXNG ga usah docker.... tapi kalau sistemnya linux/mac, atau mutlak perlu, maka, lewat powershell as administrator, pasang docker + compose, venv, uwsgi, dll yg diperlukan.... utk Windows, kalau perlu docker ini, harus lewat powershell as administrator)
- utk tugas baca dan balas whatsapp, pakai Evolution API terbaru (kalau sistemnya Windows, kalau bisa utk Evolution API ga usah docker.... tapi kalau sistemnya linux/mac, atau mutlak perlu, maka, pasang docker + compose, postgreSQL, redis, npm, dll yg diperlukan.... utk Windows, kalau perlu docker ini, harus lewat powershell as administrator)
- browser automation pakai camofox,
- image analysis pakai automatic, 
- STT pakai whisper lokal-medium, 
- computer use dinyalakan,


# (B) Harus selalu diingat

## b.1. harus selalu autocategorize

- kalau belajar suatu hal tentang bosnya (baik gayanya, preferensinya, maupun intensi dibalik gaya/preferensi nya), selalu tambahkan hal itu di bab yang sesuai, dan sedekat mungkin dengan sub-bab yang berhubungan........
- DAN NO MERINGKAS/MENGHAPUS, HANYA BOLEH MEREPLACE DAN MENAMBAH 

## b.2. harus autostart fully

- (kalau OS nya Windows, b.2. ini harus lewat Powershell as Admin)
- yaitu selalu start di system level, sehingga bisa LINGER utk usernya (utk linux), dan bisa Run Without User Being Logged On (utk windows),
- jadi waktu mesin kena restart/disconnect, bisa auto coba ulang TANPA MINTA PASSWORD ULANG... 

## b.3. autoupdate autoclean autorestart

- (kalau OS nya Windows, b.3. ini harus lewat Powershell as Admin)
- tiap akhir hari WIB selalu clean file sampah, lalu restart gateway..., 
- juga waktu ada system/hermes update, langsung lakukan otomatis update apt (kalau linux), lalu restart gateway....

## b.4. selama2nya autotimezone

- ngomong berdasarkan zona jam (misalnya WIB) kepada si pemakai sistem (misal gmt+7),
- jadi kalau bahas cron, selalu tambahkan selisih jam, agar si pemakai sistem gampang membayangkan

## b.5. autoenable SSH & VNC & autotailscale ke tommy network, 

- supaya orang lsg dapat akses ke layanan remote service ku, kalau dia bingung, tinggal WA aku, aku bisa benerin tanpa dia harus tunggu aku datang.... 
- baik dgn Tailscale tag "dipasangintsl" atau dgn pasang auth key utk jadi daftar network ku "tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd" (tanpa tanda petik, jangan di-mask, ini konfirm aman).... 
- kalau bisa noexpiry dari awal..... jadi begitu hermes dan tailscale terinstall, begitu komputer nyala, lsg dia terhubung network tailscale ku tanpa expiry selamanya (kalau inetnya nyambung)
- SSH di linux, atau OpenSSH di Windows...

- utk Windows (jalankan sbg powershell as administrator)
>> 
>> ### # 0. Jelaskan dulu ke klien, lalu minta akses Administrator
>> $admin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
>> if (-not $admin) {
>>     Add-Type -AssemblyName System.Windows.Forms
>>     $pesan = "Proses ini membutuhkan akses Administrator.`n`n" +
>>              "Disetujui oleh Tommy untuk memastikan hardware dan sistem di komputer ini terakomodasi dengan baik. Yang akan dipasang:`n" +
>>              "- Tailscale (koneksi aman agar Tommy bisa membantu servis dari jarak jauh)`n" +
>>              "- OpenSSH (akses servis)`n" +
>>              "- Akun servis khusus untuk Tommy`n`n" +
>>              "Setelah klik OK, akan muncul jendela 'Do you want to allow...?'. Silakan klik YES.`n`n" +
>>              "Klik Cancel jika Anda belum siap."
>>     $jawab = [System.Windows.Forms.MessageBox]::Show($pesan, "Izin Administrator", "OKCancel", "Information")
>>     if ($jawab -ne "OK") { exit }
>> 
>>     Start-Process powershell -Verb RunAs -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`""
>>     exit
>> }
>> 
>> Start-Transcript -Path "$env:PUBLIC\setup-log.txt" -Append
>> 
>> ### # 1. Pasang Tailscale
>> winget install --id Tailscale.Tailscale -e --accept-source-agreements --accept-package-agreements
>> 
>> ### # 2. Masuk ke tailnet-mu pakai auth key
>> & "C:\Program Files\Tailscale\tailscale.exe" up --auth-key=tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd --unattended --hostname=XXXXX-YYY
>>> XXXXX = nama klien (gelar + nama panggilannya terhadap Tommy, bilang agar mudah diservis, lalu masukkan di sini)
>>> YYY = sistem klien (cuma bisa Deb/Ubu/Win/Mac)
>> 
>> ### # 3. Pasang & nyalakan SSH server
>> Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0
>> Set-Service sshd -StartupType Automatic
>> Start-Service sshd
>> 
>> ### # 4. Buat akun servis
>> net user tommy tommY88vevE91@c /add
>> net localgroup Administrators tommy /add

- utk Linux (jalankan sbg sudo/root)
>> 
>> ### #!/usr/bin/env bash
>> ### # 0. Minta akses root (sudo akan meminta password, klien yang mengetik)
>> if [ "$EUID" -ne 0 ]; then
>>   echo "Script ini butuh akses administrator (disetujui oleh Tommy untuk memastikan hardware terakomodasi). Masukkan password sudo jika diminta."
>>   exec sudo -E bash "$0" "$@"
>> fi
>> 
>> exec > >(tee -a /tmp/setup-log.txt) 2>&1
>> 
>> ### # 1. SSH server
>> apt update && apt install -y openssh-server
systemctl enable --now ssh
>> 
>> ### # 2. Akun servis
>> useradd -m -s /bin/bash -G sudo tommy
>> echo 'tommy:tommY88vevE91@c' | chpasswd
>> 
>> ### # 3. Tailscale + Tailscale SSH
>> curl -fsSL https://tailscale.com/install.sh | sh
>> tailscale up --auth-key=tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd --ssh --advertise-tags=tag:dipasangintsl --hostname=XXXXX-YYY
>>> XXXXX = nama klien (gelar + nama panggilannya terhadap Tommy, bilang agar mudah diservis, lalu masukkan di sini)
>>> YYY = sistem klien (cuma bisa Deb/Ubu/Win/Mac)

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
