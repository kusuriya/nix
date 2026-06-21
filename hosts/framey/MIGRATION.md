# Framey Migration Runbook — LUKS2-encrypted btrfs with Secure Boot & TPM2

**Host:** framey — Framework 13 AMD laptop  
**Hardware:** AMD Ryzen 7 7840U, Radeon 780M APU, 96 GB RAM, 1.8 TB Sabrent NVMe  
**Disk path:** `/dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873`  
**Current firmware:** 0.0.3.5 (target: 0.0.3.18)  
**Kernel:** 7.0.5  |  **btrfs-progs:** v7.0  

This runbook migrates framey from its current state (unencrypted, Secure Boot off, TPM disabled, firmware outdated) to a fully encrypted btrfs system with Secure Boot and TPM2-backed automatic disk unlock.

---

## Pre-flight Checklist

1. **Check backup size**
   ```bash
   du -sh /home
   ```
   (297 GB currently used on root — ensure destination has sufficient space)

2. **Update firmware** — 0.0.3.5 → 0.0.3.18 (13 versions, multiple CVEs)
   ```bash
   sudo fwupdmgr update
   ```
   Reboot required. This also installs UEFI dbx and Secure Boot db updates.

3. **Enable TPM in BIOS**
   - Reboot, press **F2** to enter BIOS
   - Navigate to **Security → TPM 2.0 → Enable**
   - (TPM is currently **disabled**)

4. **Back up `/home`** to dozer or an external drive

5. **Back up SSH host keys**
   ```bash
   sudo cp /etc/ssh/ssh_host_ed25519_key* /tmp/keys/
   ```

6. **Back up Tailscale state** (optional — currently logged out)
   ```bash
   sudo cp -r /var/lib/tailscale /tmp/tailscale-backup/
   ```

7. **Boot from NixOS live USB**

8. **Clone the flake**
   ```bash
   git clone https://github.com/kusuriya/nix.git /tmp/nix
   cd /tmp/nix
   ```

---

## Generate LUKS Passphrase (before disko)

Generate a 12-word XKCD-style passphrase using the EFF wordlist (~156 bits entropy, actually memorable):

```bash
python3 -c "
import secrets, urllib.request
words = [l.split('\t')[1] for l in urllib.request.urlopen('https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt').read().decode().strip().split('\n') if '\t' in l]
print('-'.join(secrets.choice(words) for _ in range(12)))
"
```

Save it securely:
```bash
# Save to an age-encrypted file on the system (root-only)
echo "$PASS" | age -p -o /root/luks-passphrase.age

# Write down on paper and store in a physical safe — this is your ultimate recovery method
```

See `1-Daily/2026-06-21-framey-luks-passphrase.md` in Obsidian for full details.

## Apply Disko (DESTRUCTIVE — wipes disk)

> **Warning:** This destroys all data on the NVMe. Ensure backups are complete before proceeding.
>
> When disko prompts for the LUKS passphrase, type (or paste) the 12-word passphrase generated above.

```bash
nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#framey
```

**Alternative** — nixos-anywhere (handles disko + install + SSH in one command):
```bash
nix run github:nix-community/nixos-anywhere -- --flake .#framey root@<framey-ip>
```

---

## Install NixOS

```bash
nixos-install --flake .#framey --no-root-password
```

---

## Post-install: Set user password

```bash
passwd kusuriya
```

---

## Post-install: Restore SSH host keys

```bash
sudo cp /tmp/keys/ssh_host_ed25519_key* /etc/ssh/
sudo systemctl restart sshd
```

---

## Post-install: Restore Tailscale (optional)

```bash
# Option A: restore saved state
sudo cp -r /tmp/tailscale-backup /var/lib/tailscale

# Option B: fresh login
sudo tailscale up
```

---

## Secure Boot Setup (one-time)

1. Enter BIOS, set **Secure Boot to Setup Mode** (clears existing platform keys)
2. Boot into NixOS
3. Check if lanzaboote auto-generated keys:
   ```bash
   sudo sbctl verify
   ```
4. If keys were **not** generated:
   ```bash
   sudo sbctl create-keys
   ```
5. Enroll keys with Microsoft keys for hardware compatibility:
   ```bash
   sudo sbctl enroll-keys --microsoft
   ```
6. Verify all artifacts are signed:
   ```bash
   sudo sbctl verify
   ```
7. Enter BIOS, **enable Secure Boot**
8. Reboot — system should boot without intervention
9. Confirm Secure Boot is active:
   ```bash
   bootctl status | grep -i secure
   ```

---

## TPM2 LUKS Enrollment (post-install, post-Secure-Boot)

> **Prerequisites:** Secure Boot must be set up **FIRST** — PCR 7 includes Secure Boot state.

```bash
sudo systemd-cryptenroll \
  --wipe-slot=tpm2 \
  --tpm2-device=auto \
  --tpm2-pcrs=0+2+7 \
  --tpm2-with-pin \
  /dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873-part2
```

You will be prompted to set a PIN during enrollment. Choose a strong numeric PIN (6-8 digits).

**How this works:**
- Normal boot: TPM2 checks PCRs (0+2+7) **and** prompts for the PIN → both must pass to unlock
- If PCR values don't match (firmware update, Secure Boot change): falls back to LUKS passphrase
- If laptop is stolen: attacker needs the PIN even if PCR values match — prevents silent unlock
- The LUKS passphrase is always available as a secondary recovery method

**Verify:**
```bash
sudo cryptsetup luksDump /dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873-part2
```
Should show a TPM2 slot. Reboot — the system should prompt for a PIN at boot (not the full LUKS passphrase).

**Re-enrollment triggers** (re-run the `systemd-cryptenroll` command above when any of these change):
- Firmware updates → PCR 0
- Boot loader changes → PCR 2
- Secure Boot key changes → PCR 7

When re-enrolling, you can reuse the same PIN or set a new one.

---

## USBGuard Policy Generation (one-time)

```bash
sudo usbguard generate-policy > /tmp/rules.conf
sudo cp /tmp/rules.conf /etc/usbguard/rules.conf
sudo systemctl restart usbguard
sudo usbguard list-devices
```

> **Note:** The Framework 13 built-in keyboard/trackpad are **not** USB devices — they work before and independent of policy generation.

---

## Verification

```bash
bootctl status | grep -i secure        # Secure Boot active
sudo cryptsetup luksDump \
  /dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873-part2 \
  | grep -i tpm                         # TPM2 enrolled
sudo systemctl status usbguard          # USBGuard running
sudo systemctl status btrbk.timer       # btrbk scheduled
sudo systemctl status btrfs-autoScrub   # autoScrub scheduled
sudo iptables -L -n | head              # firewall active
sudo systemctl status auditd           # audit running
sudo aa-status | head                   # AppArmor loaded
```

---

## Notes

- **autoUpgrade** is enabled (weekly Sunday 1 AM, unstable channel) — `allowReboot=false`, TPM2 handles automatic unlock after reboot.
- **NFS mounts** `/data` and `/dozer/files` are lazy-mounted (`noauto`, `x-systemd.automount`).
- **Hibernation** is **NOT** available (kernel blocks it under Secure Boot lockdown). Suspend only. The 96 GB swapfile is ready for when upstream support lands.
- **btrbk** runs hourly snapshots with retention: 48 h / 14 d / 8 w / 6 m, stored in the `@snapshots` subvolume.
- **Thunderbolt** security is set to "user" (per-device authorization).