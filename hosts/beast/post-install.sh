#!/usr/bin/env bash
# =============================================================================
# Beast Post-Install Script
# =============================================================================
# Run this after first boot to:
#   1. Add the second NVMe to the btrfs pool
#   2. Balance data across both devices
#   3. Create the 16GB swapfile
#   4. Set up Tailscale
#   5. Verify AMD GPU
#   6. Verify NFS mounts
#
# Usage:
#   sudo bash post-install.sh /dev/disk/by-id/nvme-DRIVE_2_ID
#
# =============================================================================

set -euo pipefail

DRIVE_2="${1:-}"

if [[ -z "$DRIVE_2" ]]; then
  echo "ERROR: No drive specified."
  echo ""
  echo "Usage: sudo bash post-install.sh /dev/disk/by-id/nvme-DRIVE_2_ID"
  echo ""
  echo "Available NVMe devices:"
  ls -l /dev/disk/by-id/ | grep nvme
  exit 1
fi

if [[ ! -b "$DRIVE_2" ]]; then
  echo "ERROR: $DRIVE_2 is not a valid block device."
  exit 1
fi

echo "============================================"
echo " Beast Post-Install Setup"
echo "============================================"
echo " Drive 2 (pool member): $DRIVE_2"
echo "============================================"
echo ""

# --- Step 1: Add NVMe 2 to btrfs pool ---
echo "[1/6] Adding $DRIVE_2 to btrfs pool..."
if btrfs filesystem show / | grep -q "$DRIVE_2"; then
  echo "  $DRIVE_2 is already in the pool — skipping."
else
  btrfs device add "$DRIVE_2" /
fi
echo "  Done."
echo ""

# --- Step 2: Balance ---
echo "[2/6] Balancing data across both devices..."
echo "  (This may take a few minutes for a fresh install)"
btrfs balance start -dusage=100 /
echo "  Done."
echo ""

# --- Step 3: Create swap ---
echo "[3/6] Creating 16GB swapfile..."
if [[ -f /.swapvol/swapfile ]]; then
  echo "  Swapfile already exists — skipping."
else
  btrfs subvolume create /.swapvol
  btrfs filesystem mkswapfile --size 16G /.swapvol/swapfile
fi
swapon --show
echo "  Done."
echo ""

# --- Step 4: Tailscale ---
echo "[4/6] Setting up Tailscale..."
if command -v tailscale &>/dev/null; then
  echo "  Running 'tailscale up' — follow the URL to authenticate:"
  tailscale up
else
  echo "  WARNING: tailscale not found. Install it via nixos-rebuild first."
fi
echo "  Done."
echo ""

# --- Step 5: Verify AMD GPU ---
echo "[5/6] Verifying AMD GPU..."
if lsmod | grep -q amdgpu; then
  echo "  amdgpu kernel module: loaded"
  echo "  GPU devices:"
  lspci | grep -i amd | grep -i vga
  echo ""
  echo "  Verify with: glxinfo | grep 'OpenGL renderer'"
  echo "  ROCm/OpenCL: clinfo | grep -i 'Device Name'"
else
  echo "  WARNING: amdgpu module not loaded"
  echo "  Check: lspci | grep VGA"
  echo "  Rebuild: sudo nixos-rebuild switch --flake .#beast"
fi
echo ""

# --- Step 6: Verify NFS ---
echo "[6/6] Verifying NFS mounts..."
echo "  /data:"
if ls /data &>/dev/null; then
  echo "    OK"
else
  echo "    WARNING: /data not accessible (dozer NAS may be offline)"
fi
echo "  /dozer/files:"
if ls /dozer/files &>/dev/null; then
  echo "    OK"
else
  echo "    WARNING: /dozer/files not accessible (dozer NAS may be offline)"
fi
echo ""

echo "============================================"
echo " Post-install setup complete!"
echo "============================================"
echo ""
echo "Next steps:"
echo "  - Launch Minecraft Bedrock: mcpelauncher-ui-qt"
echo "  - Verify btrfs pool: sudo btrfs filesystem show /"
echo "  - Update disko.nix with the real device paths for reproducibility"
echo "  - Git commit + push the updated config"