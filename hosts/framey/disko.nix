{
  # LUKS-encrypted btrfs layout for framey (Framework 13).
  #
  # This file only DESCRIBES the layout — it does not run on a rebuild.
  # To apply it you must (re)format the disk with disko, which is
  # destructive. See the notes at the bottom of this file.
  disko.devices = {
    disk = {
      main = {
        type = "disk";
        # Verify this with `lsblk` / `ls -l /dev/disk/by-id` before formatting.
        # For stability across reboots a /dev/disk/by-id/... path is preferred.
        device = "/dev/nvme0n1";
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
                  # already set in framey). The TPM is NOT enrolled at format
                  # time — see step 4 below to enroll it after first boot.
                  crypttabExtraOpts = [ "tpm2-device=auto" ];
                };
                # disko prompts for the passphrase interactively at format time.
                content = {
                  type = "btrfs";
                  extraArgs = [ "-f" ]; # force, overwrite any existing fs
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
                    # Kept separate so logs can be excluded from root snapshots.
                    "@log" = {
                      mountpoint = "/var/log";
                      mountOptions = [ "compress=zstd" "noatime" ];
                    };
                    # Swap lives inside the encrypted volume, so it is encrypted
                    # too — this closes the cleartext-swap leak. For hibernation
                    # (suspend-to-disk) set this to >= your RAM size (framey = 32G).
                    "@swap" = {
                      mountpoint = "/.swapvol";
                      swap.swapfile.size = "32G";
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
