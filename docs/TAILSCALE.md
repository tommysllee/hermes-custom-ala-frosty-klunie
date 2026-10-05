# Tailscale Guide — Automatically into Your Dashboard

> **Last updated: Saturday, 03 Oct 2026 · 15:35 WIB**

For **tailnet owners**. The goal: everyone who installs the
AI agent **automatically appears** in your Tailscale dashboard, so you
can help whenever needed without being asked.

The tag this repo uses: **`tag:dipasangintsl`** (matching your ACL).

---

## Concept

```
AUTH KEY  = "entry ticket". Embedded in the repo. Anyone who runs the
            installer automatically joins your tailnet.
TAG       = automatic label attached to the device: tag:dipasangintsl
ACL       = permission rules (which you have already set up).
```

**Your ACL is already correct** (from console.tailscale.com/acl):

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

**What matters about this ACL:**

| Rule | What it means |
|---|---|
| `tagOwners` | Only you (admin) may use this tag |
| Personal devices stay connected | Your laptop/phone keep working normally |
| `admin` → `tag:dipasangintsl` | **You** can access all devices installed by the repo |
| SSH `accept` to `tag:dipasangintsl` | **You** can SSH in to help |
| **No client → client rules** | Clients **cannot** see each other ✅ |

**Key point:** because your ACL grants no rules between tagged
devices, the installer's privacy is preserved — A cannot touch B.

---

## Remaining step — create an Auth Key (3 minutes)

1. Open **https://login.tailscale.com/admin/settings/keys**

2. Click **Generate auth key...**

3. Fill in:

```
Description   : repo-pemasang-otomatis
Reusable      : ✅ ON      <- many people use the same key
Ephemeral     : ❌ OFF     <- device persists even while offline
Pre-approved  : ✅ ON      <- no manual approval needed from you
Tags          : tag:dipasangintsl   <- REQUIRED
Expiration    : 90 days
```

4. Click **Generate key** → **COPY** it.

   It looks like: `tskey-auth-xxxxxxxxxxx-xxxxxxxxxxxxxxxxxxxx`

5. **Paste it into the repo.** Two ways:

### Method A — Embed in the repo (fully automatic)

Edit `installer.env`:

```bash
TS_AUTHKEY="tskey-auth-xxxxx"
TS_TAG="tag:dipasangintsl"
```

Anyone who clones and runs `./install.sh` → **automatically joins**
your tailnet. No typing required.

### Method B — Via an environment variable (safer)

```bash
TS_AUTHKEY="tskey-auth-xxxxx" ./install.sh
```

---

## ⚠️ Risks you must be aware of

```
With Method A the key is EMBEDDED in the public repo.
Anyone who reads the repo can take that key and add a device
to your tailnet.

Mitigations:
  1. 90-day expiry (not Forever)
  2. Pre-approved ON -> you can view & remove devices at any time
  3. Required tag -> foreign devices are automatically isolated by the ACL
  4. Check the dashboard regularly: https://login.tailscale.com/admin/machines
  5. If it leaks: delete the key on the keys page and create a new one
```

**Safest alternative:** use Method B — send the key over a private channel
(WhatsApp/Telegram), do not embed it in the repo.

---

## Seeing who just installed

```bash
tailscale status
```

Or open **https://login.tailscale.com/admin/machines**

Devices from this repo will appear as:

```
Device name : hermes-agent-<name>   (or the installer's hostname)
Tag         : tag:dipasangintsl     <- this is the marker
```

**Quick way to see only the tagged ones:**

```bash
tailscale status | grep -i dipasangintsl
```

---

## Helping the installer

**SSH in** (the ACL already allows it):

```bash
ssh <username>@100.x.x.x
```

**See their browser** (if they turned on the remote web view):

```
http://<device-IP>:6080/vnc.html
```

> The remote web view password differs per device and **only exists on their machine**.
> Ask them to run:
> `~/.hermes/remote-view/remote-view.sh password`

---

## If you don't want it automatic

The installer **never forces anything**. If `TS_AUTHKEY` is empty, the installer
just shows:

```
1. SECURE NETWORK (automatic)
     Run this, then follow the link:
        sudo tailscale up --ssh
```

That person logs in with their own Tailscale account → the device joins
**their** tailnet, not yours. Valid, but you cannot help them directly.

---

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| Device joins without a tag | Auth key created without a tag | Create a new auth key, select **Tags** |
| A can see B | ACL is wrong | Check there is no `src: ["*"]` |
| `tailscale up` asks for approval | **Pre-approved** not checked | Create a new key with Pre-approved ON |
| Key doesn't work | Expired / already deleted | Create a new key |
| Device doesn't appear | `tailscale up` failed | Check: `sudo tailscale status` |
| Can't SSH into the device | SSH ACL not yet correct | Make sure the `ssh` block is present as above |

---

## Things to remember

```
1. Auth keys & tags are ONLY created from the admin console, not the CLI.
2. Always use a tag — without a tag, devices can see each other.
3. Your ACL is ALREADY CORRECT: only admin -> devices, nothing between devices.
4. A key = access to your tailnet. Give it a short expiry (90 days).
5. The installer never forces anything — automatic only if a key is provided.
6. Check the dashboard regularly, remove unknown devices.
```

---

## IMPORTANT — If an auth key is pasted into the repo

If the repo owner pastes an auth key directly into `installer.env`
so clients don't have to fill in anything:

### Safeguards already built into the installer

```
1. Automatic device name: hermes-<6 random characters>
   → easy to recognize & group in the dashboard

2. The device CANNOT become an exit node / subnet router
   (--advertise-exit-node=false)
   → narrows the possibility of misuse

3. Clients are honestly told that their device is connected
   and given a way to disconnect on their own:
       sudo tailscale down && sudo tailscale logout
```

### What the repo owner MUST keep in mind

```
⚠️ A reusable auth key in a public repo = anyone can use it.

Recommended mitigations:
  • SHORT expiration (7–30 days) → the key dies on its own
    → Renew by generating a new key periodically
  • Watch the Machines page: foreign device = remove it
    (https://login.tailscale.com/admin/machines)
  • Revoke the key at any time: Settings > Keys > Revoke
  • Do NOT use the same key for anything else
```

### Limits of responsibility (honestly)

```
What the key owner CAN do:
  • Access the client's device via SSH
  • See the client's device in the dashboard

What does NOT happen automatically:
  • Client data is not sent to the repo owner
  • Client files are not copied anywhere
  • Client applications cannot be accessed without their own credentials
```

Therefore the installer **informs clients openly** and
provides a way to disconnect. This matters both ethically and
so clients don't feel disadvantaged.
