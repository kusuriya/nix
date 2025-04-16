{ inputs
, outputs
, lib
, config
, pkgs
, modulesPath
, self
, ...
}:
{
  # You can import other NixOS modules here
  imports = [
    ./hardware-configuration.nix
    ./vfio.nix
    ../../modules/core
    ../../modules/kernel/latest
    inputs.hardware.nixosModules.common-cpu-amd
    inputs.hardware.nixosModules.common-gpu-intel
    inputs.hardware.nixosModules.common-pc-ssd
  ];
  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-27.3.11"
      ];
    };
    overlays = [
      self.overlays.additions
      self.overlays.modifications
      self.overlays.unstable-packages
      (self: super: {
      glowing-bear-electron = self.callPackage ../../pkgs/glowing-bear-electron.nix {};
      bower = self.nodePackages.bower;
    })
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
        experimental-features = "nix-command flakes";
        auto-optimise-store = true;
        allowed-users = [ "kusuriya" "root" ];
        trusted-users = [ "kusuriya" "root" ];
        nix-path = config.nix.nixPath;
        max-jobs = "auto";
        substituters = [
          "https://cache.nixos.org"
          "https://nix-community.cachix.org"
        ];
        trusted-public-keys = [
          "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        ];
      };
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      gc = {
        automatic = true;
        dates = "weekly";
        # Keep the last week
        options = "--delete-older-than 7d";
      };
    };
  system = {
    autoUpgrade = {
      enable = true;
      flake = inputs.self.outPath;
      flags = [
        "--cores 30"
        "--update-input"
        "nixpkgs"
        "-L"
      ];
      allowReboot = false;
      dates = "weekly";
      randomizedDelaySec = "45min";
      rebootWindow.lower = "00:01";
      rebootWindow.upper = "05:00";
      persistent = true;
    };
  };

  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      systemd-boot.configurationLimit = 7;
    };
    kernel.sysctl = {
      "net.ipv4.tcp_mtu_probing" = 1;
      "kernel.panic" = 60;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "vm.swappiness" = 5;
      "vm.vfs_cache_pressure" = 50;
      "kernel.sched_autogroup_enabled" = 1;
      "kernel.sched_cfs_bandwidth_slice_us" = 500;
      "vm.dirty_ratio" = 10;
      "vm.dirty_background_ratio" = 5;
      "net.ipv4.tcp_fastopen" = 3;
      "net.ipv4.tcp_slow_start_after_idle" = 0;
    };
    binfmt.registrations.appimage = {
      wrapInterpreterInShell = false;
      interpreter = "${pkgs.appimage-run}/bin/appimage-run";
      recognitionType = "magic";
      offset = 0;
      mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
      magicOrExtension = ''\x7fELF....AI\x02'';
    };

  };

  networking = {
    hostName = "beast";
    networkmanager.enable = true;
    resolvconf = {
      dnsExtensionMechanism = true;
      enable = true;
    };
    firewall = {
      enable = true;
      allowPing = true;
      allowedTCPPortRanges = [{ from = 1714; to = 1764; }];
      allowedUDPPortRanges = [{ from = 1714; to = 1764; }];
    };
  };

  time.timeZone = "America/Los_Angeles";
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
      LC_ADDRESS = "en_US.UTF-8";
      LC_IDENTIFICATION = "en_US.UTF-8";
      LC_MEASUREMENT = "en_US.UTF-8";
      LC_MONETARY = "en_US.UTF-8";
      LC_NAME = "en_US.UTF-8";
      LC_NUMERIC = "en_US.UTF-8";
      LC_PAPER = "en_US.UTF-8";
      LC_TELEPHONE = "en_US.UTF-8";
      LC_TIME = "en_US.UTF-8";
    };
  };
  xdg.portal = {
    enable = true;
  };
  zramSwap = {
    enable = true;
    priority = 100;
    memoryPercent = 1;
    swapDevices = 1;
    algorithm = "zstd";
  };
  hardware = {
    bluetooth.enable = true;
    keyboard.qmk.enable = true;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        vpl-gpu-rt # for newer GPUs on NixOS >24.05 or unstable
        intel-media-driver # LIBVA_DRIVER_NAME=iHD
        #intel-vaapi-driver # LIBVA_DRIVER_NAME=i965 (older but works better for Firefox/Chromium)
        libvdpau-va-gl
      ];
      extraPackages32 = with pkgs.pkgsi686Linux; [ intel-media-driver intel-vaapi-driver ];
    };

  };
  #sound.enable = true;
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
        hyprlock.fprintAuth = false;
      };
    };

  };

  services = {
    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
    };
    displayManager = {
      sddm = {
        enable = true;
        wayland.enable = true;
      };
    };
    desktopManager = {
      plasma6.enable = true;
    };
    greetd = {
      enable = false;
      settings = rec {
        initial_session = {
          command = "${pkgs.hyprland}/bin/Hyprland";
          user = "kusuriya";
        };
        default_session = initial_session;
      };
    };
    fprintd.enable = true;
    flatpak.enable = true;
    libinput = {
      enable = true;
      touchpad = {
        tapping = true;
        disableWhileTyping = true;
        clickMethod = "clickfinger";
      };
    };
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      interfaceName = "userspace-networking";
    };
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    openssh.enable = true;
    avahi = {
      enable = true;
      nssmdns4 = true;
      nssmdns6 = true;
      openFirewall = true;
      ipv6 = true;
      ipv4 = true;
      browseDomains = [
        "lan.corrupted.io"
        "corrupted.io"
        "local"
        "sneaky.dev"
      ];
    };
    fwupd.enable = true;
    fstrim = {
      enable = true;
      interval = "weekly";
    };
    thermald.enable = true;
    gvfs.enable = true;
    udev =
      {
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
        pkgs.cnijfilter2
      ];
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };
  };
  programs = {
    kdeconnect.enable = true;
    hyprland = {
      enable = false;
      # set the flake package
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # make sure to also set the portal package, so that they are in sync
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      withUWSM = true;
    };
    steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      fontPackages = [ pkgs.source-han-sans ];
      gamescopeSession.enable = true;
      localNetworkGameTransfers.openFirewall = true;

    };
    nix-ld = {
      enable = true;
    };
    corectrl = {
      enable = true;
    };
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "kusuriya" ];
    };
    dconf.enable = true;
  };

  environment = {
    sessionVariables = { LIBVA_DRIVER_NAME = "iHD"; };
    systemPackages = with pkgs; [
      glowing-bear-electron
      openterface-qt
      wget
      git
      curl
      distrobox
      neovim
      linux-firmware
      glib
      glib-networking
      appimage-run
      btrfs-progs
      btrfs-snap
      timeshift
      swtpm
      edk2
      dnsmasq
      appimage-run
      openconnect
      p7zip
      zenmonitor
      ryzenadj
      mosh
      nix-diff
      nix-index
      nix-output-monitor
      nix-prefetch-git
      nil
      sops
      age
      usbutils
      coreutils
      brightnessctl
      virt-viewer
      spice-gtk
      deadnix
      statix
      nixpkgs-fmt
      plymouth-blahaj-theme
      (OVMF.override {
        tpmSupport = true;
        secureBoot = true;
        msVarsTemplate = true;
        httpSupport = true;
        tlsSupport = true;
      })
    ];
    etc = {
      "ovmf/edk2-x86_64-secure-code.fd" = {
        source = "${config.virtualisation.libvirtd.qemu.package}/share/qemu/edk2-x86_64-secure-code.fd";
      };

      "ovmf/edk2-i386-vars.fd" = {
        source = "${config.virtualisation.libvirtd.qemu.package}/share/qemu/edk2-i386-vars.fd";
        mode = "0644";
        user = "libvirtd";
      };
      "1password/custom_allowed_browsers" = {
        text = ''
          	  vivaldi-bin
          	'';
        mode = "0755";
      };
    };
  };
  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_full;
        runAsRoot = true;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [ pkgs.OVMF.fd ];
        };
      };
    };
  };


  system.stateVersion = "23.05"; # Did you read the comment
  vfio.enable = true;
  security.wrappers.qemu-system-x86_64 = {
    source = "${pkgs.qemu_full}/bin/qemu-system-x86_64";
    owner = "root";
    group = "kvm";
    permissions = "0755";
    capabilities = "cap_net_admin+ep";
  };
  systemd.services.rtkit-daemon.serviceConfig = {
    ExecStart = [
      ""
      "${pkgs.rtkit}/libexec/rtkit-daemon --scheduling-policy=FIFO --priority=20"
    ];
  };
}

