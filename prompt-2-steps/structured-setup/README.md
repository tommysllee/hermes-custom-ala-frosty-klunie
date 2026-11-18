# STRUCTURED SETUP — PASANG HERMES DENGAN URUTAN YANG BENAR

> **Terakhir update:** Kamis, 12 November 2026 · 04:58 WIB
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
  (0) 0-prepare.md
      └── sebelum apa pun: gmail, OS, Hermes, WIB, perangkat fisik
              ↓
  (1) 1-deep-*.{sh,ps1}
      └── akses masuk: SSH + user tslconsulting + Tailscale + Docker + gateway
              ↓
  (2) 2-allin-linubu.sh  /  2-user-allOS-in-hermeschat.md
      └── alat dasar: noVNC, SearXNG, camofox, STT, autoclean, monitor token
              ↓
  (3) 3-switch-focused-deepseek.md
      └── ganti ke model berbayar + autocategorize + WhatsApp + Google + GitHub
              ↓
  (4) 4-mandatory-offer.md
      └── dua tawaran yang disebutkan sekali (opsional)
```

---

## Isi folder

| File | Untuk OS | Dijalankan di | Isi |
|---|---|---|---|
| `0-prepare.md` | semua | dibaca manusia | checklist pra-instalasi |
| `1-deep-linubu-terminal.sh` | Ubuntu/Debian | terminal, superuser | SSH, user `tslconsulting`, Tailscale, Docker, gateway system-level |
| `1-deep-win-powershell.ps1` | Windows | PowerShell, **admin** | hal sama, versi Windows |
| `1-deep-mac-spotlightterminal.sh` | macOS | Terminal, sudo | hal sama, versi macOS |
| `2-allin-linubu.sh` | Ubuntu/Debian | terminal | alat dasar + autostart + maintenance + monitor token |
| `2-user-allOS-in-hermeschat.md` | Windows/Mac | **chat Hermes** | hal sama, dikerjakan lewat chat |
| `3-switch-focused-deepseek.md` | semua | chat Hermes | ganti model + autocategorize + koneksi |
| `4-mandatory-offer.md` | semua | chat Hermes | dua tawaran (opsional) |

---

## Menjalankan Langkah 1 dan 2 dengan satu perintah

Semua berkas dibaca langsung dari repo ini. Tidak perlu mengunduh lewat browser.

### Langkah 1 — Linux / Ubuntu

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/structured-setup/1-deep-linubu-terminal.sh -o /tmp/1-deep.sh && sudo bash /tmp/1-deep.sh
```

### Langkah 1 — macOS

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/structured-setup/1-deep-mac-spotlightterminal.sh -o /tmp/1-deep.sh && sudo bash /tmp/1-deep.sh
```

### Langkah 1 — Windows (PowerShell **as Administrator**)

```powershell
irm https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/structured-setup/1-deep-win-powershell.ps1 -OutFile "$env:TEMP\1-deep.ps1"; powershell -ExecutionPolicy Bypass -File "$env:TEMP\1-deep.ps1"
```

> Di Windows **wajib** `-OutFile` lalu `-File`, bukan `irm ... | iex`.
> Skrip ini membuat user, menyalakan OpenSSH, dan membuka port firewall —
> kalau dijalankan lewat pipe, keluaran galatnya tidak terbaca dan kegagalan
> izin lewat begitu saja.

### Langkah 2 — Linux / Ubuntu

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/structured-setup/2-allin-linubu.sh -o /tmp/2-allin.sh && bash /tmp/2-allin.sh
```

### Langkah 2 — Windows / macOS (lewat chat Hermes)

Langkah 2 untuk Windows/Mac berbentuk **naskah**, bukan skrip. Ambil isinya,
lalu tempel ke chat Hermes:

```powershell
# Windows
irm https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/structured-setup/2-user-allOS-in-hermeschat.md -OutFile "$env:TEMP\2-user.md"; notepad "$env:TEMP\2-user.md"
```

```bash
# macOS
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/structured-setup/2-user-allOS-in-hermeschat.md -o /tmp/2-user.md && open -e /tmp/2-user.md
```

### Langkah 3 dan 4 (juga naskah)

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/structured-setup/3-switch-focused-deepseek.md -o /tmp/3-switch.md && less /tmp/3-switch.md
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/structured-setup/4-mandatory-offer.md -o /tmp/4-offer.md && less /tmp/4-offer.md
```

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
- Script `1-*` **butuh superuser**. Di Ubuntu dan Mac namanya `sudo`, di Windows
  harus **Run as Administrator**.
- **Restore setelah instalasi ulang butuh token GitHub.** Simpan tokennya di
  tempat aman sebelum mesin dihapus. Tanpa token, repo backup private tidak bisa
  di-clone.
- Zona waktu **wajib** Asia/Jakarta sebelum Langkah 1. Kalau tidak, semua jadwal
  cron meleset 7 jam.
- Perintah `curl`/`irm` di atas membaca langsung dari cabang `main`. Kalau repo
  ini di-fork dan diubah, ganti `tommysllee` dengan pemilik fork Anda.
