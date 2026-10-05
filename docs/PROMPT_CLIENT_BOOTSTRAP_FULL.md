# PROMPT FOR AI AGENT — Client Bootstrap (Full Version)

> **Last updated: Monday, 05 Oct 2026 · 17:30 WIB**
>
> **What this is:** a prompt you paste into Hermes Agent on a client machine **after**
> Hermes is already installed and a model is already selected. Hermes then configures
> the whole machine by itself — no manual setting-up by the client.
>
> **Not the same as** `docs/PROMPT_FOR_AI_AGENT.md` (that one builds THIS repo).
>
> **How to use it:**
> 1. Install Hermes on the client machine:
>    - Linux / macOS / WSL2 → `curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash`
>    - Windows → `iex (irm https://hermes-agent.nousresearch.com/install.ps1)`
> 2. Run `hermes model` → pick the provider and model (recommended: OpenRouter + a strong model for this one-time setup).
> 3. Copy **everything between the two markers below** and paste it into Hermes as ONE message.
> 4. Let it run. It only asks for input at the steps that genuinely need the client's own login.
>
> **Or, if the file is already on the machine (Linux/macOS):**
> ```bash
> hermes chat -q "$(curl -fsSL https://raw.githubusercontent.com/tommysllee/hermes-custom-bisa-whatsapp-bisa-sheets-bisa-autobackup-autostart-bisa-ssh-tailscale-remote-webview/main/docs/PROMPT_CLIENT_BOOTSTRAP.txt)"
> ```
>
> **Security note:** this prompt contains a Tailscale auth key. Anyone who reads this
> file can join the tailnet with it. Rotate (revoke) that key in the Tailscale console
> after the first client machine has joined, and prefer the key-free tag mechanism
> where possible.

---

## — start copying from here

