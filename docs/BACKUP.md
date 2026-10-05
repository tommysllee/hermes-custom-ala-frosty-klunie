# FULL BACKUP & RESTORE

> Last updated: 4 Oct 2026 · 09:15 WIB

Your robot automatically backs up **its entire self** twice a day.
This guide explains what is copied, where it is stored, and how
to restore it if the computer breaks.

---

## 1. WHAT IS BACKED UP

Everything. Not just the settings:

```
ROBOT'S BRAIN
  • skills/          its capabilities
  • cron/            its scheduled tasks
  • templates/       ready-to-use examples
  • knowledge/       its knowledge material

ROBOT'S CHARACTER
  • SOUL.md          its personality
  • profiles/        all profiles (if there are several)
  • config.yaml      all of its configuration
  • .env             its access keys (secret!)

WORK TOOLS
  • scripts/         its helper scripts
  • hooks/           its automatic triggers
  • remote-view/     the remote-screen helper tool

ITS MEMORY
  • sessions/        conversation history
  • state.db         the memory database
  • session_search.db the search index
```

**Why complete?** If only the settings were backed up, the robot would have
to be trained from scratch. This way, a new robot immediately becomes like
it was before — just like restoring a phone's entire contents from a backup.

---

## 2. WHERE IT IS STORED

```
~/hermes-backup/                        ← on your computer
   hermes-snapshot-20261004_0900.tar.zst
   hermes-snapshot-20261004_0900.CATATAN.txt

Google Drive (if set up)
   gdrive:hermes-backup/                ← in the cloud, safe if the computer breaks
```

⚠️ **The backup is deliberately stored OUTSIDE the `~/.hermes` folder.**
If it were stored inside, the backup would also be lost when `.hermes` breaks.
That would be the same as having no backup.

---

## 3. SCHEDULE

```
02:00 UTC = 09:00 WIB     morning backup
14:00 UTC = 21:00 WIB     evening backup
14:00 UTC = 21:00 WIB     daily maintenance (cleanup)

Backups older than 30 days are deleted automatically (to save space)
```

---

## 4. HOW TO RESTORE (TWRP-STYLE)

First save the `full-backup.sh` file outside the `.hermes` folder,
for example in the home folder. Then:

```bash
cd ~
bash full-backup.sh --pulihkan ~/hermes-backup/hermes-snapshot-XXX.tar.zst
```

Or directly with tar:

```bash
cd ~
tar --zstd -xf ~/hermes-backup/hermes-snapshot-XXX.tar.zst
```

**What happens:**

```
1. Your old system is moved to  ~/.hermes-lama-<tanggal>
   (not deleted — if the restore fails, you can still go back)
2. The backup contents are restored to   ~/.hermes
3. You are asked to run:      hermes gateway restart
```

**If something goes wrong:** restore the old system —

```bash
rm -rf ~/.hermes
mv ~/.hermes-lama-<tanggal> ~/.hermes
hermes gateway restart
```

---

## 5. CONNECTING TO GOOGLE DRIVE

A backup only on the computer is still risky: if the computer breaks or is
stolen, the backup is lost too. Connecting to Google Drive
solves this.

### Step 1 — Create an app in Google Cloud

```
1. Open  https://console.cloud.google.com/
2. Create a new project (for example: hermes-backup)
3. Open   https://console.cloud.google.com/apis/library/drive.googleapis.com
   → click ENABLE
4. Open   https://console.cloud.google.com/apis/credentials
   → Create Credentials → OAuth client ID
   → Application type: Desktop app
   → Create
5. Download the JSON → move it to:  ~/.config/rclone/gdrive.json
```

### Step 2 — Connect

```bash
rclone config
```

Follow:

```
n                          → new remote
name: gdrive               → its name must be "gdrive" (lowercase)
Storage: drive             → choose Google Drive
client_id: (leave empty)
client_secret: (leave empty)
scope: 1                   → Full access
root_folder_id: (leave empty)
service_account_file: (leave empty)
Edit advanced config: n
Use web browser: n         → because this is a server
   → a link will appear; open it on your phone/computer
   → allow → copy the code → paste it in the terminal
Configure as Shared Drive: n
y                          → save
q                          → quit
```

### Step 3 — Test

```bash
rclone listremotes                      # should show: gdrive:
bash ~/.hermes/scripts/full-backup.sh
rclone ls gdrive:hermes-backup/         # should show the archives
```

---

## 6. CONNECTING TO GITHUB

With this method the backup is **versioned** — you can go back to any point.

### Step 1 — Create a GitHub token

```
1. Open  https://github.com/settings/tokens?type=beta
2. Generate new token (fine-grained)
3. Name: hermes-backup
4. Expiration: 90 days (or No expiration if you really want)
5. Repository access: Only select repositories
   → select your backup repo (must be created first)
6. Permissions → Repository permissions:
       Contents .............. Read and write
       Administration ......... Read and write
7. Generate token → COPY (it only appears once)
```

### Step 2 — Store safely & connect

```bash
mkdir -p ~/.hermes/kredensial
printf '%s' '<token Anda>' > ~/.hermes/kredensial/github-backup.token
chmod 600 ~/.hermes/kredensial/github-backup.token

# configure git so it doesn't ask for a password again
git config --global credential.helper store
```

> **If you use Perplexity/AI to guide you:**
> ask that AI to look at that GitHub page first
> (`https://github.com/settings/tokens?type=beta`) so the steps match
> the current interface — the GitHub page changes often. The basic pattern to
> understand: choose the **repository** first → then **permissions** → then generate.

---

## 7. INSTRUCT YOUR AI

If you use an AI to guide you, paste this text:

```
Back up my Hermes system to Google Drive and/or GitHub.

Before guiding, LOOK FIRST at these pages on the internet so the
steps are accurate (pages change often):
  • https://rclone.org/drive/                    (how to use rclone + Drive)
  • https://github.com/settings/tokens?type=beta (how to create a GitHub token)
  • https://console.cloud.google.com/apis/credentials (how to do OAuth)

Then guide me step by step. Don't guess the structure.
Always state the time in WIB when giving times/schedules.
```

---

## 8. WHAT YOU NEED TO KNOW

```
✅ Complete backup       → the robot can come back fully intact
✅ Stored outside        → safe if .hermes breaks
✅ To Drive              → safe if the computer is lost
✅ To GitHub             → can go back to any point

⚠️ .env contains secret keys → keep the Drive remote as PRIVATE
⚠️ Backups older than 30 days are deleted automatically → if you need to keep them longer, change the schedule
```

---

## 9. IF BACKUP FAILS

```bash
# view the log
tail -50 ~/.hermes/logs/full-backup.log

# test manually
bash ~/.hermes/scripts/full-backup.sh

# check disk space
df -h ~
```

Most common problems:

```
"zstd not available"   → sudo apt-get install -y zstd
"rclone not found"     → sudo apt-get install -y rclone
"Drive not set up"     → repeat section 5 above
```
