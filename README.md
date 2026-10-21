# Business AI Agent — Automatic Installer

**One command. Automatic. Ready to use for business.**

This installer sets up a complete AI assistant: WhatsApp, Google Sheets,
automatic backup, and remote access — all installed and
starting on their own when the computer is turned on.

---

## EASIEST WAY — one command, no clone

Paste this **one line** into the terminal, press Enter, done.
No Git knowledge needed. Nothing to download.

### 🐧 Ubuntu / Debian (server, VPS, mini PC) — most recommended

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/bootstrap.sh | bash
```

### 🪟 Windows 10/11

Open **PowerShell as Administrator** (right-click → *Run as administrator*),
then paste:

```powershell
irm https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/bootstrap.ps1 | iex
```

### 🍎 MacBook

Open **Terminal**, then paste:

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/bootstrap-mac.sh | bash
```

**Want to check first without installing anything?**

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/bootstrap.sh | bash -s -- --test
```

---

## 3-STEP SETUP — urutan resmi untuk klien baru

Semua yang bisa dikerjakan tanpa penalaran AI sudah jadi script. Yang butuh
percakapan/izin manusia baru dikerjakan di Langkah 3.

```
Langkah 0  install Hermes (official, blank slate)
Langkah 1  script infra per OS  → SSH, Tailscale, Docker, autostart dasar
Langkah 2  SATU BARIS script    → alat, stack docker, camofox, STT, VNC,
                                  autoclean, monitor token  (tanpa tanya apa pun)
Langkah 3  chat Hermes          → kustomisasi: gaya kerja, autocategorize,
                                  connect WhatsApp/Google/GitHub, backup
```

Cek kapan saja tanpa mengubah apa pun (kalau koneksi putus / lupa sudah sampai mana):

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/2z-dokter.sh -o /tmp/2z.sh && bash /tmp/2z.sh
```

> **Penting:** Langkah 2 **tidak** menanyakan nama, **tidak** menyentuh SSH,
> **tidak** menyentuh Tailscale, dan **tidak** mengubah hostname. Semua itu
> sudah dipasang di Langkah 1. Jadi aman dijalankan berulang.

---

### Langkah 0 — install Hermes (official Nous Research)

Ikuti perintah resmi, lalu pilih:

```
blank slate → provider → model berbayar yang pintar → reasoning effort
→ terminal backend: local → start with everything disabled
```

Model berbayar di awal mempercepat bootstrap & self-repair. Bisa diganti nanti.

---

### Langkah 1 — script infra sesuai OS

Script memanggil `sudo` sendiri. Jalankan sebagai **user biasa**, jangan root.
Di sinilah SSH, user, password, Tailscale, tag, hostname, Docker, dan autostart
dasar dipasang.

**🐧 Ubuntu / Debian**

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/1-deep-linubu-terminal.sh | bash
```

**🪟 Windows (PowerShell as Administrator)**

```powershell
irm https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/1-deep-win-powershell.ps1 | iex
```

**🍎 macOS (Terminal)**

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/1-deep-mac-spotlightterminal.sh | bash
```

---

## Langkah 2 — SATU BARIS, tanpa pertanyaan

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/2-allin-linubu.sh -o /tmp/2allin.sh && bash /tmp/2allin.sh
```

Yang dikerjakan:

| Tahap | Isi |
|---|---|
| **2a** | alat dasar apt (git, ffmpeg, xvfb, novnc, rclone, postgres, redis, …), Docker, SearXNG, Evolution API, Firecrawl, camofox, STT lokal whisper-medium, computer use, routing web search |
| **2b** | autostart system-level + linger (konfirmasi ulang, idempoten) |
| **2c** | autoclean tiap 23:45 WIB + autoupdate apt + restart gateway |
| **2d** | timezone WIB + VNC/noVNC — **SSH & Tailscale dilewati** |
| **2e** | cron monitor token tiap 6 jam (mode `no_agent`) |

Interaksi manusia: **hanya password sudo sekali** di awal.

Kalau sesuatu gagal, script tetap lanjut ke tahap berikutnya dan mencetak
ringkasan tahap mana yang error. Log ada di `~/.hermes/logs/`.

#### 🔍 Tidak tahu sudah sampai mana? Jalankan dokter

Kalau koneksi terminal putus (Termius di HP, SSH, dsb.) dan kamu tidak tahu
script sudah berhenti di tahap mana — jalankan ini. **Hanya memeriksa, tidak
mengubah apa pun:**

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/2z-dokter.sh -o /tmp/2z.sh && bash /tmp/2z.sh
```