```
TASK
Configure this machine completely so the client can use it immediately without
setting anything up by hand. This machine ALREADY has:
  - Hermes Agent installed via the official Nous Research command
  - A provider and model already selected
Do NOT install Hermes again and do NOT change the model. Your job is everything else.

OUT OF SCOPE (never do these)
  - Do NOT run `hermes model` or `hermes setup` to choose a model.
  - Do NOT change model.default or model.provider.
  - Do NOT reinstall Hermes from scratch. The official installer may be used ONLY as a
    repair path, and only if `hermes doctor` finds a problem that cannot be fixed another
    way:
      Linux/macOS/WSL2: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --non-interactive
      Windows:          iex (irm https://hermes-agent.nousresearch.com/install.ps1) -NonInteractive
    It is idempotent, so it is safe to re-run — but it is not the first step.
  - For heavy mechanical work you may use delegate_task with the model already configured
    under delegation.*, but never switch the main model.

HARD RULES (must not be broken at any point)
 1. DO THE WORK, DO NOT JUST DESCRIBE IT. Every step is executed with a tool, verified
    with real output, then reported. Never write "next I will..." without executing.
 2. BE OS-ADAPTIVE, NEVER ASSUME. Detect: OS, distro, arch, init system
    (systemd / launchd / Task Scheduler / none), active user, sudo rights, headless or
    has a display, RAM and free disk. Use the correct package manager (apt / dnf /
    pacman / zypper / brew / winget / pkg). If a feature has no equivalent on that OS,
    use its native counterpart (launchd / LaunchDaemon / Task Scheduler) and note the
    difference. Never fail the whole job over one missing package.
 3. NON-INTERACTIVE AND IDEMPOTENT. Every command automatic (-y, --yes,
    DEBIAN_FRONTEND=noninteractive, -NonInteractive). Every script safe to re-run
    without damaging anything.
 4. VERIFY, DO NOT TRUST THE LOG. A step counts as successful ONLY when proven:
    `command -v <bin>`, `systemctl is-active`, a curl health check, or re-reading the
    file that was just written. If it fails, fix it yourself first (at least 2 different
    approaches: different package manager, different source, different method), and only
    report it as a blocker afterwards. Never report success for anything unproven.
 5. SECRETS GO IN `.env` ONLY. Tokens and passwords never go into config.yaml, are never
    retyped into chat, never echoed to the screen. Non-secret settings go into
    config.yaml via `hermes config set`. NEVER hand-edit config.yaml — one wrong indent
    breaks the gateway.
 6. NEVER ASK FOR A PASSWORD IN CHAT. If sudo or an OTP is needed, have the user type it
    at the masked prompt on their own machine, or use the remote web view (step 8.2).
 7. ONE SOURCE OF TRUTH. Before guessing how Hermes does something, read
    https://hermes-agent.nousresearch.com/docs/llms.txt (the index of all official
    docs). When in doubt, check the docs — do not improvise.
 8. LANGUAGE AND STYLE: reply in the user's language (default Indonesian). Short,
    direct, no filler.
 9. TIME AND TIMEZONE: every time you report to the user, use the user's local time
    (section 7.5). When talking about cron, give both clocks: the raw UTC and the local
    time.
10. NEVER DELETE, NEVER SUMMARIZE — ONLY REPLACE AND ADD. This applies to memory, the
    user profile, work documents, and client config files (section 7.2).

PHASE 0 — RECON (required, about 2 minutes)
Collect and record as a baseline:
  - OS, distro, version, architecture, kernel
  - active user; is sudo available and passwordless? (`sudo -n true`)
  - init system: systemctl / launchctl / none
  - headless or has a display ($DISPLAY, /dev/dri)
  - RAM and free disk (if RAM < 2 GB, the `medium` STT model and Xvfb/noVNC may be too
    heavy: drop to `small` and note why)
  - Hermes: `command -v hermes`, `hermes --version`, `hermes doctor`,
    `hermes config get model` (record it, DO NOT change it)
  - internet connection and DNS
From this, write the per-OS plan first, then execute it.

PHASE 1 — BASE TOOLS (auto-install, non-interactive)
Install everything available on this OS; anything unavailable gets skipped and its
reason recorded.
  - Core: git, curl, wget, tar, unzip, ca-certificates, build-essential/base-devel,
    pkg-config, jq, ripgrep, openssh-client, openssh-server, rsync, cron
  - Python & Node: python3, python3-venv, python3-pip, pipx, nodejs, npm
  - Media & browser automation: ffmpeg, xvfb, x11vnc, novnc + websockify, fonts
    (dejavu, noto)
  - Sync & network: rclone, iproute2 (`ip`), iw, rfkill, netplan.io (Ubuntu/Debian
    only), network-manager if needed, dnsutils, traceroute, socat, lsof
  - Utilities: sqlite3, zstd, tmux, htop/btop, ncdu, gpg, age (for encrypting backups)
Rule: verify each package with `command -v <bin>`. Final output = a table of
package -> OK / SKIPPED(reason).
Install optional or release-specific packages on their own package-manager call, so one
missing package cannot take down the whole core set.

PHASE 2 — VERIFY HERMES (not a reinstall)
  1. `hermes --version` and `hermes doctor` — fix EVERY warning (dependencies, python,
     browser tools, etc).
  2. Make sure ~/.local/bin is on the user's shell PATH (~/.bashrc / ~/.zshrc /
     equivalent), and placed ABOVE the non-interactive guard so agent commands do not
     hang.
  3. Only if something is broken beyond other repair: run the official installer in
     non-interactive mode as a repair (see OUT OF SCOPE), then `hermes doctor` again
     until clean.
  4. Do NOT run `hermes model` and do not change the model. Just record the active
     provider and model for the report.

PHASE 3 — DOCKER / COMPOSE / VENV / SEARXNG
  1. Docker Engine + Compose plugin from the official repository (not the distro's
     outdated package). Add the user to the `docker` group and TELL the user to
     log out and back in (or use `newgrp docker`) — do not silently assume it is active.
     Verify with `docker run --rm hello-world` actually running.
     Windows/macOS: use Docker Desktop if available; if not, note it and continue.
  2. Ready-to-use Python venv: `python3 -m venv ~/.venvs/main` plus pip/setuptools/wheel
     upgrade. Record how to activate it.
  3. Local SearXNG (free search engine, no API key) via docker compose in ~/searxng/:
     image searxng/searxng, port 8080, restart: unless-stopped. Verify with curl until
     the instance actually returns results (not just a container showing "Up").
  4. `ddgs` (DuckDuckGo Search) in the venv for scripts/fallback: `pip install ddgs`.
     Note: the valid Hermes web-search backends are searxng / firecrawl / exa / tavily /
     parallel / perplexity / keenable. `ddgs` is used as a library inside scripts, not
     as a backend.

PHASE 4 — HERMES TOOL CONFIGURATION
Set everything with `hermes config set`, then verify each value with `hermes config get`.
  1. Web search — local SearXNG + keyless fallback:
     - web.backend = searxng
     - web.keyless_fallback = true, web.keyless_rescue = true
     - SEARXNG_URL=http://localhost:8080 in ~/.hermes/.env
  2. Browser automation — Camofox (anti-detect, local):
     - browser.cloud_provider = camofox
     - browser.camofox.managed_persistence = true (cookies and logins survive restarts)
     - Make sure the browser toolset is enabled. Note: Camofox exposes NO CDP, so it
       uses the built-in browser tools (not browser_exec) — that is expected.
  3. Image analysis (vision): enable it automatically using whatever provider/model is
     available from the user's chosen model. If it needs a separate key, offer free
     options first, then ask for the key.
  4. STT (voice to text) — local, medium model:
     - stt.enabled = true, stt.provider = local, stt.local.model = medium
     - Download the faster-whisper model NOW. Do not make the user wait the first time
       they send a voice note.
  5. Computer use: `hermes tools enable computer_use`; make sure the driver is installed
     (`hermes pm install cua-driver` if needed).
  6. Required toolsets enabled: web, search, browser, terminal, file, code_execution,
     vision, memory, skills, session_search, cronjob, delegation, todo, clarify, tts.
  7. Timezone (section 7.5): timezone = Asia/Jakarta (or the user's real zone), plus
     HERMES_TIMEZONE in .env.
  8. Run `hermes doctor` again — it must be clean before continuing.

PHASE 5 — PERMANENT RULES (binding FOREVER — write them to memory AND SOUL.md/AGENTS.md)
Store these as standing policy so they also apply in future sessions, not just today.

  7.1 AUTO-CATEGORIZE MEMORY (REQUIRED)
  Every time you learn something about the boss/user — their style, their preferences,
  AND the INTENT behind that style or preference — store it immediately in the RIGHT
  chapter, and as close as possible to the related sub-chapter. Example mapping:
    - Technical/infra/server -> the infrastructure chapter
    - Language, greetings, pronouns -> the communication chapter
    - File rules, report format, timestamps -> the presenting-results chapter
    - Message templates for third parties -> the templates chapter
  If no chapter fits yet, CREATE a new chapter. Never attach a communication rule to
  the infra chapter, or vice versa.

  7.2 NO DELETE / NO SUMMARIZE — ONLY REPLACE AND ADD (REQUIRED)
  - NEVER delete the contents of memory, the user profile, or work documents.
  - NEVER summarize in a way that loses information.
  - ONLY allowed: REPLACE (swap one entry for a more correct/complete version — keep
    whatever is still relevant from the old entry inside the new one) and ADD a new
    entry.
  - If memory is full: MERGE overlapping entries via REPLACE, never by discarding
    entries.
  - After any major memory change, briefly tell the user what was added or replaced.

  7.3 AUTOSTART + AUTOLINGER + AUTO-RETRY (REQUIRED)
  The Hermes gateway must run at the SYSTEM level so it can linger:
  - Linux: `sudo hermes gateway install --system` -> `systemctl enable --now
    hermes-gateway` -> `sudo loginctl enable-linger <user>` (linger is REQUIRED: it keeps
    running even after the user logs out or SSH disconnects)
    - Do NOT use `hermes gateway install` (user service) — two gateways fight over the
      token and corrupt state.db.
    - If a USER unit `hermes-gateway.service` exists, MASK it:
      `systemctl --user mask hermes-gateway` — so `hermes update` cannot start it again.
    - Restart policy: Restart=always with a small RestartSec.
  - macOS: LaunchDaemon with KeepAlive=true (a daemon runs without a user login).
  - Windows: Task Scheduler, trigger "At startup", option "Run whether user is logged on
    or not".
  - WITHOUT ASKING FOR A PASSWORD AGAIN: automation runs as the service user, with
    `sudo -n` (NOPASSWD) only for the commands that genuinely need it, and no password
    prompt anywhere on the startup path.
  - Verify: restart the service / log out and back in / reboot -> `systemctl is-active
    hermes-gateway` plus `hermes gateway status` must both come back on their own.

  7.4 AUTOUPDATE + AUTOCLEAN + AUTORESTART (REQUIRED)
  Create exactly ONE cron job (never two overlapping ones) that runs every END OF DAY
  WIB (e.g. 23:30 WIB = 16:30 UTC):
    1. Clean junk: apt autoremove -y / dnf autoremove -y / pacman -Sc --noconfirm,
       `docker system prune -f` (NEVER touch mounted volumes), remove old caches and
       temp files, delete logs older than N days, `journalctl --vacuum-time=14d`.
    2. Update the system and Hermes: OS package update (non-interactive, NO auto-reboot),
       then `hermes update`.
    3. After ANY update -> restart the gateway: `systemctl restart hermes-gateway`, then
       verify with `hermes gateway status`.
  - Set updates.pre_update_backup = quick so every update has a small snapshot first.
  - Everything is logged to ~/logs/hermes-daily-maintenance.log and a success/failure
    summary is sent to the user's chat.
  - System cron uses UTC -> ALWAYS write the local-time conversion in the report.

  7.5 AUTOTIMEZONE — SPEAK IN THE USER'S TIMEZONE (REQUIRED)
  - Set the Hermes timezone to the user's zone (default Asia/Jakarta, WIB = GMT+7) and
    set the OS timezone too, so logs and schedules agree.
  - Every time you mention a time, use the user's local clock. When you mention cron or
    UTC, ALWAYS add the offset — example: "20:00 UTC (03:00 WIB the next day)". The user
    must be able to picture it without doing arithmetic.
  - Every file or text handed to the user MUST carry a "last updated" date and local time
    in its header.

PHASE 6 — REMOTE ACCESS: SSH + VNC + TAILSCALE (auto-enable, no expiry)
  1. SSH: install and enable sshd (`systemctl enable --now ssh`), confirm it listens and
     login works. Do not disable key authentication.
  2. VNC / remote web view (noVNC): Xvfb + x11vnc + novnc/websockify, wrapped in a script
     and a service (~/remote-view/).
     - Service is DISABLED by default — never auto-start. It MUST be stopped after use.
     - Reachable ONLY over Tailscale (never expose it to the public internet).
     - Purpose: logins / CAPTCHAs / OTPs that cannot be automated.
  3. Tailscale — join the TSL tailnet automatically, WITH NO EXPIRY:
     - Install: `curl -fsSL https://tailscale.com/install.sh | sh` (Linux) / official
       package (macOS) / `winget install tailscale.tailscale` (Windows).
     - MAIN METHOD (permanent no-expiry) — join as a TAGGED DEVICE:
         sudo tailscale up --auth-key=<AUTH_KEY> --advertise-tags=tag:dipasangintsl \
           --hostname=<client-name> --accept-routes
       A tagged device has key expiry DISABLED by default -> no need to log in again, ever.
     - AUTH_KEY from the owner:
       tskey-auth-k2HmNVCem821CNTRL-xkb1zaVZA9JuW6TcfH8u8J7PKaoApy8Vd
       This key is reusable. SECURITY NOTE: once the client machine has joined, the owner
       should ROTATE this key in the Tailscale console (Keys -> revoke), because the key
       has been written into text.
     - If the key fails or has expired: DO NOT stay silent — first run interactive
       `tailscale up --advertise-tags=tag:dipasangintsl`, tell the user to contact the
       technician for a new key, and record it as a blocker.
     - Verify: `tailscale status` (the machine appears on the tailnet) plus
       `tailscale ip -4` (it gets a 100.x address). Make sure the `tailscaled` service is
       enabled, and turn on Tailscale auto-update if available.
  4. Expected result: once Tailscale is done and the machine is online, the client machine
     is IMMEDIATELY on the owner's tailnet — SSH and the remote view are reachable by the
     owner from anywhere, with nothing for the client to configure, and no expiry.

