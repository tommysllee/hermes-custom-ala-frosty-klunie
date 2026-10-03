# Panduan Tailscale — Otomatis ke Dashboard Anda

> **Terakhir diperbarui: Sabtu, 03 Okt 2026 · 15:35 WIB**

Untuk **pemilik tailnet** (Tommy). Tujuannya: setiap orang yang memasang
AI agent **otomatis muncul** di dashboard Tailscale Anda, sehingga Anda
bisa membantu kapan pun tanpa diminta.

Tag yang dipakai repo ini: **`tag:dipasangintsl`** (sesuai ACL Anda).

---

## Konsep

```
AUTH KEY  = "tiket masuk". Ditanam di repo. Siapa pun yang menjalankan
            installer otomatis masuk ke tailnet Anda.
TAG       = label otomatis yang menempel di device: tag:dipasangintsl
ACL       = aturan izin (sudah Anda siapkan).
```

**ACL Anda sudah benar** (dari console.tailscale.com/acl):

```json
{
  "tagOwners": {
    "tag:dipasangintsl": ["autogroup:admin"]
  },
  "grants": [
    { "src": ["autogroup:member"], "dst": ["autogroup:self"], "ip": ["*"] },
    { "src": ["autogroup:admin"], "dst": ["tag:dipasangintsl"], "ip": ["*"] }
  ],
  "ssh": [
    {
      "action": "check",
      "src": ["autogroup:member"],
      "dst": ["autogroup:self"],
      "users": ["autogroup:nonroot", "root"]
    },
    {
      "action": "accept",
      "src": ["autogroup:admin"],
      "dst": ["tag:dipasangintsl"],
      "users": ["autogroup:nonroot", "root"]
    }
  ]
}
```

**Yang penting dari ACL ini:**

| Aturan | Artinya |
|---|---|
| `tagOwners` | Hanya Anda (admin) yang boleh memakai tag ini |
| Device pribadi saling terhubung | Laptop/HP Anda tetap normal |
| `admin` → `tag:dipasangintsl` | **Anda** bisa akses semua device yang dipasang repo |
| SSH `accept` ke `tag:dipasangintsl` | **Anda** bisa SSH ke sana untuk membantu |
| **Tidak ada aturan klien → klien** | Klien **tidak bisa** saling lihat ✅ |

**Poin penting:** karena ACL Anda tidak memberi aturan antar-device
ber-tag, privasi pemasang terjaga — A tidak bisa menyentuh B.

---

## Langkah yang tersisa — buat Auth Key (3 menit)

1. Buka **https://login.tailscale.com/admin/settings/keys**

2. Klik **Generate auth key...**

3. Isi:

```
Description   : repo-pemasang-otomatis
Reusable      : ✅ ON      <- banyak orang pakai kunci yang sama
Ephemeral     : ❌ OFF     <- device tetap ada walau sedang offline
Pre-approved  : ✅ ON      <- tidak perlu Anda approve manual
Tags          : tag:dipasangintsl   <- WAJIB
Expiration    : 90 days
```

4. Klik **Generate key** → **SALIN**.

   Bentuknya: `tskey-auth-xxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxx`

5. **Tempel ke repo.** Dua cara:

### Cara A — Tanam di repo (otomatis penuh)

Edit `installer.env`:

```bash
TS_AUTHKEY="tskey-auth-xxxxx"
TS_TAG="tag:dipasangintsl"
```

Siapa pun yang clone lalu jalankan `./install.sh` → **otomatis masuk**
ke tailnet Anda. Tidak perlu mengetik apa pun.

### Cara B — Lewat variabel (lebih aman)

```bash
TS_AUTHKEY="tskey-auth-xxxxx" ./install.sh
```

---

## ⚠️ Risiko yang harus Anda sadari

```
Kunci di Cara A TERTANAM di repo public.
Siapa pun yang membaca repo bisa mengambil kunci itu dan memasukkan
device ke tailnet Anda.

Mitigasi:
  1. Masa berlaku 90 hari (jangan Forever)
  2. Pre-approved ON -> Anda bisa lihat & hapus device kapan saja
  3. Tag wajib -> device asing otomatis terisolasi oleh ACL
  4. Cek dashboard berkala: https://login.tailscale.com/admin/machines
  5. Kalau bocor: hapus kunci di halaman keys, buat baru
```

**Alternatif paling aman:** pakai Cara B — kirim kunci lewat jalur pribadi
(WhatsApp/Telegram), jangan ditanam di repo.

---

## Melihat siapa yang baru pasang

```bash
tailscale status
```

Atau buka **https://login.tailscale.com/admin/machines**

Device dari repo ini akan terlihat:

```
Nama device : hermes-agent-<nama>   (atau nama host pemasang)
Tag         : tag:dipasangintsl     <- ini penandanya
```

**Cara cepat melihat hanya yang ber-tag:**

```bash
tailscale status | grep -i dipasangintsl
```

---

## Membantu pemasang

**Masuk SSH** (ACL sudah mengizinkan):

```bash
ssh <username>@100.x.x.x
```

**Melihat browser mereka** (kalau mereka nyalakan remote web view):

```
http://<IP-device>:6080/vnc.html
```

> Sandi remote web view berbeda tiap device dan **hanya ada di mesin mereka**.
> Minta mereka menjalankan:
> `~/.hermes/remote-view/remote-view.sh password`

---

## Kalau tidak mau otomatis

Installer **tidak pernah memaksa**. Kalau `TS_AUTHKEY` kosong, installer
hanya menampilkan:

```
1. JARINGAN AMAN (otomatis)
     Jalankan, lalu ikuti tautan:
        sudo tailscale up --ssh
```

Orang itu login dengan akun Tailscale-nya sendiri → device masuk ke
tailnet **miliknya**, bukan milik Anda. Sah, tapi tidak bisa Anda bantu
secara langsung.

---

## Pemecahan masalah

| Gejala | Sebab | Perbaikan |
|---|---|---|
| Device masuk tanpa tag | Auth key dibuat tanpa tag | Buat auth key baru, pilih **Tags** |
| A bisa lihat B | ACL salah | Cek tidak ada `src: ["*"]` |
| `tailscale up` minta approve | **Pre-approved** tidak dicentang | Buat kunci baru dengan Pre-approved ON |
| Kunci tidak jalan | Kedaluwarsa / sudah dihapus | Buat kunci baru |
| Device tidak muncul | `tailscale up` gagal | Cek: `sudo tailscale status` |
| Tidak bisa SSH ke device | ACL SSH belum benar | Pastikan blok `ssh` ada seperti di atas |

---

## Hal yang perlu diingat

```
1. Auth key & tag HANYA dibuat dari admin console, bukan CLI.
2. Selalu pakai tag — tanpa tag, device bisa saling lihat.
3. ACL Anda SUDAH BENAR: hanya admin -> device, tidak ada antar-device.
4. Kunci = akses ke tailnet Anda. Beri masa berlaku pendek (90 hari).
5. Installer tidak pernah memaksa — otomatis hanya kalau kunci diberikan.
6. Cek dashboard berkala, hapus device yang tidak dikenal.
```
