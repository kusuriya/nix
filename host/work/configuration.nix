{ inputs
, outputs
, lib
, config
, pkgs
, modulesPath
, ...
}:
{
  imports = [
    ../../modules/home-manager.nix
    ./hardware-configuration.nix
    ../../modules/oom.nix
    ../../modules/kusuriya.nix
    ../../modules/fonts.nix
    ../../modules/containers.nix
    inputs.hardware.nixosModules.lenovo-thinkpad-t14
    inputs.hardware.nixosModules.common-pc-ssd
  ];
  nixpkgs = {
    overlays = [
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages
    ];
    config = {
      allowUnfree = true;
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
  powerManagement.enable = true;
  systemd = {
    watchdog.runtimeTime = "30s";
    sleep.extraConfig = ''
      HibernateDelaySec=30m
      SuspendState=mem
    '';
  };
  system = {
    autoUpgrade = {
      enable = true;
      #flake = "github:kusuriya/nix";
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
        systemd-boot.enable = true;
        efi.canTouchEfiVariables = true;
        systemd-boot.configurationLimit = 7;
      };
      kernelPackages = pkgs.linuxPackages_latest;
      plymouth.enable = true;
      tmp = {
        useTmpfs = true;
        tmpfsSize = "30%";
      };
      kernel.sysctl = {
        "net.ipv4.tcp_mtu_probing" = 1;
        "kernel.panic" = 60;
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
    networkmanager.enable = true;
    firewall.enable = true;
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

  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "kvantum";
  };

  zramSwap = {
    enable = true;
    priority = 100;
    memoryPercent = 10;
    swapDevices = 1;
    algorithm = "zstd";
  };

  xdg.portal = {
    enable = true;
    config.common.default = "xdg-desktop-portal-hyprland";
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-kde
    ];
  };

  hardware = {
    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
    bluetooth.enable = true;
    graphics = {
      enable = true;
    };
  };

  security = {
    rtkit.enable = true;
    polkit.enable = true;
    pam.services.login.enableGnomeKeyring = true;
  };

  services = {
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
    fstrim.enable = true;
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
    fprintd.enable = false; #turned off for now because I need to figure out how to make this optional.
    greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "Hyprland";
          user = "kusuriya";
        };
        default_session = initial_session;
      };
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
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withRuby = true;
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
      pciutils
      sbctl
      intune-portal
    ];
    sessionVariables.NIXOS_OZONE_WL = "1";
    etc = {
      "1password/custom_allowed_browsers" = {
        text = ''
                    vivaldi-bin
                    floorp
                    brave
          	  zen
        '';
        mode = "0755";
      };
    };

  };
  system.stateVersion = "23.05"; # Did you read the comment
}