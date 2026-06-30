# Beast

Gaming and workhorse desktop. Rebuilt from scratch with disko-managed btrfs storage.

## Hardware

| Component | Details |
|-----------|---------|
| CPU | AMD (with KVM support) |
| RAM | 32 GB |
| GPU | AMD Radeon RX 9070 XT (RDNA 4) — primary display + gaming |
| iGPU | Intel (present, not used for display) |
| Storage | 3× 1 TB NVMe |
| Boot | Plain systemd-boot (no Secure Boot) |

## Disk Layout

| Drive | Use | Layout |
|-------|-----|--------|
| NVMe 1 | NixOS (disko-managed) | GPT → ESP (1 GB) + btrfs (single device) |
| NVMe 2 | NixOS pool member | Added to btrfs pool post-install (manual `btrfs device add`) |
| NVMe 3 | Reserved | Unformatted — future Windows |

**Why not multi-device disko?** Disko does not support btrfs multi-device volumes
(issue [#261](https://github.com/nix-community/disko/issues/261) — open, PR #482 closed
without merge). Drive 2 is added to the pool manually after first boot. See
"Post-Install: Add Second NVMe" below.

### Btrfs Subvolumes (on NVMe 1, expanded to NVMe 2 post-install)

| Subvolume | Mount | Purpose |
|-----------|-------|---------|
| `@root` | `/` | OS root |
| `@home` | `/home` | User home directories |
| `@nix` | `/nix` | Nix store isolation |
| `@log` | `/var/log` | Logs (separate for snapshot exclusion) |
| `@snapshots` | `/.snapshots` | btrbk snapshot target |
| `@persist` | `/persist` | Placeholder for future impermanence |

**No encryption.** No redundancy (single profile — if either NVMe fails, the pool is lost).
Swap is a 16 GB swapfile, auto-created by NixOS at `/swapfile`.

## GPU Configuration

- **AMD Radeon RX 9070 XT (RDNA 4)** — primary GPU for all displays and gaming
- Driver: `amdgpu` kernel driver (built-in, no separate driver package)
- `hardware.amdgpu.initrd.enable = true` — early KMS for Plymouth
- `hardware.graphics.enable = true` — VA-API hardware video acceleration
- Monitoring: `amdgpu_top`, `radeontop`, `vulkaninfo`
- CoreCtrl installed for GPU tuning and fan curves

## Desktop

- **Sway** via greetd (no Plasma6, no display manager)
- Wayland-only with XWayland support

## Gaming

| Tool | Purpose |
|------|---------|
| Steam | Primary game launcher (with proton-ge-bin) |
| Lutris | GOG, Epic, standalone games |
| Heroic | Epic Games + GOG launcher |
| Bottles | Wine prefix manager |
| mcpelauncher-ui-qt | Minecraft Bedrock Edition (Android version) |
| gamescope | Steam session micro-compositor |

## Networking

- **NetworkManager** — primary network management
- **Tailscale** — VPN mesh, SSH accessible on `tailscale0` interface (port 22)
- **Avahi/mDNS** — service discovery, firewall open
- **KDE Connect** — ports 1714-1764 TCP+UDP open
- **NFS** — automounts from dozer NAS (`/data`, `/dozer/files`)
- **Samba** — minimal share at `/home/kusuriya/shared`

## Snapshots

Automated via [btrbk](https://github.com/digint/btrbk) — hourly snapshots with tiered retention:
- Minimum: 2 days of all snapshots
- 48 hourly, 14 daily, 8 weekly, 6 monthly

```bash
sudo systemctl status btrbk.timer
sudo btrbk run beast-snapshots
sudo btrbk clean
```

## Virtualization

- **libvirtd/QEMU** — retained for non-passthrough VMs
- No VFIO, no Looking Glass, no kvmfr
- Supports Windows VMs (swtpm + OVMF firmware paths configured)
- QEMU security wrapper with `cap_net_admin` for bridged networking

## Printing

Drivers for HP and Canon printers (gutenprint, hplipWithPlugin, canon-cups-ufr2).
Also includes LabelRange RD560 label printer driver.

## Kernel Hardening

Sysctls adapted from framey: kptr_restrict, dmesg_restrict, perf_event_paranoid,
yama.ptrace_scope, network hardening (rp_filter, redirect blocking, SYN cookies),
TCP BBR, swappiness=10, dirty ratios.

## Auto-Upgrade

Weekly `nixos-rebuild switch` via `system.autoUpgrade`. No automatic reboots.

## Fresh Install

### Option 1: NixOS Anywhere (recommended — one-shot)

NixOS Anywhere handles disko partitioning + nixos-install in a single command.
Boot the NixOS install media, then:

```bash
# Find your NVMe by-id paths
ls -l /dev/disk/by-id/ | grep nvme

# Clone the flake
sudo nix-shell -p git --run 'git clone https://github.com/kusuriya/nix /tmp/nix'
cd /tmp/nix

# Patch disko.nix with real device path (replace placeholder)
sed -i 's|nvme-REPLACE_WITH_DRIVE_1_ID|YOUR_DRIVE_1_ID|' hosts/beast/disko.nix

# Run nixos-anywhere (disko + install in one shot, auto-reboots)
nix run github:nix-community/nixos-anywhere -- \
  --flake .#beast \
  --generate-hardware-config nixos-generate-config hosts/beast/hardware-configuration.nix
```

Or use the install script with `--anywhere`:

```bash
sudo bash hosts/beast/install.sh --anywhere /dev/disk/by-id/nvme-DRIVE_1_ID /dev/disk/by-id/nvme-DRIVE_2_ID
```

### Option 2: Manual disko + nixos-install (classic)

```bash
# Find your NVMe by-id paths
ls -l /dev/disk/by-id/ | grep nvme

# Clone and run the install script
sudo nix-shell -p git --run 'git clone https://github.com/kusuriya/nix /tmp/nix && cd /tmp/nix'
cd /tmp/nix
sudo bash hosts/beast/install.sh /dev/disk/by-id/nvme-DRIVE_1_ID /dev/disk/by-id/nvme-DRIVE_2_ID
```

The script does everything: clones the flake, patches `disko.nix` with your real
device paths, runs disko, installs NixOS, and reboots.

### Dry run (no changes, just validates)

```bash
sudo bash hosts/beast/install.sh --dry-run /dev/disk/by-id/nvme-DRIVE_1_ID /dev/disk/by-id/nvme-DRIVE_2_ID
```

### Install over SSH (remote target)

If beast is already running something (e.g. an old OS) and is reachable via SSH:

```bash
# From your local machine (must have nix + flakes enabled)
nix run github:nix-community/nixos-anywhere -- \
  --flake github:kusuriya/nix#beast \
  --target-host root@beast.lan.corrupted.io \
  --generate-hardware-config nixos-generate-config hosts/beast/hardware-configuration.nix
```

Note: This requires the disko.nix placeholder to already be replaced with the real
device path. Fork the repo or clone + patch locally, then point `--flake` at your
local path.

## Post-Install: Add Second NVMe

After first boot, add NVMe 2 to the btrfs pool and create the swapfile:

```bash
# Add NVMe 2 to the btrfs pool (replace with actual by-id path)
sudo btrfs device add /dev/disk/by-id/nvme-DRIVE_2_ID /

# Balance to spread data across both devices
sudo btrfs balance start -dusage=100 /

# Create the swap subvolume and swapfile (kernel 6.1+ handles NODATACOW automatically)
sudo btrfs subvolume create /.swapvol
sudo btrfs filesystem mkswapfile --size 16G /.swapvol/swapfile

# Verify
sudo btrfs filesystem show /
swapon --show
```

Or run the post-install script:

```bash
sudo bash hosts/beast/post-install.sh /dev/disk/by-id/nvme-DRIVE_2_ID
```

Update `disko.nix` with the actual device paths for future reproducibility.

## Post-Install: Tailscale

```bash
sudo tailscale up
```

## Post-Install: Verify GPU

```bash
sudo lspci -nn | grep -i amd
vulkaninfo | head -20
glxinfo | grep "OpenGL renderer"
amdgpu_top --version
```

## Post-Install: Minecraft Bedrock

```bash
mcpelauncher-ui-qt
```

Sign in with your Google Play account that owns Minecraft Bedrock.

## Post-Install: Verify NFS

```bash
ls /data
ls /dozer/files
```

## Troubleshooting

### GPU Driver Not Loading

```bash
lsmod | grep amdgpu
dmesg | grep -i amdgpu
sudo nixos-rebuild switch --flake .#beast
```

### Btrfs Multi-Device Issues

```bash
sudo btrfs device stats /
sudo btrfs device scan
```

### Boot Failure

1. Boot from NixOS install media
2. `sudo mount /dev/disk/by-id/nvme-DRIVE_1_ID-part2 /mnt`
3. `sudo nixos-enter --root /mnt`
4. `journalctl -b -p err`
5. `nixos-rebuild switch --flake .#beast`