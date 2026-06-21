# Framey — Framework 13 AMD Laptop

Primary workstation. Security-hardened NixOS with LUKS2 full-disk encryption, btrfs, Secure Boot, and TPM2 auto-unlock.

---

## Hardware

| Component | Spec |
|-----------|------|
| **Model** | Framework 13 (AMD) |
| **CPU** | AMD Ryzen 7 7040 (8c/16t) |
| **RAM** | 32GB |
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
/dev/nvme0n1
├── p1: ESP (1G, vfat)         → /boot          [unencrypted — kernel + initrd live here]
└── p2: LUKS2 (cryptroot)       → /dev/mapper/cryptroot
      └── btrfs (zstd compression, noatime)
          ├── @root              → /
          ├── @home              → /home
          ├── @nix               → /nix
          ├── @log               → /var/log      [separate for snapshot exclusion]
          ├── @swap              → /.swapvol     [32G swapfile, encrypted]
          └── @persist           → /persist      [placeholder for future impermanence]
```

**Why this layout:**
- **LUKS2** — full-disk encryption, protects data at rest
- **btrfs** — snapshots, compression, subvolumes for flexible management
- **@log separate** — excludes noisy logs from root snapshots
- **@swap inside LUKS** — swap is encrypted (no cleartext swap leak)
- **@persist placeholder** — not actively used; reserved for potential future impermanence setup
- **32G swapfile** — matches RAM size, required for hibernation (currently suspended-only, see Caveats)

### Secure Boot

Enabled via [lanzaboote](https://github.com/nix-community/lanzaboote) — wraps systemd-boot with UEFI Secure Boot signing.

- **User-controlled keys** via `sbctl` — you generate and enroll your own keys
- **Microsoft keys enrolled** alongside user keys for hardware compatibility (firmware updates, Option ROMs)
- **Kernel + initrd signed** at build time — lanzaboote automatically signs all boot artifacts
- **sbctl** included in systemPackages for key management and verification

**Threat model:** Protects against evil-maid attacks and boot-level malware. An attacker with physical access cannot boot an unsigned kernel or modify boot configuration without detection. This is appropriate for a laptop that travels.

### TPM2 Auto-Unlock

The LUKS2 container auto-unlocks via TPM2 at boot — no passphrase entry required for normal boots.

- **PCRs used:** 0 (firmware) + 2 (boot loader) + 7 (Secure Boot state)
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

### Network Security

- **Firewall:** enabled, no ping, SSH via Tailscale only (port 22 on `tailscale0` interface)
- **Tailscale:** client mode, userspace networking
- **NetworkManager:** MAC randomization on scan, WiFi powersave disabled
- **No ports exposed** to local network or internet (Avahi opens its own via `openFirewall = true`)

### Access Control

- **AppArmor:** enabled, `killUnconfinedConfinables = true` (processes without a profile are killed)
- **USBGuard:** class-based allowlist — allows mass storage, HID, and Bluetooth classes; blocks everything else by default
- **TPM2:** PKCS11 + TCTI environment enabled (used for LUKS unlock and potential future smart card use)
- **1Password:** GUI + CLI + polkit integration
- **sudo:** requires password (`wheelNeedsPassword = true`)
- **Audit:** `audit.enable = true` + `auditd.enable = true` — kernel audit trail enabled

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
- **zramSwap** 50% zstd (16GB compressed swap in RAM)
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

### Prerequisites

- NixOS install media (USB)
- The flake repo accessible (clone from GitHub or have it on a USB drive)
- **Back up `/home`** — this procedure is destructive
- `/data` and `/dozer/files` are NFS mounts on dozer and are unaffected

### Step 1: Boot NixOS Live Media

Boot from the NixOS install USB. If the laptop won't boot from USB:
- Framework 13: press F12 for boot menu, or F2 for BIOS
- Disable Secure Boot in BIOS temporarily (it will be re-enabled later)

### Step 2: Verify the disk

```bash
lsblk
# Confirm the NVMe is /dev/nvme0n1
# If it's a different device name, update disko.nix before proceeding
```

### Step 3: Clone the flake repo

```bash
# If networking is available:
nix-shell -p git --run "git clone https://github.com/kusuriya/nix.git /tmp/nix"
cd /tmp/nix

