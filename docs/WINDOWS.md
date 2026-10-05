# Windows Guide

> **Last updated: Saturday, 03 Oct 2026 · 15:25 WIB**

Windows doesn't have `systemd`. The solution: **WSL2 + Ubuntu**, then
autostart via **Task Scheduler**.

---

## Summary

```
Windows 10/11
   └── WSL2
         └── Ubuntu   <- the installer runs here (same as Linux)
Task Scheduler        <- starts the robot when Windows boots
```

---

## Step 1 — Install WSL2 + Ubuntu (once, 10 minutes)

Open **PowerShell as Administrator** (right-click → Run as administrator):

```powershell
wsl --install -d Ubuntu
```

Restart the computer if asked. After restarting, Ubuntu will open and
ask you to create a **username** + **password** — write them down carefully.

Check if it worked:

```powershell
wsl -l -v
```

It should show `Ubuntu` with `VERSION 2`.

> **If VERSION 1 appears**, change it:
> ```powershell
> wsl --set-version Ubuntu 2
> ```

---

## Step 2 — Run the installer

Enter Ubuntu:

```powershell
wsl -d Ubuntu
```

Then inside Ubuntu:

```bash
sudo apt update && sudo apt install -y git
git clone <URL-REPO-ANDA>
cd hermes-custom
./install.sh
```

> **Note:** the installer will automatically skip the systemd autostart part
> (because WSL doesn't use it). That's **normal** — autostart is handled by
> Task Scheduler in Step 3.

---

## Step 3 — Autostart via Task Scheduler

So the robot starts on its own when Windows is turned on.

### Method 1 — Via PowerShell (fast)

Open **PowerShell as Administrator**:

```powershell
$user = "USERNAME_UBUNTU_ANDA"

schtasks /create /tn "AI Agent Gateway" `
  /tr "wsl.exe -d Ubuntu -u $user -e bash -lc '~/.local/bin/hermes gateway'" `
  /sc onstart /ru SYSTEM /rl HIGHEST /f
```

Replace `USERNAME_UBUNTU_ANDA` with your Ubuntu username.

Check if it worked:

```powershell
schtasks /query /tn "AI Agent Gateway"
```

### Method 2 — Via the GUI (if you prefer clicking)

```
1. Open Task Scheduler (search in the Start Menu)
2. Click "Create Task..." (NOT "Create Basic Task")
3. General tab:
     Name        : AI Agent Gateway
     ✅ Run whether user is logged on or not
     ✅ Run with highest privileges
     Configure for: Windows 10 / 11
4. Triggers tab -> New...
     Begin the task: At startup
     OK
5. Actions tab -> New...
     Action : Start a program
     Program: C:\Windows\System32\wsl.exe
     Arguments: -d Ubuntu -u USERNAME_UBUNTU_ANDA -e bash -lc "~/.local/bin/hermes gateway"
6. Settings tab:
     ✅ Allow task to be run on demand
     ✅ If the task fails, restart every: 1 minute
7. OK -> enter your Windows password
```

---

## Step 4 — Remote web view & Tailscale from Windows

This is the part that **most often fails** if you're not careful.

### The problem

```
WSL has its "own address" (e.g. 172.x.x.x) that is NOT visible
from the outside network. Tailscale in WSL also often doesn't run smoothly.
```

### The solution — run Tailscale on WINDOWS, not in WSL

```powershell
# In PowerShell (Administrator)
winget install --id Tailscale.Tailscale
```

Log in to Tailscale via its Windows app (appears in the system tray).

### Bridge the noVNC port from WSL to Windows

Create a file `jembatan-port.ps1` in Windows:

```powershell
# Forward port 6080 from WSL to Windows (so it can be accessed via Tailscale)
while ($true) {
    $wslIp = (wsl -d Ubuntu hostname -I).Trim().Split()[0]
    Write-Host "Meneruskan http://$wslIp:6080 -> localhost:6080"
    netsh interface portproxy delete v4tov4 listenport=6080 listenaddress=0.0.0.0 | Out-Null
    netsh interface portproxy add v4tov4 listenport=6080 listenaddress=0.0.0.0 connectport=6080 connectaddress=$wslIp
    Start-Sleep -Seconds 60
}
```

Run it once at boot (add it to Task Scheduler with the "At startup"
trigger, same as Step 3).

Then open from phone/laptop:

```
http://<IP-Tailscale-Windows>:6080/vnc.html
```

---

## Windows troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `wsl --install` fails | Virtualization is off in BIOS | Enable VT-x/AMD-V in BIOS |
| Installer says "autostart skipped" | Normal in WSL | Continue to Step 3 |
| Robot doesn't run after reboot | Task Scheduler not created yet | Repeat Step 3 |
| Task Scheduler error `0x1` | Wrong user/path | Check Ubuntu username: `wsl -d Ubuntu whoami` |
| noVNC can't be opened | Port not bridged yet | Run `jembatan-port.ps1` |
| Tailscale doesn't run in WSL | Normal | Install Tailscale on **Windows**, not WSL |
| WSL slow / eats memory | Default memory limit | Create `C:\Users\<YourName>\.wslconfig` → see below |

### Limit WSL memory (if the computer becomes slow)

Create the file `C:\Users\<NAMA-ANDA>\.wslconfig`:

```ini
[wsl2]
memory=6GB
processors=4
swap=2GB
```

Then restart WSL:

```powershell
wsl --shutdown
```

---

## Things to remember

```
1. Windows needs WSL2 — there is no better way.
2. Autostart on Windows = Task Scheduler (not systemd).
3. Tailscale is installed on WINDOWS, not in WSL.
4. noVNC needs a port bridge (portproxy) from WSL to Windows.
5. A Windows laptop that is often closed will turn the robot off.
   If you need something always on, use a computer that stays on.
```