PHASE 7 — AUTOGUIDE: SOUL, PERSONALITY, WORKFLOW (guided dialogue)
Guide the user ONE step at a time, never in bulk:
  1. Log in and connect Nous Portal (if the user has a subscription):
     `hermes setup --portal` — explain that one OAuth covers the model plus the tool
     gateway. If they do not have one, move on. DO NOT change the already-chosen model.
  2. Capture the user's "personality text" from another AI (especially ChatGPT, Gemini,
     Claude):
     - Ask the user to paste that AI's answer: speaking style, values, how they make
       decisions, what they dislike, how they want to be helped.
     - Shape it into ~/.hermes/SOUL.md (primary identity: voice, tone, stance) and
       AGENTS.md (real work rules: report format, prohibitions, procedures).
     - DO NOT summarize the personality text the user provides — store it whole, only
       tidy the structure.
     - Show the SOUL.md draft to the user before saving it.
  3. Ask for the complete procedure/workflow in the field the AI should help with:
     - Ask: what field, the daily/weekly routine, what inputs normally arrive, what
       outputs are expected, who receives the results, what must never be done.
     - Turn the answers into: (a) memory entries, (b) a skill named `prosedur-kerja-klien`
       with the standard steps, (c) output templates (reports/messages/documents) matching
       the user's preferences.
     - Store them following 7.1 and 7.2.
  4. Connect WhatsApp: via `hermes gateway setup` -> WhatsApp / WhatsApp Cloud API. If a
     QR scan or OTP is needed, use the remote web view (step 6.2), walk the user through
     it, then STOP the remote view service afterwards.
  5. Connect the Google API:
     - Guide them through creating credentials in the Google Cloud Console: OAuth consent
       screen -> Credentials -> OAuth Client ID -> download the JSON. Scopes as needed
       (Gmail / Calendar / Drive / Sheets).
     - Store the JSON in a safe location (not a public folder) and record it in .env.
     - IMPORTANT: before guiding them, BROWSE the live page first to confirm today's
       structure and button names (console.cloud.google.com -> APIs & Services ->
       Credentials). Google's UI changes often — guide from what is actually on screen,
       not from memory.
     - Remind them: "Testing" app mode kills the refresh token every 7 days -> recommend
       publishing the app (or production mode).
  6. Log into Google in the Web View: open the Google login page in the remote web view
     (headless browser), walk the user through until the login completes, then close the
     remote view service.

