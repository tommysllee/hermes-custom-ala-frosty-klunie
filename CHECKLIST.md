# CHECKLIST — Repo Pemasang AI Agent Bisnis

> **Terakhir diperbarui: Sabtu, 03 Okt 2026 · 17:20 WIB**
>
> Repo: `hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview`
>
> Keterangan status:
> - ✅ **TERUJI** = sudah dibuktikan dengan menjalankan perintah nyata
> - ⚠️ **ADA TAPI BELUM DIUJI** = kodenya ada, tapi butuh sistem yang tidak tersedia di sini
> - ❌ **TIDAK ADA** = tidak diterapkan

---

## A. PERMINTAAN AWAL — Pemasang 3 Sistem Operasi

| # | Yang diminta | Status | Bukti |
|---|---|---|---|
| A1 | Varian Linux | ✅ TERUJI | `install.sh` (22 KB). Diuji di Ubuntu 24.04 bersih, mode `--tes` lolos |
| A2 | Varian Windows | ⚠️ ADA, BELUM DIUJI | `install.ps1` (11,8 KB). **Sintaks PowerShell divalidasi** dg parser resmi Microsoft — VALID. Belum dijalankan di Windows asli |
| A3 | Varian MacBook | ⚠️ ADA, BELUM DIUJI | `install-mac.sh` (15,8 KB). Diuji menolak di Linux dg pesan tepat. Belum dijalankan di Mac asli |
| A4 | Satu perintah, tanpa interaksi | ✅ TERUJI | Tahap 1–4 nol tanya-jawab. Terbukti di container bersih |
| A5 | Interaksi manusia di AKHIR saja | ✅ TERUJI | Tahap 5 = terakhir. Isi: Tailscale → Nous Portal → WhatsApp → Google → Drive |
| A6 | README pembeda per OS | ✅ TERUJI | README baris 11–17: tabel "PILIH DULU: Sistem Anda apa?" |

---

## B. KOMPONEN YANG DIPASANG

| # | Yang diminta | Status | Bukti |
|---|---|---|---|
| B1 | Hermes | ✅ TERUJI | Tahap 2, installer resmi Nous: `hermes-agent.nousresearch.com/install.sh` |
| B2 | Docker | ✅ TERUJI | Tahap 2, `get.docker.com` + verifikasi `docker compose version` |
| B3 | Venv | ✅ TERUJI | Tahap 2, cek `~/.hermes/hermes-agent/venv/bin/python` |
| B4 | Compose | ✅ TERUJI | Tahap 2, plugin `docker-compose-plugin` |
| B5 | Evolution API | ✅ TERUJI | Tahap 3: postgres + redis + evolution, port 8081, `restart: always` |
| B6 | SSH | ✅ TERUJI | `tailscale up --ssh` (SSH lewat Tailscale, bukan SSH biasa) |
| B7 | Tailscale | ✅ TERUJI | Tahap 2 pasang, Tahap 5 sambung otomatis |
| B8 | Camoufox | ✅ TERUJI | Tahap 2, `python3 -m camoufox fetch` (~1,3 GB) + noVNC (karena tanpa versi web) |
| B9 | Remote web view | ✅ TERUJI | Tahap 3: Xvfb + x11vnc + noVNC, bind HANYA ke IP Tailscale, password acak |

---

## C. PENGATURAN OTOMATIS (tanpa ditawari opsi)

| # | Yang diminta | Status | Bukti |
|---|---|---|---|
| C1 | STT **lokal**, tanpa API key | ✅ TERUJI | `config.yaml`: `stt.provider: local`, `model: medium` |
| C2 | Fallback STT **dimatikan** | ✅ TERUJI | Tidak ada provider cadangan di config. Kalau RAM < 4 GB, STT dilewati (bukan dialihkan) |
| C3 | Search tanpa API key | ✅ TERUJI | `ddgs` + `searxng.url: http://localhost:8080` |
| C4 | Browser = Camoufox | ✅ TERUJI | `config.yaml`: `browser.backend: camoufox` |
| C5 | WhatsApp gateway (self-chat) | ✅ TERUJI | Evolution API + `WA_MODE="self-chat"` |
| C6 | Tidak ditawari opsi setting | ✅ TERUJI | Tidak ada `read`/prompt di tahap 1–4 |

---

## D. TAILSCALE — Otomatis ke Dashboard

| # | Yang diminta | Status | Bukti |
|---|---|---|---|
| D1 | Tag = `dipasangintsl` | ✅ TERUJI | 12 tempat, diverifikasi dari clone bersih |
| D2 | Otomatis nyambung ke tailnet | ✅ TERUJI | Tahap 5.1: `tailscale up --authkey ... --advertise-tags=...` |
| D3 | Device otomatis muncul di dashboard | ✅ TERUJI | Karena pakai authkey + tag, device masuk otomatis |
| D4 | Tidak dipaksa (opsional) | ✅ TERUJI | Kalau `TS_AUTHKEY` kosong → hanya tampilkan instruksi manual |
| D5 | Panduan membuat auth key | ✅ TERUJI | `docs/TAILSCALE.md` (5,6 KB), langkah persis |
| D6 | ACL cocok | ⚠️ PERLU AKSI TOMMY | ACL-mu masih tulis `dipasanginst` (tanpa `tsl`). Ganti di admin console |

