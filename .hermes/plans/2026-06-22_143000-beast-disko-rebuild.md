# Beast Rebuild — Disko + NVIDIA + Gaming Workstation Implementation Plan

> **For Hermes:** Use subagent-driven-development skill to implement this plan task-by-task.

**Goal:** Rebuild beast (gaming/workhorse desktop) from scratch with disko-managed btrfs multi-device JBOD across 2x 1TB NVMes, NVIDIA open drivers (RTX 3060 Ampere), Sway-only desktop, full gaming stack, and no VFIO/encryption/Secure Boot.

**Architecture:** Disko declaratively manages a 2-disk btrfs multi-device pool (JBOD/single profile, no redundancy) with framey-matching subvolume layout. Drive 3 left empty for future Windows. Plain systemd-boot, no LUKS2, no lanzaboote. NVIDIA RTX 3060 as primary GPU with nvidia-open kernel modules. Sway via greetd (matching framey). libvirtd retained for non-passthrough VMs (Windows VM for edge cases).

**Tech Stack:** NixOS unstable flake, disko, btrfs multi-device, nvidia-open, Sway/Wayland, greetd, Steam + Lutris + Heroic + Bottles + mcpelauncher-ui-qt, btrbk, Tailscale, NFS/Samba shares, Podman containers.

---

## Decisions Summary (from 20 questions)

| # | Question | Answer |
|---|----------|--------|
| 1 | Physical disks | Multiple NVMe drives |
| 2 | Disk count/sizes | 3x 1TB NVMe |
| 3 | Disk split | Drives 1+2: btrfs JBOD for NixOS, Drive 3: empty (future Windows) |
| 4 | JBOD risk | Accepted — no redundancy |
| 5 | LUKS2 encryption | No — desktop, keep simple |
| 6 | Secure Boot / lanzaboote | No — plain systemd-boot |
| 7 | GPU | RTX 3060 still installed |
| 8 | GPU driver | nvidia-open kernel modules |
| 9 | Desktop | Sway only (drop Plasma6) |
| 10 | Minecraft / dual-boot | mcpelauncher-ui-qt on NixOS, skip dual-boot, leave drive 3 empty |
| 11 | Swap | 16GB swapfile, no hibernation |
| 12 | Subvolume layout | Match framey (@root, @home, @nix, @log, @snapshots, @swap, @persist) |
| 13 | Gaming stack | Steam + proton-ge-bin + mcpelauncher + Lutris + Heroic + Bottles |
| 14 | VMs | Keep libvirtd (non-passthrough), plan for Windows VM |
| 15 | Network role | SSH + Tailscale + NFS/Samba file shares |
| 16 | Printing | Keep all drivers (HP + Canon) |
| 17 | Avahi / KDE Connect | Keep both |
| 18 | Auto-upgrade | Keep weekly |
| 19 | Btrfs snapshots | btrbk (like framey) |
| 20 | Display routing | NVIDIA dGPU for everything |

---

## Files to Create / Modify

### New files:
- `hosts/beast/disko.nix` — declarative 2-disk btrfs multi-device layout
- `hosts/beast/packages.nix` — host-specific packages (gaming, GUI, dev tools)
- `hosts/beast/README.md` — host documentation
- `hosts/beast/MIGRATION.md` — runbook for fresh install from NixOS install media

### Modified files:
- `hosts/beast/default.nix` — complete rewrite (remove VFIO, add NVIDIA, add disko, add btrbk, add Tailscale, add NFS/Samba, restructure)
- `hosts/beast/hardware-configuration.nix` — simplify (remove VFIO kernel modules, remove old UUID mounts, keep only initrd modules + CPU microcode)
- `flake.nix` — update beast's `extraModules` (replace `common-gpu-intel` with `common-gpu-nvidia.ampere`, remove `common-cpu-amd` if not needed, add disko module)

### Deleted files:
- `hosts/beast/vfio.nix` — no longer needed
- `hosts/beast/oom.nix` — superseded by `modules/core/oom.nix` (already imported via core)

---

## Assumptions

