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

## Fresh Install (at beast's local NixOS installer console)

Use disko to partition, format, and mount the target disk, then `nixos-install`
with this flake. **This destroys the selected disk, including all existing
partitions and data.** It does not install to the other NVMe drives unless you
select one of them as the disko target. Back up anything you need first.

`nixos-anywhere` is for installing **over SSH from another machine**. It requires
an SSH target; do not run it at this local console. Do not use `install.sh` as
currently written: it tries to replace an old placeholder, but `disko.nix`
currently contains the concrete path `/dev/nvme0n1`. Passing a different drive
to the script will *not* change the disko target. Its `--dry-run` is not a disk
safety check either.

1. Boot the NixOS installer in UEFI mode and obtain a checkout. If `/tmp/nix`
   already exists, use that checkout; otherwise clone it (install Git with
   `nix-shell -p git` first if needed):

   ```bash
   git clone https://github.com/kusuriya/nix /tmp/nix
   cd /tmp/nix
   ```

2. Identify the **whole disk** intended for NixOS by model, size, and serial.
   Do not use a `-partN` partition path; NVMe numbers like `/dev/nvme0n1` can
   change between boots. Match the by-id symlink to the physical disk:

   ```bash
   lsblk -o NAME,SIZE,MODEL,SERIAL,TYPE,MOUNTPOINTS
   ls -l /dev/disk/by-id/
   readlink -f /dev/disk/by-id/nvme-YOUR_WHOLE_DISK_ID
   ```

3. Edit `hosts/beast/disko.nix`: replace its `device = "/dev/nvme0n1";`
   with `device = "/dev/disk/by-id/<NIXOS_WHOLE_DISK_ID>";` using the **actual**
   whole-disk ID from step 2. The comments in that file still call the path a
   placeholder, but the value is real and potentially dangerous. Confirm what
   the flake will hand to disko, then independently compare it to `lsblk`:

   ```bash
   nix --extra-experimental-features 'nix-command flakes' \
     eval --raw .#nixosConfigurations.beast.config.disko.devices.disk.nvme1.device
   ```

   Evaluation checks the config value, **not** whether it is the disk you mean
   to erase. Stop if there is any doubt about the serial or target. Only the
   first drive is managed by disko; leave the second and reserved third drive
   alone during installation.

4. **Destructive step:** partition, format, and mount the selected disk at
   `/mnt`, then verify that root and boot (and the other declared subvolumes)
   are actually mounted before installing:

   ```bash
   sudo nix --extra-experimental-features 'nix-command flakes' \
     run github:nix-community/disko -- \
     --mode destroy,format,mount --flake .#beast
   findmnt -R /mnt
   ```

5. This flake already imports `hosts/beast/disko.nix` and its manually
   maintained `hosts/beast/hardware-configuration.nix`. Disko supplies the
   filesystem mounts; **do not regenerate hardware-configuration.nix with
   `nixos-generate-config`**, which can add conflicting filesystem definitions.
   With `/mnt` mounted, install from this edited checkout:

   ```bash
   sudo nixos-install --flake /tmp/nix#beast --root /mnt
   ```

   Follow the installer prompts. If the build or install fails, fix the error
   before rebooting; a successful disko run is not a successful OS install.
   Keep a copy of your corrected `disko.nix` for future rebuilds: `/tmp/nix`
   is temporary, and editing it does not update GitHub.

## Post-Install: Second NVMe and swap

The installed config declares a 16 GiB `/swapfile` via `swapDevices` in
`default.nix`. Check `swapon --show` after first boot. **Do not follow the old
post-install instructions or run `post-install.sh` to add the second NVMe as-is.**
That script adds a device and starts a balance while a Btrfs swapfile may be
active, and it does not actually create the swapfile it claims to create.
Btrfs documents restrictions on active swapfiles, multi-device filesystems,
balance, and scrub: <https://btrfs.readthedocs.io/en/latest/Swapfile.html>.
Choose and configure a compatible swap strategy before changing the pool; this
is a separate, data-affecting migration, not a required part of the fresh
install. Keep the third NVMe untouched.

After the installed system boots, copy or clone the repo to a persistent
location, carry over the verified disk ID change, and commit it intentionally.
Never replace a by-id path with a guessed `/dev/nvmeXnY` name.

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

Boot the NixOS install media again. The root filesystem is the Btrfs `@root`
subvolume, not a plain mount of partition 2; the EFI partition must also be
mounted at `/mnt/boot` for bootloader repair. Use the **same** checkout with the
verified by-id disk path from the installation, and mount the existing layout
without formatting:

```bash
cd /tmp/nix
sudo nix --extra-experimental-features 'nix-command flakes' \
  run github:nix-community/disko -- --mode mount --flake .#beast
findmnt -R /mnt
```

**Use `--mode mount`, never `destroy,format,mount`, for recovery.** Check the
mounts and error before attempting a repair; a failed boot alone does not say
whether the problem is the bootloader, kernel, filesystem, or system config.
The `/tmp/nix` checkout will be gone after reboot, so clone it again and apply
the correct disk ID before the mount command if necessary.