PHASE 8 — BACKUP & RESTORE (TWRP-style) + Google Drive / GitHub
Offer this at the end of the install, and guide it to actually running if the user agrees.
  1. Full Hermes backup (one command, consistent snapshot even while the gateway runs):
     - `hermes backup` -> produces ~/hermes-backup-<timestamp>.zip
     - Contents: config.yaml, .env, auth.json, all profiles, memory, skills, cron,
       sessions, templates, knowledge, scripts — credentials INCLUDED.
     - Restore on a new machine, TWRP-style: install Hermes -> `hermes import <file.zip>`
       -> everything comes back exactly (profiles, config, settings, access, sessions,
       state.db).
     - `hermes profile export` moves only ONE profile (without credentials).
  2. Detail layers that must also be saved (and verified to actually exist, not merely
     "invoked"):
     - skills, cron/jobs, templates, knowledge, scripts
     - profile, config, settings, access/credentials (keep in a separate encrypted layer)
     - sessions + state.db -> ALWAYS use the SQLite backup API / Connection.backup(),
       NEVER a raw `cp` (WAL can corrupt it)
     - supporting system files: tailscaled.state (root-owned -> `sudo cp` then chown it
       back), docker volumes (via `docker cp`), browser profiles (without large caches),
       systemd units plus linger state
     - If the systemd units and linger state are not included, on the new machine the
       backup will silently stop running — so the units, the crontab, and the backup
       script itself MUST be inside the archive.
  3. Backup destination: Google Drive and/or GitHub — ask which one they want:
     - Google Drive (rclone): `rclone config` -> Google Drive remote. Upload with
       `rclone copy`; rotate old archives by their REAL timestamp (`rclone lsjson` +
       ModTime), never by name order (that deletes the newest archive).
     - GitHub: a private repo plus `gh auth login` or a fine-grained token. Make sure
       .gitignore does not leak .env or tokens.
     - Security: a backup containing credentials must be ENCRYPTED first (age / gpg /
       AES-256) before upload. NEVER store the encryption passphrase in the same backup
       folder — that voids the encryption.
  4. Guide them through getting the API/token — after checking the internet first:
     - Before guiding, BROWSE the official page so the steps and page layout you guide
       through are actually accurate:
         Google API/Cloud -> console.cloud.google.com (APIs & Services -> Credentials /
           OAuth consent screen)
         Google Drive via rclone -> rclone.org/drive
         GitHub token -> github.com/settings/tokens (fine-grained token)
     - Guide from what is really on the page now, and name the actual buttons. If the UI
       on screen differs from old documentation, follow the screen and note the
       difference.
  5. Schedule automatic backup: daily or weekly cron (the user's local time, with the UTC
     version written too), with logging plus a success/failure notification to the chat.

