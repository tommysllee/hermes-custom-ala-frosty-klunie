# Panduan MacBook

> **Terakhir diperbarui: Sabtu, 03 Okt 2026 · 15:30 WIB**

Mac bisa dipakai, **tapi ada satu masalah besar** yang harus Anda pahami
dulu sebelum mulai.

---

## ⚠️ Masalah utama: FileVault

```
Kalau FileVault aktif, MacBook BERHENTI di layar login setelah restart.
Sebelum ada yang login, layanan latar belakang TIDAK berjalan.

Akibatnya: robot Anda MATI sampai ada yang membuka MacBook dan login.
```

**Ini bukan bug — ini memang begitu desain keamanan macOS.**

### Pilihan Anda

| Pilihan | Keamanan | Robot hidup? |
|---|---|---|
| Biarkan FileVault + login manual tiap reboot | ✅ Paling aman | ❌ Mati sampai login |
| Auto-login + FileVault | ⚠️ Sedang | ✅ Setelah disk terbuka |
| Matikan FileVault | ❌ Lemah | ✅ Selalu hidup |
| **Pakai mini PC Ubuntu** | ✅ Baik | ✅ Selalu hidup |

**Rekomendasi jujur:** kalau Anda butuh robot yang **selalu hidup**,
MacBook bukan pilihannya. Pakai komputer kecil yang menyala terus
(mini PC dengan Ubuntu, sekitar Rp850.000–1.300.000).

Kalau tetap mau pakai MacBook, ikuti panduan di bawah.

---

## Langkah 1 — Pasang alat dasar

Buka **Terminal** (Cmd+Space → ketik "Terminal"):

```bash
# Pasang Homebrew (kalau belum ada)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Pasang Docker Desktop
brew install --cask docker

# Buka Docker sekali supaya menyala (dari Applications)
```

> **Catatan:** macOS tidak punya `systemd` dan tidak punya `apt`.
> Installer Linux **tidak bisa** dijalankan langsung. Panduan ini
> memasang komponennya satu per satu.

---

## Langkah 2 — Pasang Hermes

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

Lalu cek:

```bash
hermes --version
```

---

## Langkah 3 — Suara lokal & browser

```bash
# Suara lokal (tanpa API key)
python3 -m pip install --user faster-whisper

# Browser anti-detect
python3 -m pip install --user camoufox
python3 -m camoufox fetch
```

---

## Langkah 4 — Tailscale

```bash
brew install --cask tailscale
```

Buka aplikasi Tailscale dari Applications, login.

---

## Langkah 5 — Autostart dengan LaunchAgent

Di macOS ada dua jenis:

```
LaunchDaemon  -> jalan SEBELUM login (butuh root)
                 ⚠️ TIDAK jalan kalau FileVault memblokir boot
LaunchAgent   -> jalan SETELAH login pengguna   <- pakai ini
```

### Buat LaunchAgent

Buat file `~/Library/LaunchAgents/com.hermes.gateway.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.hermes.gateway</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Users/NAMA_ANDA/.local/bin/hermes</string>
        <string>gateway</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/hermes-gateway.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/hermes-gateway-error.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/Users/NAMA_ANDA/.local/bin</string>
    </dict>
</dict>
</plist>
```

Ganti `NAMA_ANDA` dengan nama pengguna Mac Anda (cek: `whoami`).

Aktifkan:

```bash
launchctl load ~/Library/LaunchAgents/com.hermes.gateway.plist
launchctl start com.hermes.gateway
```

Cek status:

```bash
launchctl list | grep hermes
```

---

## Langkah 6 — Cegah MacBook tidur

```bash
# Saat colok listrik: jangan pernah tidur
sudo pmset -c sleep 0 disablesleep 1

# Cek pengaturan
pmset -g
```

> **Penting:** ini **hanya berlaku saat colok listrik**. Kalau pakai baterai,
> MacBook tetap akan tidur (dan robot mati).

### Supaya hidup setelah reboot — aktifkan auto-login

```
System Settings
  -> Users & Groups
     -> Automatically log in as: <nama Anda>
```

**Yang perlu dipahami:** FileVault tetap aktif. Sandi boot tetap diminta
saat pertama menyalakan. Auto-login hanya berlaku **setelah disk terbuka** —
jadi Anda tetap perlu mengetik sandi boot sekali.

---

## Pemecahan masalah Mac

| Gejala | Sebab | Perbaikan |
|---|---|---|
| Robot mati setelah reboot | FileVault menahan di layar login | Aktifkan auto-login (Langkah 6) |
| Robot mati saat pakai baterai | MacBook tidur | Colok listrik + `pmset` |
| `launchctl load` error | Path salah | Cek `whoami` dan `which hermes` |
| Docker tidak jalan | Aplikasi Docker belum dibuka | Buka Docker dari Applications |
| `camoufox fetch` gagal | Gatekeeper menolak | System Settings → Privacy → Allow |
| Port 6080 sudah dipakai | AirPlay Receiver | System Settings → General → AirDrop & Handoff → matikan AirPlay Receiver |

---

## Ringkasan: apa yang harus diingat

```
1. FileVault = robot mati sampai ada yang login. Ini masalah utama MacBook.
2. Pakai LaunchAgent (jalan setelah login), bukan LaunchDaemon.
3. Auto-login membantu, tapi TIDAK menghapus kebutuh sandi boot FileVault.
4. pmset -c sleep 0 disablesleep 1 -> hanya berlaku saat colok listrik.
5. Untuk robot yang selalu hidup, mini PC Ubuntu jauh lebih cocok
   daripada MacBook — dan jauh lebih murah.
6. macOS tidak punya systemd/apt -> installer Linux tidak berlaku.
   Pasang komponennya satu per satu seperti panduan di atas.
```
