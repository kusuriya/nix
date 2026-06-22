# Framey — Framework 13 AMD Laptop

Primary workstation. Security-hardened NixOS with LUKS2 full-disk encryption, btrfs, Secure Boot, and TPM2 auto-unlock.

---

## Hardware

| Component | Spec |
|-----------|------|
| **Model** | Framework 13 (AMD) |
| **CPU** | AMD Ryzen 7 7040 (8c/16t) |
| **RAM** | 96GB (2x48GB SODIMMs) |
| **Storage** | NVMe SSD |
| **GPU** | AMD APU (integrated, no dGPU) |
| **TPM** | fTPM 2.0 (firmware) |
| **Boot** | UEFI with Secure Boot (lanzaboote) |

---

## What This Configuration Does

### Disk Encryption & Layout

Full-disk encryption via LUKS2, managed declaratively by [disko](https://github.com/nix-community/disko). The entire disk (except the EFI System Partition) is a single LUKS2 container holding btrfs subvolumes.

**Disk layout** (`disko.nix`):
```
/dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873
├── p1: ESP (1G, vfat)         → /boot          [unencrypted — kernel + initrd live here]
└── p2: LUKS2 (cryptroot)       → /dev/mapper/cryptroot
      └── btrfs (zstd compression, noatime)
          ├── @root              → /
          ├── @home              → /home
          ├── @nix               → /nix
          ├── @log               → /var/log      [separate for snapshot exclusion]
          ├── @snapshots          → /.snapshots   [dedicated for btrbk — avoids recursive snapshots]
          ├── @swap              → /.swapvol     [96G swapfile, encrypted — matches 96GB RAM]
          └── @persist           → /persist      [placeholder for future impermanence]
```

**Why this layout:**
- **LUKS2** — full-disk encryption, protects data at rest
- **btrfs** — snapshots, compression, subvolumes for flexible management
- **@log separate** — excludes noisy logs from root snapshots
- **@swap inside LUKS** — swap is encrypted (no cleartext swap leak)
- **@persist placeholder** — not actively used; reserved for potential future impermanence setup
- **32G swapfile** → now **96G swapfile** — matches RAM size, required for hibernation (currently suspended-only, see Caveats)

### Secure Boot

Enabled via [lanzaboote](https://github.com/nix-community/lanzaboote) — wraps systemd-boot with UEFI Secure Boot signing.

- **User-controlled keys** via `sbctl` — you generate and enroll your own keys
- **Microsoft keys enrolled** alongside user keys for hardware compatibility (firmware updates, Option ROMs)
- **Kernel + initrd signed** at build time — lanzaboote automatically signs all boot artifacts
- **sbctl** included in systemPackages for key management and verification

**Threat model:** Protects against evil-maid attacks and boot-level malware. An attacker with physical access cannot boot an unsigned kernel or modify boot configuration without detection. This is appropriate for a laptop that travels.

### TPM2 Auto-Unlock

The LUKS2 container auto-unlocks via TPM2 at boot with a required PIN — both the TPM2 PCR check and the PIN must pass to unlock.

- **PCRs used:** 0 (firmware) + 2 (boot loader) + 7 (Secure Boot state)
- **PIN required:** `--tpm2-with-pin=yes` — a numeric PIN is prompted at boot in addition to the TPM2 PCR check. Prevents silent unlock if the laptop is stolen with matching PCR state.
- **Passphrase fallback:** LUKS2 always has a passphrase slot as fallback — if PCR values change (firmware update, Secure Boot key change), the passphrase works
- **systemd initrd:** `boot.initrd.systemd.enable = true` is required for TPM2 unlock via `systemd-cryptenroll`
- **Re-enrollment required** after firmware updates, boot loader changes, or Secure Boot key changes (PCR values change)

**Security trade-off:** TRIM passthrough is enabled (`allowDiscards = true`) for SSD longevity. This leaks which disk blocks are in use (minor info leak, standard trade-off for SSDs).

### btrfs Snapshots

Automated via [btrbk](https://github.com/digint/btrbk) — hourly snapshots with tiered retention.

| Retention | Period |
|-----------|--------|
| Hourly | 48 hours |
| Daily | 14 days |
| Weekly | 8 weeks |
| Monthly | 6 months |

Snapshots are stored locally in `/.snapshots`. To restore a snapshot:
```bash
# Find the snapshot you want
ls /.snapshots/

# Create a new subvolume from the snapshot
sudo btrfs subvolume snapshot /.snapshots/@root.20260621_140000 /restored

# Swap the root subvolume (requires reboot)
# Or boot from a live USB and rename subvolumes
```

**Note:** Snapshots are local and on the same disk — they are NOT backups. They protect against accidental deletion and bad changes, not disk failure.

### btrfs autoScrub

btrfs scrub is scheduled automatically via `services.btrfs.autoScrub`:
- **Frequency:** weekly
- **Targets:** all btrfs filesystems (cryptroot)
- **Purpose:** detects and repairs silent data corruption (bit rot) by verifying checksums against metadata

This runs in the background and does not impact normal I/O significantly. Check status with `sudo btrfs scrub status /`.

### Network Security

- **Firewall:** enabled, no ping, SSH via Tailscale only (port 22 on `tailscale0` interface)
- **Tailscale:** client mode, userspace networking
- **NetworkManager:** MAC randomization on scan, WiFi powersave disabled
- **No ports exposed** to local network or internet (Avahi opens its own via `openFirewall = true`)

### Access Control

- **AppArmor:** enabled, `killUnconfinedConfinables = true` (processes without a profile are killed)
- **USBGuard:** removed — broke Caldigit dock. Can revisit with per-device-ID rules later.
- **TPM2:** PKCS11 + TCTI environment enabled (used for LUKS unlock and potential future smart card use)
- **1Password:** GUI + CLI + polkit integration
- **sudo:** requires password (`wheelNeedsPassword = true`)
- **Audit:** `audit.enable = true` + `auditd.enable = true` — kernel audit trail enabled

### Physical Security

- **Thunderbolt:** `services.hardware.bolt.enable = true` with `security = "user"` — Thunderbolt devices require explicit user authorization via `boltctl` before DMA access is granted
- **USBGuard:** removed (broke Caldigit dock — see Caveats)
- **TPM2:** used for LUKS auto-unlock and potential future smart card use
- **Secure Boot:** protects against evil-maid / boot-level attacks (see Secure Boot section)

### Kernel Hardening

Sysctls configured for laptop security:

| Setting | Value | Effect |
|---------|-------|--------|
| `kernel.kptr_restrict` | 2 | Hide kernel pointers from non-root |
| `kernel.dmesg_restrict` | 1 | Restrict dmesg to root |
| `kernel.perf_event_paranoid` | 3 | Restrict perf events (most restrictive) |
| `kernel.yama.ptrace_scope` | 2 | Restrict ptrace to admin only |
| `net.ipv4.conf.all.rp_filter` | 1 | Reverse path filtering (anti-spoofing) |
| `net.ipv4.conf.all.accept_redirects` | 0 | No ICMP redirects |
| `net.ipv4.conf.all.send_redirects` | 0 | Don't send redirects |
| `net.ipv4.conf.all.accept_source_route` | 0 | No source routing |
| `net.ipv6.conf.all.accept_redirects` | 0 | No IPv6 ICMP redirects |
| `net.ipv6.conf.all.accept_source_route` | 0 | No IPv6 source routing |
| `net.ipv4.icmp_echo_ignore_broadcasts` | 1 | No smurf attacks |
| `net.ipv4.tcp_syncookies` | 1 | SYN flood protection |

Plus existing network performance tuning (BBR congestion control, fq qdisc, TCP fastopen, MTU probing, low swappiness).

### Power Management

- **TLP** enabled with charge thresholds (25% start / 90% stop) for battery longevity
- **TLP** CPU governor: performance on AC, powersave on battery
- **TLP** max perf on battery: 20% (conservative)
- **fstrim** weekly (SSD TRIM maintenance)
- **fwupd** enabled (firmware updates)
- **zramSwap** disabled (was 50% zstd — at 96GB RAM with minimal swap usage, zram wastes RAM for no benefit)
- **Swap strategy:** 96G btrfs swapfile inside LUKS only, `vm.swappiness=10`
- **power-profiles-daemon** disabled (TLP handles power management instead)

### Virtualization

- **libvirtd** (QEMU/KVM) with swtpm (software TPM for VMs)
- **podman** with Docker compatibility (`dockerCompat = true`)
- **distrobox** for container-based dev environments
- **OVMF** with TPM, SecureBoot, HTTP/TLS support (for Windows 11 VMs)
- **Looking Glass** client (VM framebuffer passthrough)
- **spice-gtk** + spice USB redirection

### Audio

PipeWire with WirePlumber, tuned for QEMU:
- Default quantum raised to 2048/48000 (42.7ms) to absorb scheduler jitter from libvirtd-launched QEMU
- WirePlumber node rules grant QEMU RT scheduling (priority 88)
- Full ALSA + PulseAudio + JACK compatibility

---

## NFS Mounts

| Mount | Source | Options |
|-------|--------|---------|
| `/data` | `dozer:/mnt/dozer-files/hermes-data` | `x-systemd.automount noauto async x-systemd.idle-timeout=5min timeo=14 retrans=2` |
| `/dozer/files` | `dozer:/mnt/dozer-files/files` | `x-systemd.automount noauto x-systemd.idle-timeout=5min timeo=14 retrans=2` |

Both are lazy-mounted via systemd automount — they only mount when accessed.

**Tuning explained:**
- `noauto` — not mounted at boot, boot is unaffected if dozer is offline
- `x-systemd.automount` — mount on first access, unmount when idle
- `x-systemd.idle-timeout=5min` — unmount after 5 min idle (default is 2 min)
- `timeo=14` — NFS timeout of 1.4s per retry (default is 60s — absurd for a laptop)
- `retrans=2` — retry 2 times, so total timeout ~3s instead of 60+
- `async` (on `/data` only) — async writes for performance (mostly-read data)

**Behavior when dozer is offline:** Accessing `/data` fails in ~3 seconds with `Connection timed out` instead of hanging for 60+ seconds.

---

## Fresh Install from NixOS Media

This procedure wipes the NVMe and installs a fresh NixOS with the full encrypted + Secure Boot + TPM2 configuration.

### Prerequisites (do these BEFORE booting the live USB)

- **Back up `/home`** — this procedure is destructive. See `1-Daily/2026-06-21-framey-backup-commands.md` in Obsidian for the rsync command
- **Enable TPM in BIOS** — F2 → Security → TPM 2.0 → Enable (currently disabled on framey)
- **Update firmware** — `sudo fwupdmgr update` (current: 0.0.3.5, latest: 0.0.3.18). Reboot required. Must be done BEFORE TPM2 enrollment.
- **Back up SSH host keys** — `sudo cp /etc/ssh/ssh_host_ed25519_key* /data/backup/framey-post-install-$(date +%Y-%m-%d)/ssh-keys/`
- **Back up Tailscale state (optional)** — `sudo cp -r /var/lib/tailscale /data/backup/framey-post-install-$(date +%Y-%m-%d)/tailscale/`
- NixOS install media (USB)
- `/data` and `/dozer/files` are NFS mounts on dozer and are unaffected

### Copy-paste install script

Boot the NixOS live USB, open a terminal, and paste this entire block. It handles cloning the repo, generating the passphrase, running disko, and installing NixOS.

> **⚠️ DESTRUCTIVE** — this wipes the entire NVMe. Ensure all backups are complete before running.

```bash
# ============================================================================
# FRAMEY FRESH INSTALL — copy-paste this entire block into a root shell
# ============================================================================
set -e

# 1. Clone the flake repo
nix-shell -p git --run "git clone https://github.com/kusuriya/nix.git /tmp/nix"
cd /tmp/nix

# 2. Generate a 12-word recovery key using EFF wordlist
#    (no python needed — uses nix-shell to pull python3 + curl)
echo "Generating 12-word recovery key..."
nix-shell -p python3 curl --run "python3 -c \"
import secrets, urllib.request
words = [l.split('\t')[1] for l in urllib.request.urlopen('https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt').read().decode().strip().split('\n') if '\t' in l]
print('-'.join(secrets.choice(words) for _ in range(12)))
\"" > /tmp/luks-passphrase.txt

echo "=== YOUR RECOVERY KEY (save this — you'll need it) ==="
cat /tmp/luks-passphrase.txt
echo "========================================================="
echo ""
echo "Write this down on paper NOW. You will need it at every step below."
echo "Press Enter when you've saved it..."
read -r

# 3. Encrypt and back up the passphrase to dozer
#    (uses nix-shell to pull age — not on the live USB by default)
nix-shell -p age --run "age -p -o /tmp/luks-passphrase.age < /tmp/luks-passphrase.txt"
#    (you'll be prompted for an age passphrase — memorize it, it's separate from the recovery key)

# Back up the age file to dozer (survives the disk wipe)
mkdir -p /data/backup/framey-post-install-$(date +%Y-%m-%d)
cp /tmp/luks-passphrase.age /data/backup/framey-post-install-$(date +%Y-%m-%d)/luks-passphrase.age
echo "Backed up encrypted passphrase to dozer."

# 4. Verify the disk
echo "=== DISK VERIFICATION ==="
lsblk -o NAME,FSTYPE,SIZE,MOUNTPOINT
echo ""
echo "Confirm the NVMe is the 1.8TB disk (should be /dev/nvme0n1)"
echo "Press Enter to continue with disko (DESTRUCTIVE — wipes disk)..."
read -r

# 5. Apply disko (DESTRUCTIVE — wipes the entire disk)
#    You will be prompted for the recovery key — paste the 12-word recovery key
nix --extra-experimental-features 'nix-command flakes' run github:nix-community/disko -- --mode destroy,format,mount --flake .#framey

# 6. Verify mounts are correct (not the USB stick)
echo "=== MOUNT VERIFICATION ==="
mount | grep /mnt
echo ""
echo "Should show /dev/mapper/cryptroot at /mnt, /mnt/boot, /mnt/home, etc."
echo "If you see /dev/sda* (USB stick), STOP — disko hit the wrong disk."
echo "Press Enter to continue with nixos-install..."
read -r

# 7. Install NixOS
nix --extra-experimental-features 'nix-command flakes' run nixpkgs#nixos-install -- --flake .#framey --no-root-password

# 8. Set the user password BEFORE rebooting (avoids being locked out)
nixos-enter --root /mnt -- passwd kusuriya
#    Enter your user password when prompted

echo ""
echo "============================================"
echo "INSTALL COMPLETE"
echo "============================================"
echo "Next steps:"
echo "1. Type 'reboot' and boot into the new system"
echo "2. Enter your 12-word recovery key at the prompt"
echo "3. Log in as root, run: passwd kusuriya"
echo "4. Follow MIGRATION.md for Secure Boot + TPM2 setup"
echo ""
echo "Your encrypted passphrase backup is on dozer at:"
echo "  /data/backup/framey-post-install-$(date +%Y-%m-%d)/luks-passphrase.age"
echo ""
```

### After reboot — post-install steps

Once you've rebooted into the new system and logged in (password was set in step 8 above):

```bash
# 1. Clone the nix config repo onto the new system
#    (clone to ~/nix, not /etc/nixos — avoids git "dubious ownership" errors)
nix-shell -p git --run "git clone https://github.com/kusuriya/nix.git /home/kusuriya/nix"
chown -R kusuriya:users /home/kusuriya/nix
# If you want /etc/nixos to point to the repo:
# ln -s /home/kusuriya/nix /etc/nixos
# Or just use the flake directly: nixos-rebuild --flake /home/kusuriya/nix#framey switch
cd /home/kusuriya/nix

# 3. Copy the age-encrypted passphrase to the new system
cp /data/backup/framey-post-install-$(date +%Y-%m-%d)/luks-passphrase.age /root/
chmod 600 /root/luks-passphrase.age

# 4. Restore SSH host keys (if backed up)
mkdir -p /data/backup/framey-post-install-$(date +%Y-%m-%d)/ssh-keys/ 2>/dev/null
cp /data/backup/framey-post-install-$(date +%Y-%m-%d)/ssh-keys/ssh_host_ed25519_key* /etc/ssh/ 2>/dev/null || echo "No SSH key backup found — new host keys generated"
systemctl restart sshd

# 5. Restore Tailscale (optional — or re-login with 'sudo tailscale up')
# cp -r /data/backup/framey-post-install-$(date +%Y-%m-%d)/tailscale/* /var/lib/tailscale/
```

### If you get locked out (password not set before reboot)

If you rebooted without setting the user password, you can't log in and root has no password.
Boot the NixOS live USB and chroot in:

```bash
# Unlock the LUKS container
cryptsetup luksOpen /dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873-part2 cryptroot
# Enter your 12-word recovery key

# Mount the root subvolume
mount -o subvol=@root,compress=zstd,noatime /dev/mapper/cryptroot /mnt
mount -o subvol=@nix,compress=zstd,noatime /dev/mapper/cryptroot /mnt/nix
mount -o subvol=@home,compress=zstd,noatime /dev/mapper/cryptroot /mnt/home
mount -o subvol=@log,compress=zstd,noatime /dev/mapper/cryptroot /mnt/var/log
mount /dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873-part1 /mnt/boot

# Enter the installed system as root
nixos-enter --root /mnt

# Set the user password
passwd kusuriya

# Exit and reboot
exit
reboot
# Pull the USB before it boots back
```

### Secure Boot setup (one-time, requires BIOS interaction)

```bash
# Step 1: Enter BIOS (F2), set Secure Boot to "Setup Mode" (clears existing platform keys)
#         Reboot back into NixOS

# Step 2: Check if lanzaboote auto-generated keys
sudo sbctl verify
# If keys not found, generate them:
sudo sbctl create-keys

# Step 3: Enroll keys (with Microsoft keys for hardware compatibility)
sudo sbctl enroll-keys --microsoft

# Step 4: Verify all boot artifacts are signed
sudo sbctl verify
# Should show: BOOTX64.EFI, kernel, initrd all signed

# Step 5: Enter BIOS (F2), enable Secure Boot
#         Reboot — system should boot without intervention

# Step 6: Verify Secure Boot is active
bootctl status | grep -i secure
```

### TPM2 LUKS enrollment (one-time, AFTER Secure Boot is set up)

```bash
# Enroll TPM2 with PCR 0+2+7 and required PIN
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+2+7 --tpm2-with-pin=yes /dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873-part2

# You will be prompted to set a PIN — choose a strong numeric PIN (6-8 digits)

# Verify enrollment
sudo cryptsetup luksDump /dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873-part2 | grep -i tpm

# Reboot — should prompt for PIN (not the full recovery key)
reboot
```

### Final verification

```bash
echo "=== Secure Boot ===" && bootctl status | grep -i secure
echo "=== TPM2 ===" && sudo cryptsetup luksDump /dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873-part2 | grep -i tpm
echo "=== btrbk ===" && sudo systemctl status btrbk.timer | head -3
echo "=== autoScrub ===" && sudo systemctl status btrfs-autoScrub | head -3
echo "=== Firewall ===" && sudo iptables -L -n | head -5
echo "=== Audit ===" && sudo systemctl status auditd | head -3
echo "=== AppArmor ===" && sudo aa-status | head -5
```

---

## Post-Install Maintenance

### Re-enroll TPM2 After These Events

The TPM2 unlock uses PCR 0 (firmware) + PCR 2 (boot loader) + PCR 7 (Secure Boot state). If any of these change, the TPM2 unlock will fail and you'll need the passphrase.

```bash
# Re-enroll after firmware updates, boot loader changes, or Secure Boot key changes:
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+2+7 --tpm2-with-pin=yes /dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873-part2
```

**What triggers re-enrollment:**
- BIOS/firmware update (PCR 0 changes)
- Boot loader update (PCR 2 changes) — rare with lanzaboote managing this
- Secure Boot key changes (PCR 7 changes)
- Kernel update — depends on whether the kernel is measured into a PCR you use (it's not with PCR 0+2+7, so kernel updates should NOT require re-enrollment)

**If TPM2 unlock fails:** You'll see a recovery key prompt at boot. Enter your recovery key, boot normally, then re-enroll TPM2.

### Re-enroll Secure Boot After lanzaboote Updates

Lanzaboote automatically re-signs on every NixOS rebuild. No manual action needed for kernel/initrd updates.

If you change Secure Boot keys:
```bash
sudo sbctl create-keys
sudo sbctl enroll-keys --microsoft
sudo sbctl verify
```

### btrfs Maintenance

```bash
# Check filesystem health
sudo btrfs device stats /
sudo btrfs scrub status /

# Manual snapshot
sudo btrbk run framey-snapshots

# List snapshots
ls /.snapshots/

# Clean up old snapshots manually (if needed)
sudo btrbk clean
```

---

## Caveats & Important Notes

### Hibernation

**Hibernation is NOT enabled.** Suspend works normally.

The Linux kernel blocks hibernation when Secure Boot (kernel lockdown mode) is enabled — it can't verify the hibernation image wasn't tampered with. A patchset by Matthew Garrett (mjg59) uses TPM PCR 5 + HMAC to authenticate hibernation images, but it is **not yet merged upstream** as of June 2026.

The 32G swapfile is in place and ready. When the upstream kernel supports secure hibernation, your config should "just work" — systemd initrd already handles resume device/offset auto-detection.

If hibernation is critical, options are:
1. Disable Secure Boot (loses evil-maid protection)
2. Run a custom kernel with the `lockdown_hibernate` patch (maintenance burden)
3. Wait for upstream support (recommended)

### Impermanence

The `@persist` subvolume exists as a placeholder but the [impermanence module](https://github.com/nix-community/impermanence) is **NOT activated**. Full impermanence (tmpfs root with explicit persist list) is high-friction on a daily-driver workstation with many GUI apps that store state in `~/.config` and `~/.local/share`. btrfs snapshots provide the rollback/clean-slate benefit without the maintenance overhead.

If you want to experiment with impermanence in the future:
1. The `@persist` subvolume is already mounted at `/persist`
2. Add the impermanence flake input and module
3. Start by persisting only `/persist/etc` and `/persist/var/lib` — don't go full tmpfs-root immediately

### autoUpgrade

Auto-upgrade is enabled (weekly, Sunday 1AM, 45min random delay) pulling from `nixos-unstable`. This means:
- **Breaking changes are possible** — unstable channel can introduce breaking changes
- **Reboots are NOT automatic** (`allowReboot = false`) — you control when to reboot after an upgrade
- **The next boot could fail** if a breaking change landed — keep the previous generation (systemd-boot keeps 5)
- **Recovery key needed on manual reboot** — TPM2 should handle this if PCR values haven't changed

Consider switching to `nixos-24.11` or `nixos-25.05` stable if stability is more important than bleeding-edge packages.

### TLP vs power-profiles-daemon

TLP is enabled and power-profiles-daemon is disabled. They conflict if both are enabled. TLP provides:
- Charge thresholds (25%/90%) — battery longevity
- CPU governor switching (performance/powersave)
- More granular control than power-profiles-daemon

If you prefer power-profiles-daemon (simpler, GNOME-integrated), disable TLP and enable PPD.

### AppArmor Strictness

`killUnconfinedConfinables = true` means any process without an AppArmor profile is killed. This is very strict and may break some applications that don't have AppArmor profiles. If you encounter issues:
- Check `dmesg | grep apparmor` for denied entries
- Consider setting `killUnconfinedConfinables = false` (still enforces profiles, but allows unconfined processes)

### NFS Mounts

`/data` and `/dozer/files` are NFS mounts from `dozer`. They use `x-systemd.automount noauto` — they only mount when accessed. If `dozer` is offline:
- Accessing `/data` will hang until the NFS timeout (can be 60+ seconds)
- This does NOT affect boot — the automount is lazy

### USBGuard — Removed

USBGuard was removed because class-based rules broke the Caldigit dock (Thunderbolt USB hub). The dock presents multiple interface classes that the class-based allowlist didn't cover properly. Can revisit with per-device-ID rules later when there's time to enumerate all dock devices.

### Kernel Module: amd-pstate

AMD 7040 uses the `amd-pstate` kernel driver for CPU frequency scaling and thermal management. This is handled automatically by the `framework-13-7040-amd` hardware module. `thermald` is NOT enabled (it's Intel-focused and we removed it).

### Sway (Window Manager)

Framey uses Sway (not Hyprland). The PAM config only references `greetd` and `login` services — no `hyprlock` PAM entry. If you switch to Hyprland, add the `hyprlock` PAM entry back.

---

## File Inventory

| File | Purpose |
|------|---------|
| `default.nix` | Main host configuration — boot, networking, security, services, virtualization |
| `disko.nix` | Declarative disk layout — LUKS2 + btrfs subvolumes + swapfile |
| `hardware-configuration.nix` | Generated by `nixos-generate-config` — initrd modules, filesystem UUIDs |
| `packages.nix` | Host-specific packages (desktop, security, GUI apps) — not in shared core |
| `README.md` | This file — documentation and installation runbook |

## Related Files in the Flake

| File | Purpose |
|------|---------|
| `modules/core/default.nix` | Shared core modules — nix settings, udev, substituters |
| `modules/core/packages.nix` | Universal packages installed on ALL hosts |
| `modules/core/nix.nix` | Nix GC, optimization, user permissions |
| `modules/core/home-manager.nix` | Home-manager module import + backup settings |
| `modules/core/kusuriya.nix` | User account, groups, shell |
| `modules/core/oom.nix` | OOM configuration — nix-daemon memory protection |
| `modules/core/polkit.nix` | Polkit rule — allows users to reboot/power-off |
| `modules/core/fonts.nix` | System fonts (Nerd Fonts, Noto, Fira, JetBrains) |
| `modules/core/containers.nix` | Podman + container infrastructure |
| `modules/core/flake-update.nix` | Weekly flake-update timer |
| `modules/core/vfio/default.nix` | Parameterized VFIO module (used by beast, not framey) |
| `modules/desktop/sway/default.nix` | Sway window manager + greetd + fonts |
| `modules/kernel/latest/default.nix` | Latest kernel (`pkgs.linuxPackages_latest`) |
| `home-manager/home.nix` | Home-manager config — fish, fzf, git, neovim, starship, zoxide, atuin, direnv, delta |
| `flake.nix` | Flake entry point — mkSystem helper, overlays, host definitions |
| `overlays/default.nix` | Overlays — unstable packages, stable packages, custom packages |

---

## Flake Inputs Used by Framey

| Input | Purpose |
|-------|---------|
| `nixpkgs` (unstable) | Main package set |
| `nixpkgs-stable` (24.11) | Stable overlay for libvirt/qemu/virt-manager |
| `nixpkgs-unstable` (master) | Unstable overlay for bleeding-edge packages |
| `home-manager` (master) | User environment management |
| `hardware` (nixos-hardware) | `framework-13-7040-amd` + `common-pc-ssd` modules |
| `lanzaboote` | Secure Boot signing (lanzaboote NixOS module) |
| `disko` | Declarative disk partitioning |
| `nixos-cosmic` | COSMIC desktop module (imported but not actively used) |
| `firefox` (flake-firefox-nightly) | Firefox Nightly browser |
| `sops-nix` | Secrets management (imported, not yet actively used on framey) |

---

## Migration Guide

See [MIGRATION.md](./MIGRATION.md) for the step-by-step migration plan covering disk layout changes, package swaps, security hardening additions, and verification procedures.