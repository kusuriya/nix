#!/usr/bin/env bash
# =============================================================================
# Beast NixOS Install Script
# =============================================================================
# Run this from the NixOS install media after booting.
#
# Two install methods supported:
#
#   1. NixOS Anywhere (recommended — does disko + install in one shot)
#      sudo bash install.sh --anywhere /dev/disk/by-id/nvme-DRIVE_1_ID /dev/disk/by-id/nvme-DRIVE_2_ID
#
#   2. Manual disko + nixos-install (the classic way)
#      sudo bash install.sh /dev/disk/by-id/nvme-DRIVE_1_ID /dev/disk/by-id/nvme-DRIVE_2_ID
#
#   Dry run (no changes, just validates):
#      sudo bash install.sh --dry-run /dev/disk/by-id/nvme-DRIVE_1_ID /dev/disk/by-id/nvme-DRIVE_2_ID
#
# Both methods:
#   1. Clone the flake
#   2. Patch disko.nix with your real device paths
#   3. Run disko (DESTRUCTIVE — wipes drive 1)
#   4. Install NixOS
#   5. Reboot
#
# After reboot, run post-install.sh (see README.md "Post-Install" section)
#
# =============================================================================

set -euo pipefail

# --- Args ---
METHOD="manual"
DRY_RUN="false"
DRIVE_1=""
DRIVE_2=""
FLAKE_URL="https://github.com/kusuriya/nix"
FLAKE_DIR="/tmp/nix"

# Parse args
while [[ $# -gt 0 ]]; do
  case "$1" in
    --anywhere)
      METHOD="anywhere"
      shift
      ;;
    --dry-run)
      DRY_RUN="true"
      shift
      ;;
    --help|-h)
      head -30 "$0"
      exit 0
      ;;
    *)
      if [[ -z "$DRIVE_1" ]]; then
        DRIVE_1="$1"
      elif [[ -z "$DRIVE_2" ]]; then
        DRIVE_2="$1"
      else
        echo "ERROR: Too many arguments"
        exit 1
      fi
      shift
      ;;
  esac
done

# --- Validation ---
if [[ -z "$DRIVE_1" ]]; then
  echo "ERROR: No drive specified."
  echo ""
  echo "Usage:"
  echo "  sudo bash install.sh --anywhere /dev/disk/by-id/nvme-DRIVE_1_ID /dev/disk/by-id/nvme-DRIVE_2_ID"
  echo "  sudo bash install.sh /dev/disk/by-id/nvme-DRIVE_1_ID /dev/disk/by-id/nvme-DRIVE_2_ID"
  echo "  sudo bash install.sh --dry-run /dev/disk/by-id/nvme-DRIVE_1_ID /dev/disk/by-id/nvme-DRIVE_2_ID"
  echo ""
  echo "Available NVMe devices:"
  ls -l /dev/disk/by-id/ | grep nvme
  exit 1
fi

if [[ ! -b "$DRIVE_1" ]]; then
  echo "ERROR: $DRIVE_1 is not a valid block device."
  echo "Use /dev/disk/by-id/ paths — run: ls -l /dev/disk/by-id/ | grep nvme"
  exit 1
fi

if [[ -n "$DRIVE_2" && ! -b "$DRIVE_2" ]]; then
  echo "WARNING: $DRIVE_2 is not a valid block device — drive 2 will be skipped for now."
  echo "You can add it post-install: see README.md 'Post-Install: Add Second NVMe'"
  DRIVE_2=""
fi

echo "============================================"
echo " Beast NixOS Install"
echo "============================================"
echo " Method:             $METHOD"
echo " Drive 1 (NixOS):    $DRIVE_1"
echo " Drive 2 (post-add): ${DRIVE_2:-<not specified, skip for now>}"
echo " Dry run:            $DRY_RUN"
echo " Flake URL:          $FLAKE_URL"
echo "============================================"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
  echo "[DRY RUN] No changes will be made."
  echo ""
fi

# --- Step 1: Clone flake ---
echo "[1/5] Cloning flake..."
if [[ -d "$FLAKE_DIR/.git" ]]; then
  echo "  Flake already cloned at $FLAKE_DIR — pulling latest..."
  cd "$FLAKE_DIR"
  git pull --ff-only
else
  git clone "$FLAKE_URL" "$FLAKE_DIR"
  cd "$FLAKE_DIR"
fi
echo "  Done."
echo ""

# --- Step 2: Patch disko.nix with real device paths ---
echo "[2/5] Patching disko.nix with real device paths..."
DISKO_FILE="hosts/beast/disko.nix"

