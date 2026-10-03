# Panduan Linux (Ubuntu / Debian)

> **Terakhir diperbarui: Sabtu, 03 Okt 2026 · 16:15 WIB**

Ini sistem yang **paling disarankan**. Paling stabil, paling ringan,
dan paling cocok untuk dipakai 24/7.

---

## Yang dibutuhkan

| | Minimal | Disarankan |
|---|---|---|
| Sistem | Ubuntu 22.04 / Debian 12 | Ubuntu 24.04 atau lebih baru |
| Ruang disk | 15 GB | 30 GB |
| Memori | 4 GB | 8 GB |
| Prosesor | 2 core | 4 core |

Cocok untuk: **server, VPS, mini PC**, atau komputer yang menyala terus.

---

## Cara pakai

```bash
git clone <URL-REPO-ANDA>
cd hermes-custom
./install.sh
```

Selesai. Ikuti 4 langkah yang muncul di layar (sekitar 5 menit).

---

## Opsi

```bash
./install.sh --tes            # periksa sistem saja, tidak mengubah apa pun
./install.sh --tanpa-docker   # tanpa WhatsApp & pencarian (ringan)
./install.sh --tanpa-stt      # tanpa suara lokal (hemat memori)
```

---

## Apa yang dilakukan pemasang

### Tahap 1 — Periksa sistem
```
✓ Sistem operasi & arsitektur
✓ Akses admin (sudo)
✓ Ruang disk (minimal 15 GB) & memori
✓ Koneksi internet
✓ Port yang mungkin bentrok
```

### Tahap 2 — Komponen dasar
```
✓ Paket apt: git, python3, rsync, ffmpeg, xvfb, x11vnc, novnc, dll
✓ Docker + docker compose
✓ Hermes Agent
✓ Lingkungan Python (venv)
✓ Camoufox (~1,3 GB) — browser anti-detect
✓ Tailscale
```

### Tahap 3 — Aplikasi & pengaturan
```
✓ config.yaml (suara lokal, pencarian, browser)
✓ SearXNG lokal (pencarian tanpa API key) — port 8080
✓ Suara lokal faster-whisper (model 'medium')
✓ Evolution API (WhatsApp) — port 8081
✓ Remote web view (noVNC) — port 6080
```

### Tahap 4 — Otomatisasi
```
✓ Autostart tingkat sistem (systemd)
✓ Backup otomatis 2x sehari
✓ Alat Google (Sheets/Drive/Docs)
```

### Tahap 5 — Giliran Anda
```
1. Tailscale   — otomatis nyambung (kalau ada kunci dari teknisi)
2. Nous Portal — login sekali (WAJIB)
3. WhatsApp    — pindai QR (mode self-chat)
4. Google      — login OAuth
```

---

## Server tanpa layar (headless)

Pemasang ini dirancang untuk server tanpa monitor. Yang perlu diperhatikan:

**Nous Portal butuh browser.** Kalau server Anda tanpa layar:

```bash
# Cara 1 — pakai remote view (browser di server, dilihat dari luar)
~/.hermes/remote-view/remote-view.sh start
~/.hermes/remote-view/remote-view.sh password
# lalu buka http://<IP-tailscale>:6080/vnc.html

# Cara 2 — tempel API key manual
hermes setup model
```

**Pindai QR WhatsApp** juga butuh tampilan. Pakai remote view di atas.

---

## Perintah yang sering dipakai

```bash
# Robot
hermes                                   # mulai mengobrol
hermes setup --portal                    # login Nous Portal
hermes setup tools                       # login Google
sudo systemctl status hermes-gateway     # cek status robot
sudo systemctl restart hermes-gateway    # nyalakan ulang
journalctl -u hermes-gateway -n 50       # lihat catatan robot

# Remote view
~/.hermes/remote-view/remote-view.sh start
~/.hermes/remote-view/remote-view.sh stop
~/.hermes/remote-view/remote-view.sh status
~/.hermes/remote-view/remote-view.sh password

# Docker
docker ps                                # lihat yang jalan
docker logs evolution_api                # catatan WhatsApp

# Backup
ls -lh ~/backups_agent/                  # cadangan
cat ~/.hermes/logs/backup.log            # catatan backup
```

---

## Setelah pemasangan — cek kesehatan

```bash
# 1. Robot jalan?
systemctl is-active hermes-gateway
# harapan: active

# 2. Container jalan?
docker ps --format '{{.Names}}\t{{.Status}}'
# harapan: evolution_api, evolution_postgres, evolution_redis, searxng

# 3. Pencarian hidup?
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/
# harapan: 200

# 4. Suara lokal siap?
~/.hermes/hermes-agent/venv/bin/python -c "import faster_whisper; print('siap')"
```

---

## Pemecahan masalah

Lihat [PEMECAHAN.md](PEMECAHAN.md) untuk daftar lengkap.

| Gejala | Perbaikan cepat |
|---|---|
| `Permission denied` | `chmod +x install.sh` |
| Robot tidak jalan setelah reboot | `sudo systemctl enable --now hermes-gateway` |
| Robot balas dua kali | `systemctl --user status hermes-gateway` → harus **masked** |
| Pemasangan berhenti di tengah | Aman diulang: `./install.sh` |
| Docker belum dikenali | Keluar lalu login ulang |

---

## Yang perlu diingat

```
1. Ubuntu/Debian = pilihan terbaik. Paling stabil & paling ringan.
2. Pemasangan aman diulang — kalau gagal, jalankan lagi.
3. Manusia hanya diperlukan di tahap 5.
4. Remote view hanya bisa diakses lewat Tailscale (aman).
5. Matikan remote view kalau tidak dipakai:
     ~/.hermes/remote-view/remote-view.sh stop
6. Untuk 24/7: pakai komputer yang menyala terus (server/mini PC).
```
