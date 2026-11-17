# STRUCTURED SETUP — PASANG HERMES DENGAN URUTAN YANG BENAR

> **Terakhir update:** Selasa, 17 November 2026 · 23:20 WIB
> **Ini jalur yang DISARANKAN.** Kerjakan berurutan, jangan melompat.

---

## Kenapa ada folder ini

Folder induk punya banyak file. Yang paling sering dipakai orang adalah
**"one-liner dari awal sampai akhir"** — satu baris, selesai. Itu **tidak
realistis**: setiap mesin beda izin, beda OS, beda jaringan. Kalau gagal di
tengah, orang tidak tahu harus mulai dari mana lagi.

Folder ini membaginya jadi **langkah kecil berurutan**. Tiap langkah punya
pemeriksaan sendiri, jadi kalau ada yang gagal, jelas langkah mana.

---

## Urutan pengerjaan

```
  (a) a-langkah-0-persiapan.md
      └── sebelum apa pun: gmail, Ubuntu, Hermes, WIB, perangkat fisik
              ↓
  (b) 1-deep-*.{sh,ps1}
      └── akses masuk: SSH + user tslconsulting + Tailscale + Docker + gateway
              ↓
  (c) 2-allin-linubu.sh  /  2-user-allOS-in-hermeschat.md
      └── alat dasar: noVNC, SearXNG, camofox, STT, autoclean, monitor token
              ↓
  (d) d-ganti-model-fokus-deepseek.md
      └── ganti ke model berbayar + autocategorize + WhatsApp + Google + GitHub
              ↓
  (e) e-tawaran-hemat.md
      └── pengingat dua penawaran (opsional)
```

---

## Isi folder

| File | Untuk OS | Dijalankan di | Isi |
|---|---|---|---|
| `a-langkah-0-persiapan.md` | semua | dibaca manusia | checklist pra-instalasi |
| `1-deep-linubu-terminal.sh` | Ubuntu/Debian | terminal, superuser | SSH, user `tslconsulting`, Tailscale, Docker, gateway system-level |
| `1-deep-win-powershell.ps1` | Windows | PowerShell, admin | hal sama, versi Windows |
| `1-deep-mac-spotlightterminal.sh` | macOS | Terminal, sudo | hal sama, versi macOS |
| `2-allin-linubu.sh` | Ubuntu/Debian | terminal | alat dasar + autostart + maintenance + monitor token |
| `2-user-allOS-in-hermeschat.md` | Windows/Mac | **chat Hermes** | hal sama, dikerjakan lewat chat |
| `d-ganti-model-fokus-deepseek.md` | semua | chat Hermes | bahasa Spanyol, ganti model + autocategorize + koneksi |
| `e-tawaran-hemat.md` | semua | chat Hermes | pengingat dua penawaran |

---

## Username akses remote

Script membuat user **`tslconsulting`** (bukan `tommy`/`tomvejadwal`) supaya
username yang dipakai masuk ke mesin klien terlihat profesional.

```
Yang TIDAK diubah dari versi lama, karena sudah terbukti aman:
  - password SSH
  - auth-key Tailscale dan tag-nya
  - pola autostart system-level + linger
```

---

## Catatan jujur

- **"One-liner dari awal sampai akhir" tidak disarankan.** Sekali gagal, seluruh
  proses harus diulang dari nol. Pakai urutan di folder ini.
- Script `1-*` **butuh superuser**. Di Ubuntu namanya `sudo`, di Windows harus
  "Run as Administrator", di Mac pakai `sudo`.
- **Restore setelah instalasi ulang butuh token GitHub.** Simpan tokennya di
  tempat aman sebelum mesin dihapus. Tanpa token, repo backup private tidak bisa
  di-clone.
- Zona waktu **wajib** Asia/Jakarta sebelum Langkah 1. Kalau tidak, semua jadwal
  cron meleset 7 jam.
