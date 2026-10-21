# Cakupan Script — Tahap 2 (setelah Hermes terinstall)

Terakhir update: Rabu, 21 Okt 2026 · 11:20 WIB

Prompt asli: `2-user-allOS-in-hermeschat.md`.
Script di bawah menggantikan bagian-bagian yang **deterministik** (tidak butuh
penalaran LLM). Bagian yang butuh percakapan/keputusan manusia tetap dikerjakan
Hermes.

## Urutan jalan (Ubuntu/Debian)

```bash
# sesudah 0-allin-linubu.sh / install Hermes
bash 2a-tools-linubu.sh          # alat dasar, docker stack, camofox, STT, routing web
bash 2b-autostart-linubu.sh      # gateway system-level + linger
bash 2c-maintenance-linubu.sh    # autoclean harian + autoupdate apt + restart gateway
NAMA=gunawan bash 2d-remote-linubu.sh   # WIB, SSH, VNC, Tailscale
bash 2e-token-monitor.sh         # cron token tiap 6 jam
```

## Sudah jadi script

| Bab | Isi | Script |
|---|---|---|
| a.2 | paket dasar apt (git, ffmpeg, xvfb, novnc, rclone, postgres, redis, dll) | `2a` |
| a.2 | SearXNG + Evolution API di Docker | `2a` |
| a.2 | camofox, STT lokal (faster-whisper medium), computer use | `2a` |
| a.2 | routing web search keyless + SearXNG | `2a` |
| b.2 | autostart system-level + linger (tanpa login) | `2b` |
| b.3 | autoclean akhir hari + autoupdate apt + restart gateway | `2c` |
| b.4 | timezone sistem = Asia/Jakarta | `2d` |
| b.5 | SSH + VNC/noVNC + Tailscale (tag, hostname, no-expiry) | `2d` |
| b.6 | cron monitor token 6 jam (sudah disediakan di md, kini 1 perintah) | `2e` |

## Masih harus dikerjakan Hermes (tidak bisa di-script)

| Bab | Kenapa |
|---|---|
| a.1 | tanya gelar/nama — percakapan |
| b.1 | autocategorize memori — perilaku LLM |
| b.4 | gaya bicara berbasis zona waktu — perilaku LLM |
| b.6 | isi/logika hitung token bila kuota berubah — perlu penalaran |
| c.1 | autoguide bahasa + minta profil dari AI lain — percakapan |
| c.2 | OAuth Google/AI Studio, scan QR WhatsApp, buat repo + PAT — butuh manusia |
| c.3 | keputusan mau backup ke mana + kredensial repo — butuh jawaban manusia |
| c.4 | bikin skill saat ada penolakan — keputusan LLM |

## Catatan jujur

- **Rantai 9 provider** (parallel → searxng → exa → keenable → tavily → firecrawl →
  brave → serper → ddgs) **tidak bisa dipaksakan** lewat config. Ring keyless
  Hermes urutannya tetap: `exa → parallel → firecrawl → keenable`, lalu SearXNG
  sebagai provider terpisah. Script menyetel primary + tier free + SearXNG URL.
- **Firecrawl self-host** berat (butuh ±2 GB RAM). Kalau gagal naik, script
  hanya memberi warning dan tidak menggagalkan keseluruhan.
- **Auto-update apt** dijalankan di pekerjaan harian (bukan event-driven saat
  ada update). Kalau butuh reaksi segera, tambahkan systemd timer terpisah.
