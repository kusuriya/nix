# =============================================================================
# Declarative disk layout for beast (gaming/workhorse desktop, 3x 1TB NVMe)
# =============================================================================
#
# This file is the declarative disk layout for beast, applied via disko:
#
#   nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#beast
#
# **DESTRUCTIVE** — this wipes drives 1 and 2 entirely. Drive 3 is left
# untouched for future Windows dual-boot.
#
# Layout:
#   Drive 1 (nvme-...): GPT → ESP (1GB) + btrfs member 1
#   Drive 2 (nvme-...): GPT → btrfs member 2 (no ESP — single ESP on drive 1)
#   Drive 3 (nvme-...): UNTOUCHED — reserved for future Windows
#
# The btrfs filesystem spans drives 1+2 in multi-device "single" profile
# (JBOD — no redundancy). If either drive fails, the filesystem is lost.
# This is an accepted trade-off (user-confirmed).
#
# Subvolumes match framey's layout:
#   @root       → /            (OS root)
#   @home       → /home        (user home dirs)
#   @nix        → /nix         (nix store isolation)
#   @log        → /var/log     (separate from root for snapshot exclusion)
#   @snapshots  → /.snapshots  (btrbk target — separate from @root)
#   @swap       → /.swapvol    (16GB swapfile, no hibernation)
#   @persist    → /persist     (placeholder for future impermanence)
#
# No LUKS2 — beast is a desktop, encryption not needed.
# No Secure Boot / lanzaboote — plain systemd-boot.
#
# IMPORTANT: The device paths below are PLACEHOLDERS. Before running disko,
# run `ls -l /dev/disk/by-id/` on beast and replace the device paths with
# the actual by-id paths for the two NVMes being used for NixOS.
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
            btrfs1 = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ "-f" "-d" "single" ];
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
                  "@swap" = {
                    mountpoint = "/.swapvol";
                    mountOptions = [ "compress=zstd" "noatime" ];
                    swap.swapfile.size = "16G";
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
      nvme2 = {
        type = "disk";
        # PLACEHOLDER — replace with actual by-id path for drive 2
        device = "/dev/disk/by-id/nvme-REPLACE_WITH_DRIVE_2_ID";
        content = {
          type = "gpt";
          partitions = {
            btrfs2 = {
              size = "100%";
              content = {
                type = "btrfs";
                extraArgs = [ ];
                subvolumes = { };
              };
            };
          };
        };
      };
    };
  };
}