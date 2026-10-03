# Pemecahan Masalah

> **Terakhir diperbarui: Sabtu, 03 Okt 2026 · 15:40 WIB**

---

## Pemasangan

| Gejala | Sebab | Perbaikan |
|---|---|---|
| `Permission denied` saat `./install.sh` | File tidak bisa dieksekusi | `chmod +x install.sh` |
| `butuh Ubuntu atau Debian` | Sistem lain | Windows → WSL2; Mac → lihat docs/MAC.md |
| `ruang kurang dari 15 GB` | Disk penuh | Kosongkan, lalu ulangi |
| `tidak ada internet` | Jaringan bermasalah | Cek koneksi, ulangi |
| Pemasangan berhenti di tengah | Jaringan putus | **Aman diulang** — jalankan `./install.sh` lagi |
| Hermes gagal dipasang | Jaringan putus di tengah | `curl -fsSL https://hermes-agent.nousresearch.com/install.sh \| bash` lalu ulangi |
| Camoufox gagal unduh (~1,3 GB) | Koneksi lambat / putus | Ulangi; atau lewati — tidak wajib |
| `docker: command not found` setelah pasang | Perlu login ulang | Keluar lalu masuk lagi (grup docker) |

---

## Menyalakan robot

| Gejala | Sebab | Perbaikan |
|---|---|---|
| Robot tidak jalan setelah reboot | Layanan belum aktif | `sudo systemctl enable --now hermes-gateway` |
| `Failed to start` | Path salah | Cek: `which hermes` → harus `~/.local/bin/hermes` |
| Robot jalan lalu mati terus | Crash berulang | Lihat: `journalctl -u hermes-gateway -n 50` |
| Robot balas dua kali | Ada dua layanan jalan | `systemctl --user status hermes-gateway` → harus **masked** |
| Sudah `hermes update` lalu mati | Layanan perlu dinyalakan lagi | `sudo systemctl restart hermes-gateway` |

---

## WhatsApp

| Gejala | Sebab | Perbaikan |
|---|---|---|
| QR tidak muncul | Evolution belum siap | Tunggu 30 detik; cek `docker ps` |
| QR muncul tapi gagal scan | Layar terlalu kecil | Perbesar tampilan browser |
| Tersambung lalu putus | WhatsApp logout perangkat | Pindai ulang QR |
| Tidak bisa buka `:8081/manager` | Tailscale belum jalan | `sudo tailscale status` |
| Robot tidak balas | Mode self-chat | Kirim pesan **ke diri sendiri**, bukan ke orang lain |

---

## Suara (bicara ke robot)

| Gejala | Sebab | Perbaikan |
|---|---|---|
| Suara tidak dikenali | Model belum diunduh | Unduh otomatis saat pertama dipakai — tunggu ~5 menit |
| Lambat sekali | Komputer kurang kuat | Model 'medium' berat; pakai komputer lebih kuat |
| Salah kata terus | Aksen / noise | Bicara lebih dekat ke mikrofon, kurangi suara latar |
| `faster_whisper` tidak ada | Gagal dipasang | `~/.hermes/hermes-agent/venv/bin/pip install faster-whisper` |

---

## Remote web view (noVNC)

| Gejala | Sebab | Perbaikan |
|---|---|---|
| Halaman tidak terbuka | Belum dinyalakan | `~/.hermes/remote-view/remote-view.sh start` |
| Tidak bisa diakses dari HP | Tailscale belum jalan | `sudo tailscale status`, lalu coba lagi |
| Sandi ditolak | Sandi berubah | `~/.hermes/remote-view/remote-view.sh password` |
| Layar hitam | Browser belum dijalankan | Normal — jalankan dulu aplikasi yang mau dilihat |
| Ingin mematikan | Hemat & aman | `~/.hermes/remote-view/remote-view.sh stop` |

---

## Pencarian internet

| Gejala | Sebab | Perbaikan |
|---|---|---|
| Hasil pencarian kosong | SearXNG belum siap | Tunggu 30 detik; cek `docker ps \| grep searxng` |
| Masih pakai ddgs saja | SearXNG belum jalan | `cd ~/searxng && docker compose up -d` |
| Port 8080 bentrok | Aplikasi lain memakai | Ubah port di `~/searxng/docker-compose.yml` |

---

## Google Sheets / Drive

| Gejala | Sebab | Perbaikan |
|---|---|---|
| Login Google gagal | Tautan kedaluwarsa | Ulangi: `hermes setup tools` |
| Masih minta login tiap minggu | Izin OAuth mode Testing | Buka console.cloud.google.com → OAuth consent → **Publish App** |
| `invalid_grant` | Token kedaluwarsa | Ulangi `hermes setup tools` |

---

## Backup

| Gejala | Sebab | Perbaikan |
|---|---|---|
| Backup tidak jalan | Cron belum terdaftar | `crontab -l` → harus ada `backup-agent.sh` |
| Gagal kirim ke Drive | rclone belum disiapkan | Jalankan: `rclone config` |
| Disk penuh | Arsip menumpuk | Arsip >7 hari otomatis dihapus; cek `~/backups_agent/` |

---

## Kalau semuanya gagal

```bash
# 1. Lihat catatan lengkap
cat /tmp/agent-install-*.log

# 2. Cek layanan
sudo systemctl status hermes-gateway
docker ps

# 3. Jalankan ulang installer (aman diulang)
./install.sh
```

Masih bermasalah? Hubungi teknisi Anda dengan membawa:
- Output perintah di atas
- Isi file `/tmp/agent-install-*.log`