DEFINITION OF DONE (everything must be PROVEN, not "should be")
  [ ] Base tools installed — table of package -> OK / SKIPPED(reason)
  [ ] Hermes validated: `hermes doctor` clean, version recorded, MODEL NOT CHANGED
  [ ] Docker + compose working (`hello-world` succeeds), venv ready
  [ ] Local SearXNG running, SEARXNG_URL set, web search actually returns results
  [ ] Camofox is the browser provider and the browser tool has opened a real web page
  [ ] Vision / image analysis enabled and tested on an actual image
  [ ] Local STT `medium` enabled and the model already downloaded
  [ ] Computer use enabled and the driver installed
  [ ] timezone = the user's zone, tested with `date`
  [ ] The memory rules (7.1, 7.2) are written into memory AND SOUL.md/AGENTS.md
  [ ] Gateway at SYSTEM level, linger=yes, Restart=always, tested via service restart /
      logout-login
  [ ] The USER unit (if any) is masked
  [ ] The daily maintenance cron exists (only one, not duplicated) and was ACTUALLY RUN
      once manually with success
  [ ] SSH enabled; remote view (noVNC) can start, is reachable over Tailscale, and has
      been STOPPED again
  [ ] `tailscale status` shows the machine as a tagged device (tag:dipasangintsl) with
      key expiry disabled
  [ ] SOUL.md filled from the user's personality text (whole, not summarized)
  [ ] The user's field workflow is now memory + skill + templates
  [ ] Messaging platform connected (Telegram/WhatsApp as the user prefers)
  [ ] Google API connected and Google login in the web view succeeded
  [ ] `hermes backup` produced successfully; Drive/GitHub offered; restore explained; if
      the user agreed, automatic backup is scheduled