# If offline, mount the USB with the repo:
# mount /dev/sdX1 /mnt && cp -r /mnt/nix /tmp/nix && cd /tmp/nix
```

### Step 4: Apply disko (DESTRUCTIVE — wipes the disk)

```bash
# This formats the disk with LUKS2 + btrfs per disko.nix
# It will prompt for the LUKS passphrase — choose a strong one
nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#framey
```

**What this does:**
1. Wipes all partitions on `/dev/nvme0n1`
2. Creates the ESP (1G vfat) and LUKS2 container
3. Formats the LUKS container with btrfs subvolumes
4. Creates the 32G swapfile
5. Mounts everything at the correct paths

### Step 5: Install NixOS

```bash
nixos-install --flake .#framey --no-root-password
```

The `--no-root-password` flag is intentional — you'll use `sudo` with your wheel user. Set the kusuriya user password after first boot.

### Step 6: Reboot into the new system

```bash
reboot
# The system should boot and prompt for the LUKS passphrase
# Enter the passphrase you set in Step 4
```

### Step 7: Set user password

```bash
# Log in as root (or use the console)
passwd kusuriya
# Set a strong password
```

### Step 8: Secure Boot Setup (one-time)

This must be done before enabling Secure Boot in firmware.

```bash
# Enter BIOS, set Secure Boot to "Setup Mode"
# This clears existing platform keys
# Reboot back into NixOS

# Generate Secure Boot keys
sudo sbctl create-keys

# Enroll keys (with Microsoft keys for hardware compatibility)
sudo sbctl enroll-keys --microsoft

# Verify all boot artifacts are signed
sudo sbctl verify
# Should show: BOOTX64.EFI, kernel, initrd all signed

# Enter BIOS, enable Secure Boot
# Reboot — system should boot without intervention
```

### Step 9: TPM2 LUKS Enrollment (one-time)

This adds TPM2 as an auto-unlock method. Must be done AFTER Secure Boot is set up (PCR 7 includes Secure Boot state).

```bash
# Enroll TPM2 with PCR 0+2+7
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+2+7 /dev/nvme0n1p2

# Verify enrollment
sudo cryptsetup luksDump /dev/nvme0n1p2
# Should show a TPM2 slot in the LUKS2 header

# Reboot — should auto-unlock via TPM2 without passphrase prompt
reboot
```

### Step 10: USBGuard Policy Generation (one-time)

Generate an allowlist from currently-connected devices:

```bash
# Generate policy from current devices
sudo usbguard generate-policy > /tmp/rules.conf
sudo cp /tmp/rules.conf /etc/usbguard/rules.conf
sudo systemctl restart usbguard

# Verify
sudo usbguard list-devices
# Should show your devices as "allow"
```

### Step 11: Verify everything

```bash
# Secure Boot is active
bootctl status
# or: mokutil --sb-state (if available)

# TPM2 is enrolled
sudo cryptsetup luksDump /dev/nvme0n1p2 | grep -i tpm

# USBGuard is running
sudo systemctl status usbguard

# btrbk snapshots are scheduled
sudo systemctl status btrbk.timer

# Firewall is active
sudo iptables -L -n | head

# Audit is running
sudo systemctl status auditd

# AppArmor is loaded
sudo aa-status | head
```

---

## Post-Install Maintenance

### Re-enroll TPM2 After These Events

The TPM2 unlock uses PCR 0 (firmware) + PCR 2 (boot loader) + PCR 7 (Secure Boot state). If any of these change, the TPM2 unlock will fail and you'll need the passphrase.

```bash
# Re-enroll after firmware updates, boot loader changes, or Secure Boot key changes:
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto --tpm2-pcrs=0+2+7 /dev/nvme0n1p2
```

**What triggers re-enrollment:**
- BIOS/firmware update (PCR 0 changes)
- Boot loader update (PCR 2 changes) — rare with lanzaboote managing this
- Secure Boot key changes (PCR 7 changes)
- Kernel update — depends on whether the kernel is measured into a PCR you use (it's not with PCR 0+2+7, so kernel updates should NOT require re-enrollment)

**If TPM2 unlock fails:** You'll see a passphrase prompt at boot. Enter your LUKS passphrase, boot normally, then re-enroll TPM2.

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

### USBGuard — Adding New Devices

```bash
# See what's connected
sudo usbguard list-devices

# Temporarily allow a device
sudo usbguard allow-device <id>

# Permanently allow a device (add to rules)
sudo usbguard generate-policy >> /etc/usbguard/rules.conf
# Edit to merge with existing rules
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
- **LUKS passphrase needed on manual reboot** — TPM2 should handle this if PCR values haven't changed

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

### USBGuard First Boot

On the first boot after install, USBGuard's default policy blocks all USB devices except those in the allowlist. **Before generating the policy** (Step 10), USBGuard may block your keyboard/mouse if they're USB-connected. The Framework 13's built-in keyboard and trackpad are not USB devices (they're internal), so they should work. External USB keyboards/mice/docks will be blocked until the policy is generated.

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