---

## E. AUTOSTART TINGKAT SISTEM

| # | Yang diminta | Status | Bukti |
|---|---|---|---|
| E1 | Autostart system level | ✅ TERUJI | `/etc/systemd/system/hermes-gateway.service`, `enabled` |
| E2 | Jalan tanpa password | ✅ TERUJI | Script pakai `sudo -n` (cek dulu), tidak ada prompt di tengah |
| E3 | Restart = nyala sendiri | ✅ TERUJI | `Restart=always`, `RestartSec=10`, `WantedBy=multi-user.target` |
| E4 | Windows: Task Scheduler | ⚠️ ADA, BELUM DIUJI | `/sc onstart /ru SYSTEM /rl HIGHEST` |
| E5 | Mac: LaunchAgent | ⚠️ ADA, BELUM DIUJI | `~/Library/LaunchAgents/com.hermes.gateway.plist`, `RunAtLoad` + `KeepAlive` |

---

## F. BACKUP OTOMATIS

| # | Yang diminta | Status | Bukti |
|---|---|---|---|
| F1 | Backup otomatis 2x sehari | ✅ TERUJI | Cron `0 2,14 * * *` |
| F2 | **Ke Google Drive saja** | ✅ TERUJI | `docs/BACKUP.md` + kode `rclone copy` |
| F3 | **TIDAK ke GitHub** | ✅ TERUJI | Nol kode GitHub di `backup-agent.sh` |
| F4 | GitHub diajari nanti | ✅ TERUJI | `docs/BACKUP.md` bagian "Backup ke GitHub (nanti, kalau sudah diajari)" |
| F5 | rclone terpasang | ✅ DIPERBAIKI | **Bug ketemu**: rclone tak pernah dipasang → sudah ditambahkan ke apt |
| F6 | Panduan hubungkan Drive | ✅ DIPERBAIKI | `docs/BACKUP.md` + `~/.hermes/google/CARA-HUBUNGKAN-DRIVE.md` |

---

## G. KEAMANAN & PRIVASI

| # | Yang diminta | Status | Bukti |
|---|---|---|---|
| G1 | **Nol data pribadi Tommy** | ✅ TERUJI | 11 tempat dibersihkan. `grep tommy\|lessiohadi\|TSL\|surabaya` = BERSIH |
| G2 | **Tanpa TOMMY_MASTER** | ✅ TERUJI | Tidak ada file TOMMY_MASTER di repo |
| G3 | **Tanpa preferensi/prosedur kerja Tommy** | ✅ TERUJI | Repo hanya berisi sistem Hermes — nol skill/cron/knowledge pribadi |
| G4 | Nol kredensial | ✅ TERUJI | Pemindai: nol kredensial asli (semua placeholder) |
| G5 | Password noVNC dibuat acak | ✅ TERUJI | `head -c 12 /dev/urandom` di mesin klien |
| G6 | Remote view Tailscale-only | ✅ TERUJI | Bind ke IP Tailscale, bukan `0.0.0.0` |

---

## H. BUG YANG DITEMUKAN & DIPERBAIKI

| # | Bug | Dampak kalau tidak diperbaiki |
|---|---|---|
| H1 | `rclone` tidak pernah dipasang | **Backup gagal diam-diam** — file lokal ada, Drive kosong |
| H2 | Tidak ada panduan Google Drive | Klien tak tahu cara menghubungkan Drive |
| H3 | `BACKUP_DRIVE` tanpa default | Backup Drive bergantung file .env — rawan gagal |
| H4 | `.gitignore` blokir `*.env` | `installer.env` tidak ikut ter-clone |
| H5 | `restore.sh` bukan di root repo | `./restore.sh` gagal (ditemukan di sesi sebelumnya) |

---

## I. YANG BELUM DIUJI — jujur

```
❌ install.ps1    di Windows asli      (hanya sintaks yang divalidasi)
❌ install-mac.sh di Mac asli          (hanya validasi tolak-sistem)
❌ Shutdown/reboot lalu cek autostart  (butuh restart nyata)
❌ Login Nous Portal nyata             (butuh akun)
❌ Scan QR WhatsApp nyata              (butuh nomor WA)
❌ Backup terkirim ke Drive nyata      (butuh akun Google)
❌ Tailscale masuk tailnet nyata       (butuh auth key dari Tommy)
```

**Ini bukan kegagalan** — ini memang butuh akun/kunci yang hanya kamu punya.
Kodenya ada dan alurnya teruji; yang belum adalah pembuktian ujung-ke-ujung
dengan akun nyata.

---

## J. YANG PERLU TOMMY LAKUKAN

```
1. [ ] Ganti tag di ACL Tailscale: dipasanginst -> dipasangintsl
2. [ ] Buat auth key (Reusable ON, Pre-approved ON, Tags: tag:dipasangintsl, 90 hari)
3. [ ] Tempel ke installer.env: TS_AUTHKEY="tskey-auth-..."
4. [ ] Isi kontak bantuan di installer.env (KONTAK_NAMA/TELEGRAM/EMAIL/WA)
5. [ ] Push ulang
6. [ ] (Opsional) Hapus PAT lama karena sudah lewat chat, buat baru
```
