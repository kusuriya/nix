# =============================================================================
# Declarative disk layout for beast (gaming/workhorse desktop, 3x 1TB NVMe)
# =============================================================================
#
# Disko manages drive 1 only (single-disk btrfs). Drive 2 is added to the
# btrfs pool post-install via `btrfs device add` — disko does NOT support
# multi-device btrfs natively (issue #261, PR #482 both closed/unmerged).
# See README.md "Post-Install: Add Second NVMe" for the manual step.
#
#   nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#beast
#
# **DESTRUCTIVE** — this wipes drive 1 entirely. Drives 2 and 3 are untouched.
#
# Layout:
#   Drive 1 (nvme-...): GPT → ESP (1GB) + btrfs (single device)
#   Drive 2 (nvme-...): UNTOUCHED at format time — added to pool post-install
#   Drive 3 (nvme-...): UNTOUCHED — reserved for future Windows
#
# Subvolumes:
#   @root       → /            (OS root)
#   @home       → /home        (user home dirs)
#   @nix        → /nix         (nix store isolation)
#   @log        → /var/log     (separate from root for snapshot exclusion)
#   @snapshots  → /.snapshots  (btrbk target — separate from @root)
#   @persist    → /persist     (placeholder for future impermanence)
#
# Swap: 16GB swapfile is created manually post-install AFTER btrfs device add,
# because btrfs swapfiles on multi-device pools need special handling
# (NODATACOW via `btrfs filesystem mkswapfile`). See README.md.
#
# No LUKS2 — beast is a desktop, encryption not needed.
# No Secure Boot / lanzaboote — plain systemd-boot.
#
# IMPORTANT: The device path below is a PLACEHOLDER. Before running disko,
# run `ls -l /dev/disk/by-id/` on beast and replace it with the actual
# by-id path for the NVMe being used for NixOS.
#
# -----------------------------------------------------------------------------
{
  disko.devices = {
    disk = {
      nvme1 = {
        type = "disk";
        # PLACEHOLDER — replace with actual by-id path for drive 1
        device = "/dev/disk/by-id/nvme-REPLACE_WITH_DRIVE_1_ID";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              priority = 1;
              name = "ESP";
              start = "1M";
              end = "1G";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
                mountOptions = [ "umask=0077" ];
              };
            };
            btrfs = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" ];
                subvolumes = {
                  "@root" = {
                    mountpoint = "/";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@home" = {
                    mountpoint = "/home";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@nix" = {
                    mountpoint = "/nix";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@log" = {
                    mountpoint = "/var/log";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@snapshots" = {
                    mountpoint = "/.snapshots";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                  "@persist" = {
                    mountpoint = "/persist";
                    mountOptions = [ "compress=zstd" "noatime" ];
                  };
                };
              };
            };
          };
        };
      };
    };
  };
}