FINAL REPORT (required format)
Send a SHORT report plus a table, all times in the user's local zone:
  1. Five-line summary — what worked, what did not.
  2. Results table — component -> status (OK/FAILED/SKIPPED) -> evidence (command plus
     short output).
  3. What the user must decide now — a short list (e.g. backup to Drive or GitHub;
     WhatsApp QR or Cloud API).
  4. What the owner must do — e.g. rotate the Tailscale auth key, issue a new API key.
  5. Daily usage — 5 to 10 lines: how to chat, how to send voice, how to reach it
     remotely, how to restore from backup.
  6. Header on every file/text: date plus local time of the last update.

CLOSING RULE: if a step fails and is not resolved after 2 attempts, DO NOT go quiet and
do not stop. Report the blocker plus what was already tried, then CONTINUE with the other
steps that do not depend on it. Complete the whole prompt until the checklist above is
fully filled in.
```

## — end of copy

---

## Note for the repo owner (don't copy this part)

**Files in this group (deliberately similar names so the grouping is visible):**

| File | What is inside |
|---|---|
| `docs/PROMPT_FOR_AI_AGENT.md` | Prompt to **build/edit this installer repo** (for an AI coding agent) |
| `docs/PROMPT_CLIENT_BOOTSTRAP_FULL.md` | **This file** — the client bootstrap prompt **plus** the explanation/how-to |
| `docs/PROMPT_CLIENT_BOOTSTRAP.txt` | The **bare prompt only**, no explanation — this is the one to paste or fetch |

**Why two versions:** the `.txt` is what a client (or a machine) reads and pastes, so it
must contain nothing but the prompt. This `.md` is for a human who needs to understand
what it does before handing it over.

**Why the prompt deliberately excludes installing Hermes and choosing a model:**
those two steps belong to the recipient's own machine and account, and a model choice
made by an installer is wrong more often than right. The prompt verifies and repairs the
existing install instead.

**Before publishing, re-check these names against the live Hermes docs**
(`https://hermes-agent.nousresearch.com/docs/llms.txt`), because the receiving agent
cannot tell a wrong setting name from a fact:

| Name used in this prompt | Why it is worth re-checking |
|---|---|
| `web.backend = searxng` | `ddgs` is NOT a backend — it is a script-level library |
| `browser.cloud_provider = camofox` | Camofox has no CDP, so it keeps the built-in browser tools |
| `stt.provider = local` / `stt.local.model` | provider vs model keys are separate |
| `computer_use` | the config key is the internal toolset name, not "computer use" |
| `hermes gateway install --system` | must stay system-level; the user-level unit must be masked |
| `hermes backup` / `hermes import` | the TWRP-style pair; profile export is not a full backup |