if ! grep -q "REPLACE_WITH_DRIVE_1_ID" "$DISKO_FILE"; then
  echo "  WARNING: disko.nix already has real device paths — skipping patch."
  echo "  Current device line:"
  grep 'device = ' "$DISKO_FILE" | head -1
else
  sed -i "s|nvme-REPLACE_WITH_DRIVE_1_ID|${DRIVE_1#/dev/disk/by-id/}|" "$DISKO_FILE"
  echo "  Patched drive 1: $DRIVE_1"
  echo "  Verifying patch..."
  grep 'device = ' "$DISKO_FILE" | head -1
fi
echo ""

# --- Step 3: Confirm ---
if [[ "$DRY_RUN" != "true" ]]; then
  echo "  ⚠️  THIS WILL WIPE $DRIVE_1 COMPLETELY ⚠️"
  echo "  Drive 2 and Drive 3 will NOT be touched."
  echo ""
  read -p "  Type 'WIPE' to continue: " CONFIRM
  if [[ "$CONFIRM" != "WIPE" ]]; then
    echo "  Aborted."
    exit 1
  fi
  echo ""
fi

if [[ "$METHOD" == "anywhere" ]]; then
  # --- NixOS Anywhere method ---
  echo "[3/5] Running nixos-anywhere (disko + install in one shot)..."
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [DRY RUN] Would run:"
    echo "  nix run github:nix-community/nixos-anywhere -- \\"
    echo "    --flake \"$FLAKE_DIR#beast\" \\"
    echo "    --generate-hardware-config nixos-generate-config hosts/beast/hardware-configuration.nix"
  else
    nix --extra-experimental-features 'nix-command flakes' run \
      github:nix-community/nixos-anywhere -- \
      --flake "$FLAKE_DIR#beast" \
      --generate-hardware-config nixos-generate-config hosts/beast/hardware-configuration.nix
  fi
  echo "  Done."
  echo ""

  echo "[4/5] nixos-anywhere handles install + reboot automatically."
  echo ""

  echo "[5/5] Done."
  echo ""
  echo "============================================"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo " Dry run complete — no changes made."
    echo " Run without --dry-run to perform the install."
  else
    echo " nixos-anywhere complete — system should be rebooting."
  fi
  echo "============================================"
  echo ""
  echo "After reboot, run:"
  echo "  sudo bash hosts/beast/post-install.sh $DRIVE_2"
  exit 0
fi

# --- Manual disko + nixos-install method ---

# --- Step 3: Run disko ---
echo "[3/5] Running disko (DESTRUCTIVE — wipes $DRIVE_1)..."
if [[ "$DRY_RUN" == "true" ]]; then
  echo "  [DRY RUN] Skipping disko."
else
  nix --extra-experimental-features 'nix-command flakes' run \
    github:nix-community/disko -- \
    --mode destroy,format,mount \
    --flake "$FLAKE_DIR#beast"
fi
echo "  Done."
echo ""

# --- Step 4: Install NixOS ---
echo "[4/5] Installing NixOS..."
if [[ "$DRY_RUN" == "true" ]]; then
  echo "  [DRY RUN] Skipping install."
else
  # Generate hardware config (disko already created the mounts)
  nixos-generate-config --no-roots --root /mnt

  # Install using the flake
  nixos-install --flake "$FLAKE_DIR#beast" --root /mnt
fi
echo "  Done."
echo ""

# --- Step 5: Reboot ---
echo "[5/5] Reboot..."
if [[ "$DRY_RUN" == "true" ]]; then
  echo "  [DRY RUN] Skipping reboot."
  echo ""
  echo "============================================"
  echo " Dry run complete — no changes made."
  echo " Run without --dry-run to perform the install."
  echo "============================================"
else
  echo ""
  echo "============================================"
  echo " Install complete!"
  echo "============================================"
  echo ""
  echo "Next steps after reboot:"
  echo "  1. Add second NVMe:  sudo btrfs device add $DRIVE_2 /"
  echo "  2. Balance:           sudo btrfs balance start -dusage=100 /"
  echo "  3. Create swap:       sudo btrfs subvolume create /.swapvol && sudo btrfs filesystem mkswapfile --size 16G /.swapvol/swapfile"
  echo "  4. Tailscale:         sudo tailscale up"
  echo "  5. Verify NVIDIA:    nvidia-smi"
  echo "  6. Minecraft:         mcpelauncher-ui-qt"
  echo ""
  read -p "Reboot now? [y/N] " REBOOT
  if [[ "$REBOOT" == "y" || "$REBOOT" == "Y" ]]; then
    reboot
  else
    echo "Reboot skipped. Run 'reboot' when ready."
  fi
fi