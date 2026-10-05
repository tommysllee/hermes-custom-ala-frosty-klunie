# MacBook Guide

> **Last updated: Saturday, 03 Oct 2026 · 15:30 WIB**

A Mac can be used, **but there is one big problem** you must understand
before starting.

---

## ⚠️ Main problem: FileVault

```
If FileVault is active, the MacBook STOPS at the login screen after restart.
Before anyone logs in, background services do NOT run.

The result: your robot is OFF until someone opens the MacBook and logs in.
```

**This is not a bug — it's simply how macOS's security is designed.**

### Your options

| Option | Security | Robot running? |
|---|---|---|
| Keep FileVault + manual login each reboot | ✅ Safest | ❌ Off until login |
| Auto-login + FileVault | ⚠️ Medium | ✅ After the disk is unlocked |
| Turn off FileVault | ❌ Weak | ✅ Always on |
| **Use an Ubuntu mini PC** | ✅ Good | ✅ Always on |

**Honest recommendation:** if you need a robot that is **always on**,
a MacBook is not the choice. Use a small computer that stays on
(an Ubuntu mini PC, around Rp850,000–1,300,000).

If you still want to use a MacBook, follow the guide below.

---

## Step 1 — Install basic tools

Open **Terminal** (Cmd+Space → type "Terminal"):

```bash
# Install Homebrew (if not already installed)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install Docker Desktop
brew install --cask docker

# Open Docker once so it starts (from Applications)
```

> **Note:** macOS has neither `systemd` nor `apt`.
> The Linux installer **cannot** be run directly. This guide
> installs the components one by one.

---

## Step 2 — Install Hermes

```bash
curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
```

Then check:

```bash
hermes --version
```

---

## Step 3 — Local voice & browser

```bash
# Local voice (no API key)
python3 -m pip install --user faster-whisper

# Anti-detect browser
python3 -m pip install --user camoufox
python3 -m camoufox fetch
```

---

## Step 4 — Tailscale

```bash
brew install --cask tailscale
```

Open the Tailscale app from Applications, log in.

---

## Step 5 — Autostart with LaunchAgent

On macOS there are two kinds:

```
LaunchDaemon  -> runs BEFORE login (needs root)
                 ⚠️ does NOT run if FileVault blocks boot
LaunchAgent   -> runs AFTER user login   <- use this one
```

### Create a LaunchAgent

Create the file `~/Library/LaunchAgents/com.hermes.gateway.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.hermes.gateway</string>

    <key>ProgramArguments</key>
    <array>
        <string>/Users/NAMA_ANDA/.local/bin/hermes</string>
        <string>gateway</string>
    </array>

    <key>RunAtLoad</key>
    <true/>

    <key>KeepAlive</key>
    <true/>

    <key>StandardOutPath</key>
    <string>/tmp/hermes-gateway.log</string>

    <key>StandardErrorPath</key>
    <string>/tmp/hermes-gateway-error.log</string>

    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/Users/NAMA_ANDA/.local/bin</string>
    </dict>
</dict>
</plist>
```

Replace `NAMA_ANDA` with your Mac username (check: `whoami`).

Enable it:

```bash
launchctl load ~/Library/LaunchAgents/com.hermes.gateway.plist
launchctl start com.hermes.gateway
```

Check status:

```bash
launchctl list | grep hermes
```

---

## Step 6 — Prevent the MacBook from sleeping

```bash
# While plugged in: never sleep
sudo pmset -c sleep 0 disablesleep 1

# Check settings
pmset -g
```

> **Important:** this **only applies while plugged in**. On battery,
> the MacBook will still sleep (and the robot turns off).

### To stay on after reboot — enable auto-login

```
System Settings
  -> Users & Groups
     -> Automatically log in as: <your name>
```

**What to understand:** FileVault stays active. The boot password is still
required when first powering on. Auto-login only applies **after the disk is
unlocked** — so you still need to type the boot password once.

---

## Mac troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Robot off after reboot | FileVault holds it at the login screen | Enable auto-login (Step 6) |
| Robot off on battery | MacBook sleeps | Plug in + `pmset` |
| `launchctl load` error | Wrong path | Check `whoami` and `which hermes` |
| Docker doesn't run | Docker app not opened yet | Open Docker from Applications |
| `camoufox fetch` fails | Gatekeeper blocks it | System Settings → Privacy → Allow |
| Port 6080 already in use | AirPlay Receiver | System Settings → General → AirDrop & Handoff → turn off AirPlay Receiver |

---

## Summary: what to remember

```
1. FileVault = robot off until someone logs in. This is the MacBook's main problem.
2. Use LaunchAgent (runs after login), not LaunchDaemon.
3. Auto-login helps, but does NOT remove the need for the FileVault boot password.
4. pmset -c sleep 0 disablesleep 1 -> only applies while plugged in.
5. For an always-on robot, an Ubuntu mini PC is far more suitable
   than a MacBook — and far cheaper.
6. macOS has no systemd/apt -> the Linux installer doesn't apply.
   Install the components one by one as in the guide above.
```
