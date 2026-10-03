# Panduan Windows

> **Terakhir diperbarui: Sabtu, 03 Okt 2026 · 15:25 WIB**

Windows tidak punya `systemd`. Solusinya: **WSL2 + Ubuntu**, lalu
autostart lewat **Task Scheduler**.

---

## Ringkas

```
Windows 10/11
   └── WSL2
         └── Ubuntu   <- installer berjalan di sini (sama seperti Linux)
Task Scheduler        <- menyalakan robot saat Windows boot
```

---

## Langkah 1 — Pasang WSL2 + Ubuntu (sekali, 10 menit)

Buka **PowerShell sebagai Administrator** (klik kanan → Run as administrator):

```powershell
wsl --install -d Ubuntu
```

Restart komputer kalau diminta. Setelah restart, Ubuntu akan terbuka dan
meminta Anda membuat **username** + **password** — catat baik-baik.

Cek berhasil:

```powershell
wsl -l -v
```

Harus tampil `Ubuntu` dengan `VERSION 2`.

> **Kalau muncul VERSION 1**, ubah:
> ```powershell
> wsl --set-version Ubuntu 2
> ```

---

## Langkah 2 — Jalankan installer

Masuk ke Ubuntu:

```powershell
wsl -d Ubuntu
```

Lalu di dalam Ubuntu:

```bash
sudo apt update && sudo apt install -y git
git clone <URL-REPO-ANDA>
cd hermes-custom
./install.sh
```

> **Catatan:** installer akan otomatis melewati bagian autostart systemd
> (karena WSL tidak memakainya). Itu **normal** — autostart ditangani
> Task Scheduler di Langkah 3.

---

## Langkah 3 — Autostart lewat Task Scheduler

Supaya robot nyala sendiri saat Windows dinyalakan.

### Cara 1 — Lewat PowerShell (cepat)

Buka **PowerShell sebagai Administrator**:

```powershell
$user = "USERNAME_UBUNTU_ANDA"

schtasks /create /tn "AI Agent Gateway" `
  /tr "wsl.exe -d Ubuntu -u $user -e bash -lc '~/.local/bin/hermes gateway'" `
  /sc onstart /ru SYSTEM /rl HIGHEST /f
```

Ganti `USERNAME_UBUNTU_ANDA` dengan username Ubuntu Anda.

Cek berhasil:

```powershell
schtasks /query /tn "AI Agent Gateway"
```

### Cara 2 — Lewat tampilan (kalau lebih suka klik)

```
1. Buka Task Scheduler (cari di Start Menu)
2. Klik "Create Task..." (BUKAN "Create Basic Task")
3. Tab General:
     Name        : AI Agent Gateway
     ✅ Run whether user is logged on or not
     ✅ Run with highest privileges
     Configure for: Windows 10 / 11
4. Tab Triggers -> New...
     Begin the task: At startup
     OK
5. Tab Actions -> New...
     Action : Start a program
     Program: C:\Windows\System32\wsl.exe
     Arguments: -d Ubuntu -u USERNAME_UBUNTU_ANDA -e bash -lc "~/.local/bin/hermes gateway"
6. Tab Settings:
     ✅ Allow task to be run on demand
     ✅ If the task fails, restart every: 1 minute
7. OK -> masukkan password Windows Anda
```

---

## Langkah 4 — Remote web view & Tailscale dari Windows

Ini bagian yang **paling sering gagal** kalau tidak hati-hati.

### Masalahnya

```
WSL punya "alamat sendiri" (misal 172.x.x.x) yang TIDAK terlihat
dari jaringan luar. Tailscale di WSL juga sering tidak jalan mulus.
```

### Solusinya — jalankan Tailscale di WINDOWS, bukan di WSL

```powershell
# Di PowerShell (Administrator)
winget install --id Tailscale.Tailscale
```

Login Tailscale lewat aplikasi Windows-nya (muncul di system tray).

### Jembatani port noVNC dari WSL ke Windows

Buat file `jembatan-port.ps1` di Windows:

```powershell
# Teruskan port 6080 dari WSL ke Windows (supaya bisa diakses Tailscale)
while ($true) {
    $wslIp = (wsl -d Ubuntu hostname -I).Trim().Split()[0]
    Write-Host "Meneruskan http://$wslIp:6080 -> localhost:6080"
    netsh interface portproxy delete v4tov4 listenport=6080 listenaddress=0.0.0.0 | Out-Null
    netsh interface portproxy add v4tov4 listenport=6080 listenaddress=0.0.0.0 connectport=6080 connectaddress=$wslIp
    Start-Sleep -Seconds 60
}
```

Jalankan sekali saat boot (tambahkan ke Task Scheduler dengan trigger
"At startup", sama seperti Langkah 3).

Lalu buka dari HP/laptop:

```
http://<IP-Tailscale-Windows>:6080/vnc.html
```

---

## Pemecahan masalah Windows

| Gejala | Sebab | Perbaikan |
|---|---|---|
| `wsl --install` gagal | Virtualisasi mati di BIOS | Nyalakan VT-x/AMD-V di BIOS |
| Installer bilang "autostart dilewati" | Normal di WSL | Lanjutkan Langkah 3 |
| Robot tidak jalan setelah reboot | Task Scheduler belum dibuat | Ulangi Langkah 3 |
| Task Scheduler error `0x1` | User/path salah | Cek username Ubuntu: `wsl -d Ubuntu whoami` |
| noVNC tidak bisa dibuka | Port belum dijembatani | Jalankan `jembatan-port.ps1` |
| Tailscale tidak jalan di WSL | Normal | Pasang Tailscale di **Windows**, bukan WSL |
| WSL lambat / makan memori | Batas memori default | Buat `C:\Users\<Anda>\.wslconfig` → lihat di bawah |

### Batasi memori WSL (kalau komputer jadi lambat)

Buat file `C:\Users\<NAMA-ANDA>\.wslconfig`:

```ini
[wsl2]
memory=6GB
processors=4
swap=2GB
```

Lalu restart WSL:

```powershell
wsl --shutdown
```

---

## Yang perlu diingat

```
1. Windows butuh WSL2 — tidak ada cara lain yang lebih baik.
2. Autostart di Windows = Task Scheduler (bukan systemd).
3. Tailscale dipasang di WINDOWS, bukan di WSL.
4. noVNC butuh jembatan port (portproxy) dari WSL ke Windows.
5. Laptop Windows yang sering ditutup akan mematikan robot.
   Kalau butuh yang selalu hidup, pakai komputer yang menyala terus.
```
