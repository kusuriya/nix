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
    ../../modules/core
    ../../modules/kernel/latest
    ./hardware-configuration.nix
    inputs.hardware.nixosModules.framework-13-7040-amd
    inputs.hardware.nixosModules.common-pc-ssd
  ];
  nixpkgs = {
    overlays = [
      self.overlays.additions
      self.overlays.modifications
      self.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-27.3.11"
      ];

    };
  };

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        experimental-features = "nix-command flakes";
        auto-optimise-store = true;
        allowed-users = [
          "kusuriya"
          "root"
        ];
        trusted-users = [
          "kusuriya"
          "root"
        ];
        nix-path = config.nix.nixPath;
        max-jobs = "auto";
        cores = 0; # Use all cores
      };
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      gc = {
        automatic = true;
        dates = "weekly";
        # Keep the last week
        options = "--delete-older-than 30d";
      };
    };
  powerManagement.enable = true;
  systemd = {
    watchdog.runtimeTime = "30s";
  };
  system = {
    autoUpgrade = {
      enable = true;
      flake = inputs.self.outPath;
      flags = [
        "--cores 15"
        "--update-input"
        "nixpkgs"
        "-L"
      ];
      allowReboot = true;
      dates = "01:00";
      randomizedDelaySec = "45min";
      rebootWindow.lower = "00:01";
      rebootWindow.upper = "05:00";
      persistent = true;
    };
  };

  boot =
    {
      loader = {
        efi.canTouchEfiVariables = true;
        systemd-boot = {
          configurationLimit = 14;
          consoleMode = "max";
          enable = false;
        };
      };
      lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
      };
      initrd = {
        compressor = "zstd";
        systemd.enable = true;
      };
      plymouth.enable = true;
      tmp = {
        useTmpfs = false;
        tmpfsSize = "50%";
      };
      kernel.sysctl = {
        "net.ipv4.tcp_mtu_probing" = 1;
        "kernel.panic" = 60;
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
        "vm.swappiness" = 10;
        "vm.vfs_cache_pressure" = 50;
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
    hostName = "framey";
    networkmanager = {
      wifi = {
        powersave = false;
        scanRandMacAddress = true;
      };
      enable = true;
      plugins = [
        pkgs.networkmanager-openconnect
      ];
    };
    firewall = {
      enable = true;
      allowPing = true;
    };
    resolvconf = {
      dnsExtensionMechanism = true;
      enable = true;
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

  zramSwap = {
    enable = true;
    priority = 100;
    memoryPercent = 50;
    swapDevices = 1;
    algorithm = "zstd";
  };

  xdg.portal = {
    enable = true;
    config.common.default = "xdg-desktop-portal-hyprland";
  };

  hardware = {
    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
    bluetooth.enable = true;
    keyboard.qmk.enable = true;
    #amdgpu = {
    #  amdvlk.enable = true;
    #  opencl.enable = true;
    #  initrd.enable = true;
    #};
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = [ pkgs.mesa.drivers ];
      extraPackages32 = [ pkgs.pkgsi686Linux.mesa.drivers ];
    };
  };
  security = {
    rtkit.enable = true;
    polkit.enable = true;
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
    greetd = {
      enable = false;
    };
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

    fwupd.enable = true;
    fstrim = {
      enable = true;
      interval = "weekly";
    };
    thermald.enable = true;
    gvfs.enable = true;
    hardware.bolt.enable = true;
    udev.packages = [ pkgs.via ];
    printing = {
      enable = true;
      drivers = [
        pkgs.gutenprint
        pkgs.gutenprintBin
        pkgs.cnijfilter2
      ];
    };
    pipewire = {
      enable = true;
      alsa.enable = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
      #media-session.enable = true;
    };
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
    power-profiles-daemon.enable = true;
    flatpak.enable = true;
    dbus.enable = true;
    upower.enable = true;
    displayManager = {
      sddm = {
        enable = false;
        wayland.enable = true;
      };
      cosmic-greeter.enable = true;
    };
    desktopManager = {
      cosmic.enable = true;
    };
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };

  };
  programs = {
    regreet = {
      enable = false;
    };
    hyprland = {
      enable = true;
      # set the flake package
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      # make sure to also set the portal package, so that they are in sync
      portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      withUWSM = true;
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
    systemPackages = with pkgs; [
      appimage-run
      brightnessctl
      curl
      coreutils
      distrobox
      linux-firmware
      mosh
      nix-diff
      nix-index
      nix-output-monitor
      nix-prefetch-git
      nix-direnv
      pciutils
      sbctl
      lm_sensors
      poweralertd
      statix
      git
      nil
      sops
      age
      unzip
      p7zip
      dig
      whois
      usbutils
      iotop
      openconnect
      networkmanager-openconnect
      greetd.regreet
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      TERMINAL = "alacritty";
      EDITOR = "nvim";
    };
    etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
          vivaldi-bin
        '';
        mode = "0755";
      };
    };

  };
  system.stateVersion = "23.05"; # Did you read the comment
}
