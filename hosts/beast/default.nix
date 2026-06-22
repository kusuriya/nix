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
        ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
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