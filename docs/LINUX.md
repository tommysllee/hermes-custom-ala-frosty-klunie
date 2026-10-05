# Linux Guide (Ubuntu / Debian)

> **Last updated: Saturday, 03 Oct 2026 · 16:15 WIB**

This is the **most recommended** system. The most stable, the lightest,
and the most suitable for 24/7 use.

---

## Requirements

| | Minimum | Recommended |
|---|---|---|
| System | Ubuntu 22.04 / Debian 12 | Ubuntu 24.04 or newer |
| Disk space | 15 GB | 30 GB |
| Memory | 4 GB | 8 GB |
| Processor | 2 core | 4 core |

Suitable for: **server, VPS, mini PC**, or a computer that stays on.

---

## How to use

```bash
git clone <URL-REPO-ANDA>
cd hermes-custom
./install.sh
```

Done. Follow the 4 steps that appear on screen (about 5 minutes).

---

## Options

```bash
./install.sh --test           # check the system only, change nothing
./install.sh --no-docker      # without WhatsApp & search (lightweight)
./install.sh --no-stt         # without local voice (saves memory)
```

---

## What the installer does

### Stage 1 — Check the system
```
✓ Operating system & architecture
✓ Admin access (sudo)
✓ Disk space (minimum 15 GB) & memory
✓ Internet connection
✓ Ports that might conflict
```

### Stage 2 — Base components
```
✓ apt packages: git, python3, rsync, ffmpeg, xvfb, x11vnc, novnc, etc.
✓ Docker + docker compose
✓ Hermes Agent
✓ Python environment (venv)
✓ Camoufox (~1.3 GB) — anti-detect browser
✓ Tailscale
```

### Stage 3 — Applications & configuration
```
✓ config.yaml (local voice, search, browser)
✓ Local SearXNG (search without API key) — port 8080
✓ Local faster-whisper voice (model 'medium')
✓ Evolution API (WhatsApp) — port 8081
✓ Remote web view (noVNC) — port 6080
```

### Stage 4 — Automation
```
✓ System-level autostart (systemd)
✓ Automatic backup 2x a day
✓ Google tools (Sheets/Drive/Docs)
```

### Stage 5 — Your turn
```
1. Tailscale   — connects automatically (if there's a key from the technician)
2. Nous Portal — log in once (REQUIRED)
3. WhatsApp    — scan the QR (self-chat mode)
4. Google      — OAuth login
```

---

## Headless server (no screen)

This installer is designed for servers without a monitor. Things to note:

**Nous Portal needs a browser.** If your server has no screen:

```bash
# Method 1 — use remote view (browser on the server, viewed from outside)
~/.hermes/remote-view/remote-view.sh start
~/.hermes/remote-view/remote-view.sh password
# then open http://<IP-tailscale>:6080/vnc.html

# Method 2 — paste the API key manually
hermes setup model
```

**Scanning the WhatsApp QR** also needs a display. Use the remote view above.

---

## Frequently used commands

```bash
# Robot
hermes                                   # start chatting
hermes setup --portal                    # log in to Nous Portal
hermes setup tools                       # log in to Google
sudo systemctl status hermes-gateway     # check robot status
sudo systemctl restart hermes-gateway    # restart
journalctl -u hermes-gateway -n 50       # view robot logs

# Remote view
~/.hermes/remote-view/remote-view.sh start
~/.hermes/remote-view/remote-view.sh stop
~/.hermes/remote-view/remote-view.sh status
~/.hermes/remote-view/remote-view.sh password

# Docker
docker ps                                # see what's running
docker logs evolution_api                # WhatsApp logs

# Backup
ls -lh ~/backups_agent/                  # backups
cat ~/.hermes/logs/backup.log            # backup log
```

---

## After installation — health check

```bash
# 1. Is the robot running?
systemctl is-active hermes-gateway
# expected: active

# 2. Are the containers running?
docker ps --format '{{.Names}}\t{{.Status}}'
# expected: evolution_api, evolution_postgres, evolution_redis, searxng

# 3. Is search alive?
curl -s -o /dev/null -w "%{http_code}\n" http://localhost:8080/
# expected: 200

# 4. Is local voice ready?
~/.hermes/hermes-agent/venv/bin/python -c "import faster_whisper; print('siap')"
```

---

## Troubleshooting

See [PEMECAHAN.md](PEMECAHAN.md) for the full list.

| Symptom | Quick fix |
|---|---|
| `Permission denied` | `chmod +x install.sh` |
| Robot doesn't run after reboot | `sudo systemctl enable --now hermes-gateway` |
| Robot replies twice | `systemctl --user status hermes-gateway` → should be **masked** |
| Installation stops halfway | Safe to rerun: `./install.sh` |
| Docker not recognized | Log out and log back in |

---

## Things to remember

```
1. Ubuntu/Debian = the best choice. Most stable & lightest.
2. Installation is safe to rerun — if it fails, run it again.
3. A human is only needed at stage 5.
4. Remote view can only be accessed via Tailscale (safe).
5. Turn off remote view when not in use:
     ~/.hermes/remote-view/remote-view.sh stop
6. For 24/7: use a computer that stays on (server/mini PC).
```
