# Beast

Gaming and workhorse desktop. Rebuilt from scratch with disko-managed btrfs multi-device storage.

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
| NVMe 1 | NixOS | GPT → ESP (1 GB) + btrfs member 1 |
| NVMe 2 | NixOS | GPT → btrfs member 2 (multi-device JBOD with drive 1) |
| NVMe 3 | Reserved | Unformatted — future Windows dual-boot |

### Btrfs Subvolumes (multi-device pool spanning NVMe 1+2)

| Subvolume | Mount | Purpose |
|-----------|-------|---------|
| `@root` | `/` | OS root |
| `@home` | `/home` | User home directories |
| `@nix` | `/nix` | Nix store isolation |
| `@log` | `/var/log` | Logs (separate for snapshot exclusion) |
| `@snapshots` | `/.snapshots` | btrbk snapshot target |
| `@swap` | `/.swapvol` | 16 GB swapfile (no hibernation) |
| `@persist` | `/persist` | Placeholder for future impermanence |

**No encryption.** No redundancy (JBOD/single profile) — if either NVMe 1 or 2 fails, the entire filesystem is lost.

## GPU Configuration

- **NVIDIA RTX 3060** — primary GPU for all displays and gaming
- Driver: `nvidia-open` kernel modules (`hardware.nvidia.open = true`)
- `hardware.nvidia.modesetting.enable = true` — required for Wayland
- `hardware.nvidia.powerManagement.enable = true` — display stability

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
# Check status
sudo systemctl status btrbk.timer

# Manual snapshot run
sudo btrbk run beast-snapshots

# Clean old snapshots
sudo btrbk clean
```

## Virtualization

- **libvirtd/QEMU** — retained for non-passthrough VMs
- No VFIO, no Looking Glass, no kvmfr
- Supports Windows VMs (swtpm + OVMF available)

## Printing

Drivers for HP and Canon printers (gutenprint, hplipWithPlugin, canon-cups-ufr2).

## Auto-Upgrade

Weekly `nixos-rebuild switch` via `system.autoUpgrade`. No automatic reboots.

## Installation (Fresh Install from NixOS Install Media)

See [MIGRATION.md](./MIGRATION.md) for the full runbook.

Quick reference:

```bash
# 1. Boot NixOS install media
# 2. Clone the flake
sudo nix-shell -p git --run 'git clone https://github.com/kusuriya/nix /tmp/nix && cd /tmp/nix'

# 3. Verify disk by-id paths
ls -l /dev/disk/by-id/

# 4. Edit disko.nix — replace PLACEHOLDER device paths with actual by-id paths
# 5. Run disko (DESTRUCTIVE — wipes drives 1+2)
sudo nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#beast

# 6. Generate and install
sudo nixos-generate-config --no-roots --root /mnt
sudo nixos-install --flake .#beast --root /mnt
```