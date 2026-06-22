# Beast Migration Runbook

Step-by-step guide for a fresh NixOS install on beast using disko + the flake.

## Pre-flight Checklist

- [ ] Boot from NixOS install media (latest unstable ISO recommended)
- [ ] Backup any data from drives 1+2 (disko will DESTROY them)
- [ ] Drive 3 has no data OR data you don't want to keep (it stays untouched)
- [ ] Network connection available (for cloning the flake + downloading packages)
- [ ] You have the Tailscale auth key or can `tailscale up` interactively

## Step 1: Boot NixOS Install Media

Boot from a NixOS unstable ISO (USB). Select the default boot option.

## Step 2: Identify Disks

```bash
ls -l /dev/disk/by-id/ | grep nvme
```

Note the by-id paths for all 3 NVMe drives. You'll need the two that will be used for NixOS.

Example output:
```
nvme-Samsung_SSD_980_1TB_S123456789 → /dev/nvme0n1
nvme-Samsung_SSD_980_1TB_S987654321 → /dev/nvme1n1
nvme-WD_BLACK_SN850X_1TB_ABC123     → /dev/nvme2n1
```

**IMPORTANT:** Verify which drives are which. If you pick the wrong ones, you'll lose data on the wrong disks.

## Step 3: Clone the Flake

```bash
sudo nix-shell -p git --run 'git clone https://github.com/kusuriya/nix /tmp/nix'
cd /tmp/nix
```

## Step 4: Update disko.nix with Real Device Paths

Edit `hosts/beast/disko.nix` and replace the two PLACEHOLDER device lines:

```nix
# Replace these:
device = "/dev/disk/by-id/nvme-REPLACE_WITH_DRIVE_1_ID";
device = "/dev/disk/by-id/nvme-REPLACE_WITH_DRIVE_2_ID";

# With the actual by-id paths from Step 2, e.g.:
device = "/dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S123456789";
device = "/dev/disk/by-id/nvme-Samsung_SSD_980_1TB_S987654321";
```

## Step 5: Run Disko (DESTRUCTIVE)

**This wipes drives 1 and 2 completely.** Drive 3 is untouched.

```bash
# Dry run first — verify what disko will do
sudo nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#beast --dry-run

# If the dry run looks correct:
sudo nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#beast
```

### If Disko Multi-Device Fails

Disko's multi-device btrfs support may not work as expected. If the above fails:

**Fallback: Single-disk disko + manual device add**

1. Temporarily modify `disko.nix` to use only drive 1 (comment out the `nvme2` disk block)
2. Run disko on the single disk
3. Install NixOS (Steps 6-7 below)
4. After first boot, manually add drive 2:
   ```bash
   # Add drive 2 to the btrfs pool
   sudo btrfs device add /dev/disk/by-id/nvme-DRIVE_2_ID /

   # Balance to spread data across both devices
   sudo btrfs balance start -dusage=0 /
   ```
5. Update `disko.nix` back to the 2-disk config for future reproducibility

## Step 6: Install NixOS

```bash
# Generate hardware config (disko already created the mounts)
sudo nixos-generate-config --no-roots --root /mnt

# Install using the flake
sudo nixos-install --flake .#beast --root /mnt
```

When prompted, set the root password and user password.

## Step 7: Reboot

```bash
sudo reboot
```

Remove the install media when prompted.

## Step 8: Post-Install Setup

### Tailscale

```bash
sudo tailscale up
```

Authenticate via the URL provided.

### Verify NVIDIA

```bash
# Check driver is loaded
nvidia-smi

# Check Vulkan
vulkaninfo | head -20

# Check OpenGL
glxinfo | grep "OpenGL renderer"
```

### Verify Btrfs Multi-Device

```bash
# Should show both NVMe devices
sudo btrfs filesystem show /

# Check mount options
mount | grep btrfs
```

### Verify btrbk

```bash
# Check timer
sudo systemctl status btrbk.timer

# Run first snapshot manually
sudo btrbk run beast-snapshots

# Verify snapshots exist
ls /.snapshots/
```

### Minecraft Bedrock

```bash
# Launch mcpelauncher
mcpelauncher-ui-qt
```

You'll need to sign in with your Google Play account that owns Minecraft Bedrock.

### NFS Mounts

```bash
# Verify NFS automounts
ls /data
ls /dozer/files
```

## Troubleshooting

### NVIDIA Driver Not Loading

```bash
# Check if module is loaded
lsmod | grep nvidia

# Check dmesg
dmesg | grep -i nvidia

# Rebuild
sudo nixos-rebuild switch --flake .#beast
```

### Btrfs Multi-Device Issues

```bash
# Check device status
sudo btrfs device stats /

# If a device is missing
sudo btrfs device scan
```

### Boot Failure

If beast fails to boot after install:
1. Boot from NixOS install media
2. Mount the root filesystem: `sudo mount /dev/disk/by-id/nvme-DRIVE_1_ID-part2 /mnt` (adjust partition)
3. `sudo nixos-enter --root /mnt`
4. Check logs: `journalctl -b -p err`
5. Rebuild: `nixos-rebuild switch --flake .#beast`