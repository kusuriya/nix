{ inputs
, lib
, config
, pkgs
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
    ../../modules/desktop/sysctl
    ../../modules/desktop/btrfs-snapshots
    ../../modules/desktop/dozer-mounts
    ../../modules/desktop/virtualization
    ../../pkgs/rd560
    inputs.disko.nixosModules.disko
    # Hardware modules are imported via flake.nix extraModules — no duplicate here
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
      self.overlays.unstable-packages
      self.overlays.custom-packages
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
        allowed-users = [ "kusuriya" "root" ];
        trusted-users = [ "kusuriya" "root" ];
        nix-path = config.nix.nixPath;
      };
      # gc and experimental-features are handled by modules/core/nix.nix
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
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

  # Hardware watchdog — auto-reboot if system hangs
  systemd.settings.Manager.RuntimeWatchdogSec = "30s";

  # Swap — 16GB swapfile on root btrfs, auto-created by NixOS
  swapDevices = [{
    device = "/swapfile";
    size = 16384;
  }];

  # Bootloader — plain systemd-boot, no Secure Boot
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 7;
      };
      efi.canTouchEfiVariables = true;
    };
    initrd = {
      compressor = "zstd";
      systemd.enable = true;
      luks.devices = { };
    };
    kernelParams = [ "quiet" "audit=1" ];
    # TPM disabled in UEFI firmware — fixing boot issues
    # Kernel modules blacklisted as belt-and-suspenders
    extraModprobeConfig = ''
      blacklist tpm_crb
      blacklist tpm_tis
    '';
    plymouth.enable = true;
    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };
  };

  # --- AMD Radeon RX 9070 XT (RDNA 4) — primary GPU ---
  hardware = {
    amdgpu = {
      initrd.enable = true;
    };
    bluetooth.enable = true;
    keyboard.qmk.enable = true;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        libva
        libva-vdpau-driver
        libvdpau-va-gl
      ];
    };
  };

  networking = {
    hostName = "beast";
    networkmanager.enable = true;
    firewall = {
      enable = true;
      allowPing = true;
      # PulseAudio TCP tunnel (Ubuntu audio → beast speakers)
      allowedTCPPorts = [ 4713 ];
      # KDE Connect
      allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
      allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
      # SSH on Tailscale interface only
      interfaces.tailscale0 = {
        allowedTCPPorts = [ 22 ];
      };
    };
  };

  xdg = {
    portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
    };
    mime = {
      enable = true;
      defaultApplications = {
        "text/html" = "vivaldi-stable.desktop";
        "x-scheme-handler/about" = "vivaldi-stable.desktop";
        "x-scheme-handler/unknown" = "vivaldi-stable.desktop";
      };
    };
  };

  security = {
    rtkit.enable = true;
    sudo = {
      wheelNeedsPassword = true;
      extraConfig = ''
        Defaults timestamp_timeout=240
      '';
    };
    audit.enable = true;
    auditd.enable = true;
    apparmor = {
      enable = true;
      killUnconfinedConfinables = true;
    };
    tpm2.enable = false;
    # QEMU security wrapper — cap_net_admin for bridged VM networking
    wrappers.qemu-system-x86_64 = {
      source = "${pkgs.qemu_full}/bin/qemu-system-x86_64";
      owner = "root";
      group = "kvm";
      permissions = "0755";
      capabilities = "cap_net_admin+ep";
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
      openFirewall = true;
      settings = {
        "global" = {
          "workgroup" = "CORRUPTED";
          "server string" = "BEAST";
          "netbios name" = "BEAST";
          "security" = "user";
          "guest account" = "nobody";
        };
        "beast-share" = {
          path = "/home/kusuriya/shared";
          browseable = "yes";
          "read only" = "no";
          "guest ok" = "no";
          "create mask" = "0644";
          "directory mask" = "0755";
        };
      };
    };
  };

  # Create the Samba share directory at boot
  systemd.tmpfiles.settings."10-beast-shared"."/home/kusuriya/shared".d = {
    user = "kusuriya";
    group = "users";
    mode = "0755";
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

  # sched-ext CPU scheduler — loads scx_lavd BPF scheduler at boot
  systemd.services.scx = {
    description = "sched-ext CPU Scheduler (scx_lavd)";
    wantedBy = [ "multi-user.target" ];
    after = [ "sysinit.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.scx.rustscheds}/bin/scx_lavd";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };

  environment = {
    etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          vivaldi-bin
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

  system.stateVersion = "24.05";
}