1. The 3 NVMe drives have stable `/dev/disk/by-id/` paths. The implementer MUST run `ls -l /dev/disk/by-id/` on beast before formatting and update the `device` lines in `disko.nix` with the actual by-id paths.
2. `nixos-hardware.common-gpu-nvidia.ampere` exists and is the correct module for RTX 3060 (Ampere GA106). Verified via GitHub search — the module exists at `common/gpu/nvidia/ampere/default.nix` in nixos-hardware.
3. `hardware.nvidia.open = true` is supported for Ampere GPUs (driver 555+). Verified via nixpkgs `nixos/modules/hardware/video/nvidia.nix`.
4. The user owns Minecraft Bedrock on the Google Play Store (required for mcpelauncher-ui-qt).
5. The user's CPU is AMD (existing config had `common-cpu-amd` and `kvm-amd`). Keeping AMD CPU module.
6. NFS shares will mirror framey's pattern (dozer NAS automounts). Samba config will be minimal for now — can be expanded later.
7. `system.stateVersion` stays `"23.05"` (matching existing — do NOT change this on a rebuild).

---

## Task 1: Delete vfio.nix and oom.nix

**Objective:** Remove dead files that are no longer needed.

**Files:**
- Delete: `hosts/beast/vfio.nix`
- Delete: `hosts/beast/oom.nix`

**Step 1: Delete vfio.nix**

```bash
rm hosts/beast/vfio.nix
```

**Step 2: Delete oom.nix**

```bash
rm hosts/beast/oom.nix
```

**Step 3: Commit**

```bash
git add -A hosts/beast/
git commit -m "refactor(beast): remove vfio.nix and oom.nix — no longer needed"
```

**Verification:** `ls hosts/beast/` should show only `default.nix`, `hardware-configuration.nix`, and `README.md` (if it exists).

---

## Task 2: Create disko.nix — declarative 2-disk btrfs multi-device layout

**Objective:** Define the disk layout for beast: 2x 1TB NVMe in btrfs multi-device JBOD (single profile), with framey-matching subvolumes. Drive 3 is left untouched.

**Files:**
- Create: `hosts/beast/disko.nix`

**Step 1: Write disko.nix**

```nix
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
    # btrfs multi-device pool spanning drives 1+2
    # disko creates a btrfs filesystem with multiple devices by listing
    # them under `device` keys in the disk definitions and referencing
    # the same btrfs content across both.
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
                # extraArgs with -M devices flag for multi-device
                # -f forces overwrite, -d single = JBOD (no redundancy)
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
                # This is the second device of the multi-device btrfs pool.
                # disko will add it to the same filesystem as nvme1's btrfs1.
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
```

**IMPORTANT NOTE for implementer:** Disko's multi-device btrfs support requires careful testing. The above is a best-effort layout based on disko's documentation. The implementer MUST:
1. Read the disko docs for multi-device btrfs: https://github.com/nix-community/disko/blob/master/docs/reference.md
2. Test with `--mode destroy,format,mount --dry-run` first
3. Verify the btrfs filesystem actually spans both devices with `btrfs filesystem show` after formatting
4. If disko does not support multi-device btrfs natively, the fallback is: use disko for drive 1 only (single disk), then manually `btrfs device add` drive 2 after first boot and update the mount config. This alternative should be documented in MIGRATION.md.

**Step 2: Commit**

```bash
git add hosts/beast/disko.nix
git commit -m "feat(beast): add disko.nix — 2-disk btrfs multi-device JBOD layout"
```

**Verification:** `nix flake check` should not error on the disko module. Run `nix run .#nixosConfigurations.beast.config.system.build.toplevel -- --dry-run` to verify it evaluates.

---

## Task 3: Rewrite hardware-configuration.nix — remove VFIO, simplify

**Objective:** Strip out all VFIO-related kernel modules and old UUID-based filesystem mounts (disko handles mounts now). Keep only initrd modules, CPU microcode, and platform.

**Files:**
- Modify: `hosts/beast/hardware-configuration.nix`

**Step 1: Write new hardware-configuration.nix**

```nix
# Hardware configuration for beast — manually maintained.
# Disk mounts are managed by disko (see ./disko.nix).
{ lib, ... }:

{
  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "uas"
        "sd_mod"
      ];
      kernelModules = [ ];
    };
    # AMD CPU — KVM for virtualization (libvirtd retained for non-passthrough VMs)
    kernelModules = [ "kvm-amd" ];
    extraModprobeConfig = ''
      options kvm-amd nested=1
    '';
    kernelParams = [
      "quiet"
    ];
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault true;
  };
}
```

**Step 2: Commit**

