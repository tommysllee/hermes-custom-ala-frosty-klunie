# Troubleshooting

> **Last updated: Saturday, 03 Oct 2026 · 15:40 WIB**

---

## Installation

| Symptom | Cause | Fix |
|---|---|---|
| `Permission denied` when running `./install.sh` | File isn't executable | `chmod +x install.sh` |
| `requires Ubuntu or Debian` | Different OS | Windows → WSL2; Mac → see docs/MAC.md |
| `less than 15 GB of space` | Disk full | Free up space, then retry |
| `no internet` | Network problem | Check the connection, retry |
| Installation stops midway | Connection dropped | **Safe to retry** — run `./install.sh` again |
| Hermes failed to install | Connection dropped midway | `curl -fsSL https://hermes-agent.nousresearch.com/install.sh \| bash` then retry |
| Camoufox failed to download (~1.3 GB) | Slow / dropped connection | Retry; or skip it — not required |
| `docker: command not found` after install | Need to log in again | Log out and back in (docker group) |

---

## Starting the robot

| Symptom | Cause | Fix |
|---|---|---|
| Robot doesn't run after reboot | Service not enabled | `sudo systemctl enable --now hermes-gateway` |
| `Failed to start` | Wrong path | Check: `which hermes` → should be `~/.local/bin/hermes` |
| Robot runs then keeps dying | Repeated crash | See: `journalctl -u hermes-gateway -n 50` |
| Robot replies twice | Two services running | `systemctl --user status hermes-gateway` → should be **masked** |
| Did `hermes update` then it died | Service needs restarting | `sudo systemctl restart hermes-gateway` |

---

## WhatsApp

| Symptom | Cause | Fix |
|---|---|---|
| QR doesn't appear | Evolution not ready yet | Wait 30 seconds; check `docker ps` |
| QR appears but scan fails | Screen too small | Zoom in the browser display |
| Connected then disconnected | WhatsApp logged out the device | Rescan the QR |
| Can't open `:8081/manager` | Tailscale not running | `sudo tailscale status` |
| Robot doesn't reply | Self-chat mode | Send a message **to yourself**, not to someone else |

---

## Voice (talking to the robot)

| Symptom | Cause | Fix |
|---|---|---|
| Voice not recognized | Model not downloaded yet | Downloads automatically on first use — wait ~5 minutes |
| Very slow | Computer too weak | The 'medium' model is heavy; use a more powerful computer |
| Keeps getting words wrong | Accent / noise | Speak closer to the microphone, reduce background noise |
| `faster_whisper` missing | Failed to install | `~/.hermes/hermes-agent/venv/bin/pip install faster-whisper` |

---

## Remote web view (noVNC)

| Symptom | Cause | Fix |
|---|---|---|
| Page doesn't open | Not started yet | `~/.hermes/remote-view/remote-view.sh start` |
| Can't access from phone | Tailscale not running | `sudo tailscale status`, then try again |
| Password rejected | Password changed | `~/.hermes/remote-view/remote-view.sh password` |
| Black screen | Browser not launched yet | Normal — first run the app you want to see |
| Want to turn it off | Saves power & safer | `~/.hermes/remote-view/remote-view.sh stop` |

---

## Internet search

| Symptom | Cause | Fix |
|---|---|---|
| Search results empty | SearXNG not ready yet | Wait 30 seconds; check `docker ps \| grep searxng` |
| Still only using ddgs | SearXNG not running | `cd ~/searxng && docker compose up -d` |
| Port 8080 conflicts | Another app is using it | Change the port in `~/searxng/docker-compose.yml` |

---

## Google Sheets / Drive

| Symptom | Cause | Fix |
|---|---|---|
| Google login fails | Link expired | Retry: `hermes setup tools` |
| Still asks to log in every week | OAuth in Testing mode | Open console.cloud.google.com → OAuth consent → **Publish App** |
| `invalid_grant` | Token expired | Retry `hermes setup tools` |

---

## Backup

| Symptom | Cause | Fix |
|---|---|---|
| Backup doesn't run | Cron not registered | `crontab -l` → should include `backup-agent.sh` |
| Failed to send to Drive | rclone not set up | Run: `rclone config` |
| Disk full | Archives piling up | Archives >7 days old are auto-deleted; check `~/backups_agent/` |

---

## If everything fails

```bash
# 1. Read the full log
cat /tmp/agent-install-*.log

# 2. Check services
sudo systemctl status hermes-gateway
docker ps

# 3. Re-run the installer (safe to retry)
./install.sh
```

Still having trouble? Contact your technician and bring:
- The output of the commands above
- The contents of `/tmp/agent-install-*.log`
