# =============================================================================
# Declarative disk layout for framey (Framework 13 AMD, 96 GB RAM)
# =============================================================================
#
# This file is the declarative disk layout for framey, applied via disko:
#
#   nix run github:nix-community/disko -- --mode destroy,format,mount --flake .#framey
#
# **DESTRUCTIVE** — this wipes the entire target disk. All existing data on
# the device below will be lost.
#
# The layout is:
#   GPT
#   ├─ ESP (1 GB, vfat, unencrypted)  → /boot
#   └─ LUKS2 container               → btrfs with subvolumes
#
# TPM2 enrollment is NOT done at format time. After the first boot, enroll
# the TPM2 so the LUKS container unlocks automatically:
#
#   systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto /dev/disk/by-id/...
#
# The swapfile inside @swap is created with `btrfs filesystem mkswapfile`
# (kernel 6.1+), which handles NODATACOW and the sparse swapfile automatically.
#
# @snapshots is kept separate from @root so that btrbk snapshots of @root
# do not recursively include the snapshot directory itself.
#
# @persist is a placeholder for future impermanence support — it is mounted
# but not actively used yet.
#
# -----------------------------------------------------------------------------
{
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # Verify this with `lsblk` / `ls -l /dev/disk/by-id` before formatting.
        # A /dev/disk/by-id/... path is stable across reboots.
        device = "/dev/disk/by-id/nvme-Sabrent_SB-RKT4P-2TB_48797869800873";
        content = {
          type = "gpt";
          partitions = {
            # Unencrypted EFI System Partition. systemd-boot/lanzaboote needs
            # the kernel + initrd here in the clear, which is exactly why
            # Secure Boot (lanzaboote) matters on this host.
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

            # Everything else is a single LUKS2 container holding btrfs.
            luks = {
              size = "100%";
              content = {
                type = "luks";
                name = "cryptroot"; # opens as /dev/mapper/cryptroot
                settings = {
                  # TRIM passthrough to the SSD. Minor info leak (which blocks
                  # are in use); standard trade-off for SSD longevity on laptops.
                  allowDiscards = true;
                  # Try the TPM2 first, fall back to passphrase. Requires
                  # systemd in stage 1 (boot.initrd.systemd.enable = true,
                  # already set in framey). The TPM is NOT enrolled at
                  # format time — enroll it after first boot (see header above).
                  # IMPORTANT: tpm2-device and tpm2-with-pin options must be
                  # added AFTER systemd-cryptenroll is run. Adding them before
                  # enrollment causes the initrd to try TPM2 unlock, find no key,
                  # and drop to emergency mode instead of falling back to passphrase.
                  # Post-install: uncomment the line below, rebuild, then reboot
                  # NOTE: tpm2-with-pin=yes is correct for systemd 260+ (boolean with explicit =yes)
                  crypttabExtraOpts = [ "tpm2-device=auto" "tpm2-with-pin=yes" ];
                };
                # disko prompts for the passphrase interactively at format time.
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # force, overwrite any existing fs
                  subvolumes = {
                    # Root filesystem — the OS itself.
                    "@root" = {
                      mountpoint = "/";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    # User home directories.
                    "@home" = {
                      mountpoint = "/home";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    # Nix store — kept on its own subvolume for isolation.
                    "@nix" = {
                      mountpoint = "/nix";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    # Kept separate so logs can be excluded from root snapshots.
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    # Dedicated snapshot target for btrbk. Separate from @root
                    # so snapshots don't recurse into the snapshot directory.
                    "@snapshots" = {
                      mountpoint = "/.snapshots";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    # Swap lives inside the encrypted volume, so it is encrypted
                    # too — this closes the cleartext-swap leak. For hibernation
                    # (suspend-to-disk) set this to >= your RAM size (framey = 96G).
                    "@swap" = {
                      mountpoint = "/.swapvol";
                      mountOptions = [ "compress=zstd" "noatime" ];
                      swap.swapfile.size = "96G";
                    };
                    # Placeholder for future impermanence support — mounted but
                    # not actively used yet.
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
  };
}