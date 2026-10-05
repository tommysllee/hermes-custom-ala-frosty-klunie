# PROMPT FOR AI AGENT — Building an Installer Repo

> **Last updated: Saturday, 03 Oct 2026 · 12:25 WIB**
>
> How to use: copy the ENTIRE contents of this file into your AI agent (Claude Code,
> Codex, Cursor, or another agent). Then tell it: "do it according to this prompt".

---

## PROMPT — start copying from here

```
TASK
Create me a GitHub repository containing an AI agent installer that can be
run with ONE command on Ubuntu/Debian (including WSL on Windows).
I will share this repo with clients via a link.

INITIAL CONDITIONS
I already have one installer file that has been TESTED and works:
  - install.sh  (I have tested it up to the system check stage)

What I'm asking for: tidy it up into a repo worth sharing, fill in
what's missing, and prepare its structure.

--------------------------------------------------------------
SECTION 1 — REQUIRED REPO STRUCTURE
--------------------------------------------------------------

Create a structure like this:

    <repo>/
    ├── install.sh              # main installer (already exists, refine it)
    ├── README.md               # short guide for clients
    ├── LICENSE                 # MIT
    ├── docs/
    │   ├── LINUX.md            # Ubuntu/Debian + WSL guide
    │   ├── WINDOWS.md          # Windows guide (WSL2 + Task Scheduler)
    │   ├── MAC.md              # MacBook guide (LaunchDaemon + FileVault)
    │   ├── TAILSCALE.md        # tag & auth key guide (already exists)
    │   ├── GITHUB.md           # public vs private guide (already exists)
    │   ├── PESANPASANG.md      # what clients should do afterwards
    │   └── DECOMPOSITION.md    # common problems & their solutions
    ├── scripts/
    │   ├── cek-sistem.sh       # STAGE 1 part (separated from install.sh)
    │   ├── install-base.sh     # STAGE 2 part
    │   ├── install-apps.sh     # STAGE 3 part
    │   ├── pesan-akhir.sh      # STAGE 4 part
    │   └── pencatat.sh         # shared logging function
    └── templates/
        ├── config.yaml.template
        ├── searxng-compose.yml
        ├── evolution-compose.yml
        └── systemd-hermes.service

Reason for splitting: install.sh becomes easier to read, and each part can
be fixed independently.

--------------------------------------------------------------
SECTION 2 — WHAT THE INSTALLER MUST INSTALL
--------------------------------------------------------------

The order is MANDATORY as follows (important: the parts needing human
intervention go LAST):

STAGE 1 — System check (without changing anything)
  1. Detect OS & architecture. Reject if not Ubuntu/Debian
     (except WSL).
  2. Detect WSL.
  3. Check sudo/root access. If a password is needed, ask ONCE.
  4. Check disk space (minimum 15 GB) and memory.
  5. Check internet connection.
  6. Report the time zone.
  7. Check for ports that may conflict (8080, 6080, 5909, 8081, 5432).

STAGE 2 — Install basics (fully automatic)
  8. apt packages: curl, wget, git, ca-certificates, gnupg, python3,
     python3-pip, python3-venv, rsync, unzip, jq, sqlite3,
     build-essential, pkg-config, ffmpeg,
     xvfb, x11vnc, websockify, imagemagick, xdotool, novnc, ufw
  9. Docker + docker compose plugin.
 10. Hermes (official installer):
       curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
 11. Hermes Python venv.
 12. Camoufox (anti-detect browser, ~1.3 GB):
       python3 -m camoufox fetch
 13. Tailscale: curl -fsSL https://tailscale.com/install.sh | sh

STAGE 3 — Install apps & settings (fully automatic)
 14. Write ~/.hermes/config.yaml with these settings:
       stt.provider  : local          (no API key)
       stt.model     : medium         (~1.5 GB, downloaded automatically)
       stt.language  : id
       web.backend   : ddgs           (no API key)
       web.searxng.url : http://localhost:8080
       browser.backend : camoufox
       terminal.backend: local
     RULE: don't overwrite an existing config — back it up first.
 15. Local SearXNG via Docker (your own search engine, no API key),
     port 8080, restart: unless-stopped.
 16. Local STT: install faster-whisper. If RAM < 4 GB, SKIP it and
     notify. The 'medium' model downloads automatically on first use.
 17. Evolution API (WhatsApp) via Docker: postgres + redis + evolution,
     port 8081, restart: always.
 18. Remote web view: Xvfb + x11vnc + noVNC via websockify,
     bind ONLY to the Tailscale IP, random password automatically.
     Provide a script: remote-view.sh start|stop|status|password
     The service is DELIBERATELY not enabled (started manually when needed).
 19. SYSTEM-level autostart (not user-level):
       /etc/systemd/system/hermes-gateway.service
       enabled, Restart=always

STAGE 4 — The human part (LAST, in order)
 20. Nous Portal (OAuth login — free initially, no API key):
       hermes setup --portal
 21. Show the noVNC address: http://<Tailscale-IP>:6080/vnc.html
     (PLACED HERE, before the WhatsApp QR — as I requested)
 22. Tailscale up (optional, to be helped by a technician):
       sudo tailscale up --ssh
 23. WhatsApp QR via the Evolution manager on port 8081
 24. Remind them to TURN OFF the remote web view when done:
       remote-view.sh stop

--------------------------------------------------------------
SECTION 3 — RULES THAT MUST NOT BE VIOLATED
--------------------------------------------------------------

A. STAGE 4 MUST BE LAST. Things needing human intervention
   (login, QR, API key) must not block the automatic installation.

B. THE INSTALLER MUST NOT FAIL COMPLETELY if one component fails.
   Example: Camoufox fails to download -> log it, continue. SearXNG fails ->
   log it, continue. Always have a summary at the end: what succeeded,
   what needs to be retried.

C. NEVER put credentials in the repo:
   - no API keys, tokens, or passwords
   - the .env file only contains PLACEHOLDERS
   - start .gitignore with: .env, *.key, *.token

D. The Tailscale auth key (if any) comes from ENVIRONMENT VARIABLES,
   not written to a file:
     HERMES_TAILSCALE_AUTHKEY="tskey-..." ./install.sh
   If the variable is empty -> do NOT force it, just show the instructions
   `sudo tailscale up --ssh`.

E. Idempotent: safe to run AGAIN. If already installed, skip it with a
   message, don't install twice.
   (Special: the Hermes gateway — make sure there aren't two units running
   at once, that corrupts the database. One system-level unit only.)

F. Output language: clear Indonesian. Avoid technical terms without
   explanation. Clients may not understand the terminology.

G. Each step prints a clear visual indicator:
     ✓ success
     ✗ failed
     → in progress
   So clients know the process is still running.

H. Log to file: /tmp/hermes-install-<timestamp>.log
   Technical error messages go to the log, friendly messages to the screen.

I. NEVER use commands that delete user files without asking.
   NO `rm -rf` outside folders the installer created itself.

J. The installer must RUN ON WSL. Detect WSL and adapt:
   - systemd may not be active -> skip autostart, tell them how
   - Tailscale on WSL needs extra steps -> put it in the docs

--------------------------------------------------------------
SECTION 4 — WINDOWS SUPPORT (after Linux is mature)
--------------------------------------------------------------

Windows does NOT have systemd. The correct way:
  1. Use WSL2 + Ubuntu (exactly like Linux)
  2. Autostart via Task Scheduler at boot:
       schtasks /create /tn "Hermes Agent" /tr "wsl -d Ubuntu -u <user> \
         -e bash -lc 'hermes gateway'" /sc onstart /ru SYSTEM /rl HIGHEST
  3. Create install.ps1 that:
       - checks WSL2 exists; if not, installs: wsl --install -d Ubuntu
       - runs install.sh inside WSL
       - registers Task Scheduler
  4. noVNC in WSL: bind to the Windows Tailscale IP, not the WSL localhost.
     Put the port-forwarding steps in docs/WINDOWS.md

--------------------------------------------------------------
SECTION 5 — MAC SUPPORT (last)
--------------------------------------------------------------

  IMPORTANT — problems that must be handled in docs/MAC.md:
    FileVault makes the MacBook STOP at the login screen after reboot.
    LaunchDaemon does NOT run before anyone logs in. So the agent dies.

  What must be written in docs/MAC.md:
    1. How to enable auto-login:
         System Settings -> Users & Groups -> Automatically log in as
       Explain: FileVault stays active (boot password is still required);
       auto-login only applies AFTER the disk is unlocked.
    2. Prevent sleep when plugged in:
         sudo pmset -c sleep 0 disablesleep 1
    3. Use LaunchAgent (not LaunchDaemon) so it runs after login:
         ~/Library/LaunchAgents/com.hermes.gateway.plist
    4. HONESTLY: a MacBook is not a suitable machine for a 24/7 agent.
       If you need something always on, suggest an Ubuntu mini PC.

--------------------------------------------------------------
SECTION 6 — WHAT MUST BE IN README.md
--------------------------------------------------------------

The README must be short and to the point:
  1. What this is (2 sentences)
  2. How to use it (3 lines of code)
  3. What gets installed (concise list)
  4. WHAT NEEDS TO BE DONE AFTERWARDS (4 steps, in order)
  5. Brief troubleshooting
  6. Links to docs/ for details

--------------------------------------------------------------
SECTION 7 — TEST BEFORE DECLARING DONE
--------------------------------------------------------------

MUST be tested, and show the results:
  1. bash -n on ALL .sh files (syntax check)
  2. ./install.sh --test -> must run fully without changing anything
  3. Run on a clean Ubuntu (VM/container) if possible
  4. Make sure the installer can be run TWICE without errors (idempotent)
  5. Make sure there are NO credentials anywhere in the repo:
       grep -rE '(sk-[A-Za-z0-9]{24,}|ghp_|tskey-auth|AIza)' .
     -> the result must be empty

Don't say "done" before the seven things above are proven.

--------------------------------------------------------------
WHAT I ALREADY HAVE (use these, don't build from scratch)
--------------------------------------------------------------

I'm attaching:
  1. install.sh          — an early working version (test: --test passed)
  2. docs/TAILSCALE.md   — tag & auth key guide
  3. docs/GITHUB.md      — public vs private repo guide

Use all three as the basis. Refine them, don't change direction.

--------------------------------------------------------------
WHERE TO START
--------------------------------------------------------------

1. Read my install.sh, understand its flow.
2. Split it into scripts/ per SECTION 1 (don't change its behavior).
3. Fill in what's missing per SECTION 2 and 3.
4. Write README.md and the docs/ that don't exist yet.
5. Run the SECTION 7 tests, report the results as they are.
6. Only afterwards do Windows (SECTION 4), then Mac (SECTION 5).

Do Linux first until it's mature and proven.
```

## — end of copy

---

## Note for the repo owner (don't copy this part)

**Why this prompt is structured this way:**

```
1. Structure is forced explicit  -> the agent won't invent its own layout
2. Stage order is pinned         -> your request (humans last) isn't violated
3. Prohibition rules are written -> so no credentials leak into the repo
4. Required tests are mentioned  -> the agent can't say "done" without proof
5. "Use what already exists"     -> so it doesn't start over from scratch
```

**What you may need to change before sending:**
```
- <YOUR-CONTACT-DETAILS> in the end of install.sh
- Repo name (in docs/GITHUB.md)
- If you want MIT replaced with another license
```
