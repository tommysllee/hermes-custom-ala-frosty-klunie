# AI Agent Bisnis — Pemasang Otomatis

**Satu perintah. Otomatis. Siap dipakai untuk bisnis.**

Pemasang ini menyiapkan asisten AI lengkap: WhatsApp, Google Sheets,
backup otomatis, dan akses jarak jauh — semuanya sudah terpasang dan
menyala sendiri saat komputer dinyalakan.

---

## PILIH DULU: Sistem Anda apa?

| Sistem Anda | Cara pakai | Panduan |
|---|---|---|
| **Ubuntu / Debian** (server, VPS, mini PC) | `./install.sh` | [docs/LINUX.md](docs/LINUX.md) |
| **Windows 10/11** | `.\install.ps1` | [docs/WINDOWS.md](docs/WINDOWS.md) |
| **MacBook** | `./install-mac.sh` | [docs/MAC.md](docs/MAC.md) |

> **Belum yakin?** Ubuntu/Debian memberi hasil terbaik dan paling stabil.
> Windows & MacBook juga jalan, tapi lihat catatan di masing-masing panduan.

---

## Cara pakai — Ubuntu / Debian (disarankan)

```bash
git clone <URL-REPO-ANDA>
cd hermes-custom
./install.sh
```

---

Selesai. Tinggal ikuti 4 langkah terakhir yang muncul di layar
(sekitar 5 menit).

**Mau cek dulu tanpa memasang apa pun?**

```bash
./install.sh --tes
```

---

## Yang Anda dapat

| Komponen | Kegunaan |
|---|---|
| **Hermes Agent** | Otak asisten AI-nya |
| **WhatsApp** | Robot balas pesan (mode self-chat: aman) |
| **Google Sheets/Drive/Docs** | Baca-tulis spreadsheet & dokumen |
| **Suara lokal** | Bicara ke asisten, tanpa API key, tanpa biaya |
| **Pencarian internet** | Tanpa API key (ddgs + SearXNG lokal) |
| **Browser anti-detect** | Untuk tugas yang butuh login |
| **Remote web view** | Lihat layar server dari HP/laptop |
| **Tailscale** | Akses aman dari mana saja |
| **Backup otomatis** | 2x sehari, ke Google Drive |
| **Nyala sendiri** | Aktif lagi setelah komputer restart |

---

## Setelah pemasangan — 5 langkah

### 1. Jaringan aman (otomatis, sudah berjalan)

Kalau Anda menerima kunci dari teknisi, langkah ini **sudah otomatis**.
Kalau tidak, jalankan:

```bash
sudo tailscale up --ssh
```

### 2. Akun AI — WAJIB

```bash
hermes setup --portal
```

Browser akan terbuka. Login sekali, pilih model. **Gratis di awal** —
tidak perlu menempel API key.

### 3. WhatsApp (opsional)

```bash
~/.hermes/remote-view/remote-view.sh start
~/.hermes/remote-view/remote-view.sh password
```

Buka `http://<alamat-tailscale>:8081/manager` → pindai QR.
Setelah tersambung, **matikan**:

```bash
~/.hermes/remote-view/remote-view.sh stop
```

### 4. Google Sheets/Drive/Docs (opsional)

```bash
hermes setup tools
```

Login sekali lewat tautan yang muncul.

### 5. Backup ke Google Drive (disarankan)

Backup sudah jalan 2x sehari, tapi masih tersimpan di komputer. Kalau
komputernya rusak, cadangannya hilang. Hubungkan ke Drive — sekali saja:

```bash
rclone config
```

Ikuti panduan: [docs/BACKUP.md](docs/BACKUP.md)

---

## Butuh bantuan?

- **Panduan Ubuntu/WSL** — [docs/LINUX.md](docs/LINUX.md)
- **Panduan Windows** — [docs/WINDOWS.md](docs/WINDOWS.md)
- **Panduan MacBook** — [docs/MAC.md](docs/MAC.md)
- **Backup & Google Drive** — [docs/BACKUP.md](docs/BACKUP.md)
- **Masalah umum** — [docs/PEMECAHAN.md](docs/PEMECAHAN.md)

---

## Syarat sistem

| | Minimal | Disarankan |
|---|---|---|
| Sistem | Ubuntu 22.04 / Debian 12 | Ubuntu 24.04+ |
| Ruang disk | 15 GB | 30 GB |
| Memori | 4 GB | 8 GB |
| Prosesor | 2 core | 4 core |
| Windows | Windows 10/11 + WSL2 | - |
| MacBook | macOS 12+ | macOS 14+ |

---

## Perintah yang sering dipakai

```bash
hermes                          # mulai mengobrol
hermes gateway                  # nyalakan robot (otomatis saat boot)
sudo systemctl status hermes-gateway   # cek status robot

~/.hermes/remote-view/remote-view.sh start    # nyalakan remote view
~/.hermes/remote-view/remote-view.sh stop     # matikan (hemat & aman)
~/.hermes/remote-view/remote-view.sh status   # cek status
~/.hermes/remote-view/remote-view.sh password # lihat sandi

~/backups_agent/                # lokasi cadangan data
```

---

## Opsi pemasangan

```bash
./install.sh --tes              # periksa sistem saja
./install.sh --tanpa-docker     # tanpa WhatsApp & pencarian
./install.sh --tanpa-stt        # tanpa suara lokal
```

---

## Keamanan

- Tidak ada API key atau sandi yang disimpan di repo ini
- Sandi remote web view dibuat **acak** di komputer Anda, tidak dibagikan
- Remote web view **hanya** bisa diakses lewat Tailscale
- Remote web view **tidak** menyala sendiri — hanya saat Anda nyalakan
- Mode WhatsApp **self-chat**: robot hanya membalas pesan Anda sendiri

---

**Terakhir diperbarui: Sabtu, 03 Okt 2026 · 16:55 WIB**