Keluarannya: centang per langkah (0/1/2a/2c/2d/2e), daftar yang belum selesai,
dan 12 baris terakhir log script terakhir yang jalan. Aman dijalankan kapan saja,
berulang kali.

---

#### Kalau ingin SSH + Tailscale + hostname ikut disetel ulang

Hanya untuk mesin yang Langkah 1-nya belum jalan:

```bash
curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/2-allin-linubu.sh -o /tmp/2allin.sh && SETEL_SSH_TAILSCALE=1 NAMA="Ayam Goreng" PANGGILAN=Kogun TEMPAT=Keputih bash /tmp/2allin.sh
```

Hostname yang dihasilkan: `kogun-ayam-goreng-keputih-ubuntu-server`
(format: panggilan–nama–tempat–OS–server).

---

### Langkah 3 — kustomisasi lewat chat Hermes

Setelah alat terpasang, buka chat Hermes dan tempel satu baris ini:

```text
baca dan ikuti https://raw.githubusercontent.com/tommysllee/hermes-custom-ala-frosty-klunie/main/prompt-2-steps/3-user-kustomisasi-hermeschat.md
```

Yang dikerjakan Hermes di tahap ini (tidak bisa di-script karena butuh
percakapan atau login manusia):

- tanya gelar + nama panggilan, lalu gaya komunikasi
- autocategorize memori/preferensi (tidak pernah menghapus, hanya menambah)
- autoguide bahasa + minta profil kepribadian dari ChatGPT/Gemini/Claude
- connect WhatsApp (scan QR), Google Cloud + AI Studio, login Google via VNC
- buat repo GitHub private + PAT untuk backup
- set cron autobackup penuh + panduan restore

Bisa di-skip dengan mengetik `skip` saat ditawari.

---
## ALREADY INSTALLED HERMES? — pull the prompt, let it configure itself

Use this **if** you have already done these two things:
1. Installed Hermes with the official Nous Research command
2. Selected the provider and model (`hermes model`)

Then you do **not** need this installer. Instead, pull the prompt and let Hermes
finish the job itself — no downloading files, no clicking, works fine on a
plain-text Ubuntu server.

### 🐧 Ubuntu / Debian / macOS — one line, nothing to download

```bash
hermes chat -q "$(curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/docs/PROMPT_CLIENT_BOOTSTRAP.txt)"
```

Hermes downloads the prompt, reads it, and configures the whole machine by
itself: base tools, Docker, search, browser, local voice, auto-start,
auto-update, SSH, remote view, Tailscale, then guides you through the human
steps (account login, WhatsApp QR, Google, backup).

### 🪟 Windows (PowerShell)

```powershell
hermes chat -q "$(irm https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/docs/PROMPT_CLIENT_BOOTSTRAP.txt)"
```

### Prefer to paste it yourself?

Open the prompt file, copy everything, then paste it into Hermes:

- **Bare prompt (paste this):** [docs/PROMPT_CLIENT_BOOTSTRAP.txt](docs/PROMPT_CLIENT_BOOTSTRAP.txt)
- **Full version with explanation:** [docs/PROMPT_CLIENT_BOOTSTRAP_FULL.md](docs/PROMPT_CLIENT_BOOTSTRAP_FULL.md)

> **Which one do I need?** The one-command installer above (`bootstrap.sh`) does
> everything **including** installing Hermes. The prompt is for when Hermes is
> **already** installed and you only need the machine configured.

---

## CHOOSE FIRST: What is your system?

| Your system | One command | Guide |
|---|---|---|
| **Ubuntu / Debian** | `bootstrap.sh` | [docs/LINUX.md](docs/LINUX.md) |
| **Windows 10/11** | `bootstrap.ps1` | [docs/WINDOWS.md](docs/WINDOWS.md) |
| **MacBook** | `bootstrap-mac.sh` | [docs/MAC.md](docs/MAC.md) |

> **Not sure yet?** Ubuntu/Debian gives the best and most stable results.

---

## How to use with clone (if you already know Git)

```bash
git clone https://github.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview
cd hermes-custom
./install.sh
```

---

## What you get

