# Beast

Gaming and workhorse desktop. Rebuilt from scratch with disko-managed btrfs storage.

## Hardware

| Component | Details |
|-----------|---------|
| CPU | AMD (with KVM support) |
| RAM | 32 GB |
| GPU | NVIDIA RTX 3060 (Ampere GA106) — primary display + gaming |
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
Swap is a 16 GB swapfile, created post-install after the second NVMe is added.

## GPU Configuration

- **NVIDIA RTX 3060** — primary GPU for all displays and gaming
- Driver: `nvidia-open` kernel modules (`hardware.nvidia.open = true`)
- `hardware.nvidia.modesetting.enable = true` — required for Wayland
- `hardware.nvidia.powerManagement.enable = true` — display stability
- `hardware.nvidia.nvidiaSettings = true` — nvidia-settings GUI

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

```bash
# 1. Boot NixOS install media
# 2. Clone the flake
sudo nix-shell -p git --run 'git clone https://github.com/kusuriya/nix /tmp/nix && cd /tmp/nix'

# 3. Verify disk by-id paths
ls -l /dev/disk/by-id/

# 4. Edit hosts/beast/disko.nix — replace PLACEHOLDER device path with actual by-id for NVMe 1
# 5. Run disko (DESTRUCTIVE — wipes NVMe 1 only)
sudo nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#beast

# 6. Install NixOS
sudo nixos-generate-config --no-roots --root /mnt
sudo nixos-install --flake .#beast --root /mnt

# 7. Reboot
sudo reboot
```

## Post-Install: Add Second NVMe

After first boot, add NVMe 2 to the btrfs pool and create the swapfile:

```bash
# Add NVMe 2 to the btrfs pool (replace with actual by-id path)
sudo btrfs device add /dev/disk/by-id/nvme-DRIVE_2_ID /

# Balance to spread data across both devices
sudo btrfs balance start -dusage=100 /

# Create 16 GB swapfile (kernel 6.1+ handles NODATACOW automatically)
sudo btrfs filesystem mkswapfile --size 16G /.swapvol/swapfile

# Verify
sudo btrfs filesystem show /
swapon --show
```

Update `disko.nix` with the actual device paths for future reproducibility.

## Post-Install: Tailscale

```bash
sudo tailscale up
```

## Post-Install: Verify NVIDIA

```bash
nvidia-smi
vulkaninfo | head -20
glxinfo | grep "OpenGL renderer"
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

### NVIDIA Driver Not Loading

```bash
lsmod | grep nvidia
dmesg | grep -i nvidia
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