```bash
git add hosts/beast/hardware-configuration.nix
git commit -m "refactor(beast): simplify hardware-configuration — remove VFIO, UUID mounts (disko manages)"
```

**Verification:** File should not reference any UUIDs, no vfio modules, no kvmfr. Only `availableKernelModules`, `kvm-amd`, and AMD microcode.

---

## Task 4: Create packages.nix — host-specific packages

**Objective:** Extract beast-specific packages into a dedicated file (matching framey's pattern). Gaming stack, GUI apps, NVIDIA tools, VM tools.

**Files:**
- Create: `hosts/beast/packages.nix`

**Step 1: Write packages.nix**

```nix
# ============================================================================
# BEAST HOST-SPECIFIC PACKAGES
# ============================================================================
# Gaming/workhorse desktop packages for beast.
# These are NOT installed on other hosts (framey, pve).
#
# Imported by hosts/beast/default.nix via:
#   imports = [ ... ./packages.nix ... ];
# ============================================================================
{ config, pkgs, inputs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      # ====================================================================
      # GAMING
      # ====================================================================
      steam                 # installed via programs.steam, but having the CLI is useful
      proton-ge-bin         # Custom Proton build for Steam Play (better compatibility)
      lutris               # Game launcher — GOG, Epic, Origin, standalone games
      heroic                # Epic Games + GOG launcher (native Linux)
      bottles               # Wine prefix manager — run Windows games/apps
      mcpelauncher-ui-qt    # Minecraft Bedrock Edition (unofficial Android launcher)
      gamescope             # Steam session compositor — micro-compositor for gaming

      # ====================================================================
      # GPU / MONITORING
      # ====================================================================
      nvtop                # GPU process monitor (NVIDIA)
      glxinfo              # OpenGL info (glxinfo -B for GPU info)
      vulkan-tools         # Vulkan diagnostics (vulkaninfo)
      mesa-demos           # OpenGL demos (glxgears, glxinfo)

      # ====================================================================
      # VIRTUALIZATION (non-passthrough)
      # ====================================================================
      virt-manager          # libvirt GUI — manage VMs (QEMU/KVM)
      virt-viewer          # SPICE/VNC viewer — connect to VM displays
      swtpm                # Software TPM — for Windows 11 VMs
      OVMF                 # UEFI firmware for VMs (full path: OVMF.fd)
      # NOTE: For Windows VM with Secure Boot, use:
      #   (OVMF.override { tpmSupport = true; secureBoot = true; msVarsTemplate = true; })
      #   in environment.systemPackages or libvirtd config

      # ====================================================================
      # DESKTOP / GUI
      # ====================================================================
      vscode               # VS Code editor
      vivaldi              # Browser (primary — matches framey's default)
      unzip                # Archive extraction (common desktop need)
      dig                  # DNS lookup tool
      whois                # WHOIS client
      iotop                # I/O monitoring
      lm_sensors           # Hardware sensors (temperatures, fan speeds)

      # ====================================================================
      # MINECRAFT BEDROCK DEPENDENCIES
      # ====================================================================
      # mcpelauncher-ui-qt needs these for the Android runtime
      # They should be pulled in automatically, but listing for clarity
    ];
  };
}
```

**Step 2: Commit**

```bash
git add hosts/beast/packages.nix
git commit -m "feat(beast): add packages.nix — gaming stack, GPU tools, VM tools, desktop apps"
```

**Verification:** File should import cleanly. All package names verified to exist in nixpkgs via GitHub search:
- `lutris` ✅ pkgs/by-name/lu/lutris
- `heroic` ✅ pkgs/by-name/he/heroic
- `bottles` ✅ pkgs/by-name/bo/bottles
- `mcpelauncher-ui-qt` ✅ pkgs/by-name/mc/mcpelauncher-ui-qt

---

## Task 5: Rewrite default.nix — complete configuration

**Objective:** Full rewrite of beast's main config: remove all VFIO/libvirtd passthrough config, add NVIDIA driver, add disko, add btrbk, add Tailscale, add NFS/Samba, add gaming programs, restructure to match framey's pattern.

**Files:**
- Modify: `hosts/beast/default.nix` (complete rewrite)

**Step 1: Write new default.nix**

```nix
{ inputs
, lib
, config
, pkgs
, modulesPath
, self
, ...
}:

{
  imports = [
    ./hardware-configuration.nix
    ./disko.nix
    ./packages.nix
    ../../modules/core
    ../../modules/kernel/latest
    ../../modules/desktop/sway
    ../../pkgs/rd560
    inputs.disko.nixosModules.disko
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-nvidia
    inputs.hardware.nixosModules.common-pc-ssd
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-27.3.11"
        "electron-39.8.10"
      ];
    };
    overlays = [
      self.overlays.additions
      self.overlays.unstable-packages
    ];
  };

  nix =
    let
      flakeInputs = lib.filterAttrs
        (_: lib.isType "flake")
        inputs;
    in
    {
      settings = {
        experimental-features = [ "nix-command" "flakes" ];
        allowed-users = [ "kusuriya" "root" ];
        trusted-users = [ "kusuriya" "root" ];
        nix-path = config.nix.nixPath;
      };
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      gc = {
        automatic = true;
        dates = "weekly";
        options = "--delete-older-than 7d";
      };
    };

  system = {
    autoUpgrade = {
      enable = true;
      flake = inputs.self.outPath;
      flags = [ "-L" ];
      allowReboot = false;
      dates = "weekly";
      randomizedDelaySec = "45min";
      rebootWindow.lower = "00:01";
      rebootWindow.upper = "05:00";
      persistent = true;
    };
  };

  # Bootloader — plain systemd-boot, no Secure Boot
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 7;
        timeout = 0;
      };
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      compressor = "zstd";
      systemd.enable = true;
    };
    kernelParams = [ "quiet" "audit=1" ];
    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };
  };

  # --- NVIDIA RTX 3060 (Ampere) — primary GPU, open kernel modules ---
  hardware = {
    nvidia = {
      # Open kernel modules (nvidia-open) — supported on Ampere+ (driver 555+)
      open = true;
      # Use the production driver package (not beta)
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      # RTX 3060 is not a Maxwell-era card, so no modesetting issues
      modesetting.enable = true;
      # Power management — important for display stability
      powerManagement.enable = true;
      # Fine-grained power management (turns off GPU when not in use)
      # Only works on Turing+ — RTX 3060 is Ampere, so this is fine
      powerManagement.finegrained = false;
    };

    # Intel iGPU — present but not used for display (NVIDIA is primary)
    # Keep iGPU enabled for compute/quick-sync if needed, but don't load
    # intel media driver as primary
    intel-gpu-tools.enable = true; # optional, for diagnostics

    bluetooth.enable = true;
    keyboard.qmk.enable = true;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  networking = {
    hostName = "beast";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowPing = true;
      # KDE Connect
      allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
      allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
      # SSH on Tailscale interface only
      interfaces.tailscale0 = {
        allowedTCPPorts = [ 22 ];
      };
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };

  security = {
    rtkit.enable = true;
    sudo.wheelNeedsPassword = true;
    audit.enable = true;
    auditd.enable = true;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
    pam = {
      services = {
        greetd = {
          enableGnomeKeyring = true;
        };
        login = {
          enableGnomeKeyring = true;
          fprintAuth = false;
        };
      };
    };
  };

  services = {
    keyd.enable = true;

    # --- btrbk: automated btrfs snapshot management ---
    # Matches framey's config — hourly snapshots with tiered retention.
    btrbk = {
      extraPackages = [ pkgs.mbuffer ];
      instances = {
        "beast-snapshots" = {
          onCalendar = "hourly";
          settings = {
            timestamp_format = "long";
            snapshot_preserve_min = "2d";
            snapshot_preserve = "48h 14d 8w 6m";
            snapshot_dir = "/.snapshots";
            subvolume = {
              "/" = {};
              "/home" = {};
            };
          };
        };
      };
    };

    # --- btrfs autoScrub ---
    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
      fileSystems = [ "/" "/home" ];
    };

    flatpak.enable = true;
    libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        disableWhileTyping = true;
        clickMethod = "clickfinger";
      };
    };

    # Sway-only — no Plasma6
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };

    openssh.enable = true;

    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      interfaceName = "tailscale0";
    };

    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      openFirewall = true;
      ipv6 = true;
      ipv4 = true;
      browseDomains = [ "local" ];
    };

    fwupd.enable = true;
    fstrim = {
      enable = true;
      interval = "weekly";
    };
    gvfs.enable = true;

    udev = {
      packages = [ pkgs.via ];
      extraRules = ''
        # Set scheduler for NVMe
        ACTION=="add|change", KERNEL==""nvme[0-9]n[0-9]"", ATTR{queue/scheduler}="none"
        # Set scheduler for SSD
        ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
      '';
    };

    printing = {
      enable = true;
      drivers = [
        pkgs.gutenprint
        pkgs.gutenprintBin
        pkgs.hplipWithPlugin
        pkgs.canon-cups-ufr2
      ];
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    # Samba — minimal share config for file sharing
    samba = {
      enable = true;
      settings = {
        "beast-share" = {
          path = "/home/kusuriya/shared";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
        };
      };
    };
  };

  programs = {
    nix-ld.enable = true;
    corectrl.enable = true;
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "kusuriya" ];
    };
    dconf.enable = true;
    steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      remotePlay.openFirewall = true;
      localNetworkGameTransfers.openFirewall = true;
    };
  };

  environment = {
    etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          vivaldi-bin
          firefox-nightly
        '';
        mode = "0644";
      };
    };
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      EDITOR = "nvim";
      BROWSER = "vivaldi";
    };
  };

  # --- libvirtd (non-passthrough VMs) ---
  # Retained for headless Linux VMs and a future Windows VM.
  # No VFIO, no Looking Glass, no kvmfr — just basic QEMU/KVM.
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_full;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # --- NFS mounts from dozer (NAS) ---
  # Same automount pattern as framey
  fileSystems."/data" = {
    device = "dozer:/mnt/dozer-files/hermes-data";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "async" "x-systemd.idle-timeout=5min" "timeo=14" "retrans=2" ];
  };

  fileSystems."/dozer/files" = {
    device = "dozer:/mnt/dozer-files/files";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" "x-systemd.idle-timeout=5min" "timeo=14" "retrans=2" ];
  };

  system.stateVersion = "23.05"; # Do not change on a rebuild
}
```

**Step 2: Commit**

```bash
git add hosts/beast/default.nix
git commit -m "feat(beast): full rewrite — NVIDIA open drivers, disko, btrbk, Tailscale, Sway-only, gaming stack, no VFIO"
```

**Verification:**
- `nix flake check` — should evaluate without errors
- `nix run .#nixosConfigurations.beast.config.system.build.toplevel -- --dry-run` — should succeed
- Grep for `vfio` — should return zero matches
- Grep for `plasma` — should return zero matches
- Grep for `kvmfr` — should return zero matches

---

## Task 6: Update flake.nix — fix beast's extraModules

**Objective:** Update the beast entry in flake.nix to use the correct nixos-hardware modules (NVIDIA instead of Intel GPU) and add the disko module.

**Files:**
- Modify: `flake.nix` (beast section only)

**Step 1: Update beast's mkSystem call**

In `flake.nix`, find the beast entry under `nixosConfigurations` and update the `extraModules`:

**Old:**
```nix
beast = mkSystem {
  hostname = "beast";
  extraModules = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
  ];
};
```

**New:**
```nix
beast = mkSystem {
  hostname = "beast";
  extraModules = [
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-nvidia
    inputs.hardware.nixosModules.common-pc-ssd
  ];
};
```

Note: `inputs.disko.nixosModules.disko` is already imported in `hosts/beast/default.nix` directly, so it does NOT need to be in `extraModules`. But if the pattern is to keep it in flake.nix for consistency with framey, it can be moved here instead. The current approach (in default.nix imports) is fine.

**Step 2: Commit**

```bash
git add flake.nix
git commit -m "fix(flake): beast uses common-gpu-nvidia instead of common-gpu-intel (RTX 3060 is primary GPU)"
```

**Verification:** `grep -A 5 'beast = mkSystem' flake.nix` should show `common-gpu-nvidia` not `common-gpu-intel`.

---

## Task 7: Write README.md — host documentation

**Objective:** Document beast's configuration, hardware, and how to install/rebuild.

**Files:**
- Create: `hosts/beast/README.md`

**Step 1: Write README.md**

````markdown
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
````

**Step 2: Commit**

```bash
git add hosts/beast/README.md
git commit -m "docs(beast): add README — hardware, disk layout, GPU, gaming, networking, install"
```

---

## Task 8: Write MIGRATION.md — fresh install runbook

**Objective:** Step-by-step runbook for doing a fresh NixOS install on beast using the flake + disko.

**Files:**
- Create: `hosts/beast/MIGRATION.md`

**Step 1: Write MIGRATION.md**

````markdown
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
````

**Step 2: Commit**

```bash
git add hosts/beast/MIGRATION.md
git commit -m "docs(beast): add MIGRATION.md — fresh install runbook with disko + fallback"
```

---

## Task 9: Verify the full configuration evaluates

**Objective:** Run `nix flake check` and a dry-run build to make sure everything evaluates cleanly.

**Step 1: Run flake check**

```bash
cd ~/nix
nix flake check
```

Expected: No errors (warnings are OK).

**Step 2: Dry-run build**

```bash
nix build .#nixosConfigurations.beast.config.system.build.toplevel --dry-run
```

Expected: Evaluates successfully, shows what would be built.

**Step 3: Check for stale references**

```bash
# Should return nothing
grep -rn 'vfio\|kvmfr\|plasma6\|Looking.Glass\|looking-glass' hosts/beast/
```

**Step 4: Commit any fixes if needed**

If any issues were found and fixed:
```bash
git add -A hosts/beast/
git commit -m "fix(beast): resolve evaluation errors from flake check"
```

---

## Risks, Tradeoffs, and Open Questions

### Risks

1. **Disko multi-device btrfs** — disko's support for multi-device btrfs pools is not well-documented. The plan includes a fallback (single-disk disko + manual `btrfs device add`), documented in MIGRATION.md. **This is the highest-risk item.**

2. **NVIDIA open kernel modules on RTX 3060** — The open modules are supported on Ampere (driver 555+), but some features may have gaps vs the proprietary driver (e.g., hardware encoding, some power management features). If stability issues arise, switching to `hardware.nvidia.open = false` (proprietary) is a one-line change.

3. **JBOD data loss** — If either NVMe 1 or 2 fails, the entire btrfs filesystem is lost. btrbk snapshots provide point-in-time recovery but do NOT provide disk redundancy. User accepted this trade-off.

4. **nvidia-open + Wayland** — While NVIDIA Wayland support has improved significantly, there may still be edge cases (flickering, multi-monitor issues). The `NIXOS_OZONE_WL=1` env var is set. If issues arise, the `hardware.nvidia.modesetting.enable` option is the key lever.

### Tradeoffs

- **No encryption** — simpler setup, but if beast is physically stolen, all data is accessible. Accepted for a desktop.
- **No Secure Boot** — simpler boot chain, but no boot-level integrity. Accepted for a desktop.
- **btrfs JBOD** — 2 TB usable (full capacity), but zero redundancy. RAID1 would give 1 TB usable with mirror.
- **16 GB swap** — enough for OOM safety, not enough for hibernation. If hibernation is needed later, the swapfile size can be increased.

### Open Questions

1. **Samba share path** — The plan uses `/home/kusuriya/shared` as the Samba share path. User may want a different path or multiple shares. Low priority — can be adjusted after install.

2. **NFS shares** — The plan mirrors framey's NFS mounts (`/data`, `/dozer/files`). If beast needs different mounts, they can be added. Low priority.

3. **Windows VM** — The plan includes libvirtd + swtpm + OVMF for a future Windows VM, but doesn't actually create the VM. This is a post-install task. The user can use `virt-manager` to create a Windows VM after first boot.

4. **NVIDIA driver package** — The plan uses `nvidiaPackages.stable`. If the user wants the beta driver for newer features, change to `nvidiaPackages.beta`.

---

## Verification Summary

After all tasks are complete:

- [ ] `nix flake check` passes
- [ ] `nix build .#nixosConfigurations.beast.config.system.build.toplevel --dry-run` succeeds
- [ ] No references to `vfio`, `kvmfr`, `plasma6`, `looking-glass` in `hosts/beast/`
- [ ] `disko.nix` has PLACEHOLDER device paths clearly marked
- [ ] `README.md` documents the full configuration
- [ ] `MIGRATION.md` has the complete install runbook
- [ ] `flake.nix` uses `common-gpu-nvidia` not `common-gpu-intel`
- [ ] btrbk instance named `beast-snapshots` (not `framey-snapshots`)
- [ ] 16 GB swapfile (not 96 GB like framey)
- [ ] `system.stateVersion` is `"23.05"` (unchanged)