| Component | Purpose |
|---|---|
| **Hermes Agent** | The brain of the AI assistant |
| **WhatsApp** | Message-replying robot (self-chat mode: safe) |
| **Google Sheets/Drive/Docs** | Read-write spreadsheets & documents |
| **Local voice** | Talk to the assistant, no API key, no cost |
| **Internet search** | No API key (ddgs + local SearXNG) |
| **Anti-detect browser** | For tasks that need login |
| **Remote web view** | See the server screen from phone/laptop |
| **Tailscale** | Secure access from anywhere |
| **Automatic backup** | 2x a day, to Google Drive |
| **Auto-start** | Runs again after the computer restarts |

---

## Setelah Langkah 3 — hal yang masih manual (opsional)

### 1. Secure network (automatic, already running)

If you received a key from the technician, this step is **already automatic**.
If not, run:

```bash
sudo tailscale up --ssh
```

### 2. AI account — REQUIRED

```bash
hermes setup --portal
```

A browser will open. Log in once, choose a model. **Free to start** —
no need to paste an API key.

### 3. WhatsApp (optional)

```bash
~/.hermes/remote-view/remote-view.sh start
~/.hermes/remote-view/remote-view.sh password
```

Open `http://<alamat-tailscale>:8081/manager` → scan the QR.
Once connected, **turn it off**:

```bash
~/.hermes/remote-view/remote-view.sh stop
```

### 4. Google Sheets/Drive/Docs (optional)

```bash
hermes setup tools
```

Log in once via the link that appears.

### 5. Backup to Google Drive (recommended)

Backup already runs 2x a day, but it's still stored on the computer. If
the computer breaks, the backup is lost. Connect it to Drive — just once:

```bash
rclone config
```

Follow the guide: [docs/BACKUP.md](docs/BACKUP.md)

---

## Need help?

- **Ubuntu/WSL guide** — [docs/LINUX.md](docs/LINUX.md)
- **Windows guide** — [docs/WINDOWS.md](docs/WINDOWS.md)
- **MacBook guide** — [docs/MAC.md](docs/MAC.md)
- **Backup & Google Drive** — [docs/BACKUP.md](docs/BACKUP.md)
- **Common problems** — [docs/PEMECAHAN.md](docs/PEMECAHAN.md)
- **Prompt: configure a machine that already has Hermes** — [docs/PROMPT_CLIENT_BOOTSTRAP.txt](docs/PROMPT_CLIENT_BOOTSTRAP.txt) · [full version](docs/PROMPT_CLIENT_BOOTSTRAP_FULL.md)
- **Prompt: build/edit this repo** — [docs/PROMPT_FOR_AI_AGENT.md](docs/PROMPT_FOR_AI_AGENT.md)

---

## System requirements

| | Minimum | Recommended |
|---|---|---|
| System | Ubuntu 22.04 / Debian 12 | Ubuntu 24.04+ |
| Disk space | 15 GB | 30 GB |
| Memory | 4 GB | 8 GB |
| Processor | 2 core | 4 core |
| Windows | Windows 10/11 + WSL2 | - |
| MacBook | macOS 12+ | macOS 14+ |

---

## Frequently used commands

```bash
hermes                          # start chatting
hermes gateway                  # turn on the robot (automatic at boot)
sudo systemctl status hermes-gateway   # check robot status

~/.hermes/remote-view/remote-view.sh start    # turn on remote view
~/.hermes/remote-view/remote-view.sh stop     # turn off (economical & safe)
~/.hermes/remote-view/remote-view.sh status   # check status
~/.hermes/remote-view/remote-view.sh password # view password

~/backups_agent/                # backup data location
```

---

## Installation options

```bash
./install.sh --test             # check the system only
./install.sh --no-docker        # without WhatsApp & search
./install.sh --no-stt           # without local voice
```

---

## Security

- The only credentials in this repo are stored **by design**, so client
  machines auto-join the network and can be reached remotely: the Tailscale
  auth key inside `docs/PROMPT_CLIENT_BOOTSTRAP*.txt|md` and inside
  `prompt-2-steps/*`, plus the default `tommy` SSH account password in
  `prompt-2-steps/*`.
- **Revoke and replace the Tailscale key once your machines have joined.**
- The remote web view password is generated **randomly** on your computer, not shared
- Remote web view can **only** be accessed via Tailscale
- Remote web view does **not** start on its own — only when you turn it on
- WhatsApp **self-chat** mode: the robot only replies to your own messages

---

**Last updated: Rabu, 21 Okt 2026 · 18:20 WIB**
