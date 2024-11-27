{ inputs
, outputs
, lib
, config
, pkgs
, modulesPath
, ...
}:
{
  # You can import other NixOS modules here
  imports = [
    ./hardware-configuration.nix
    ./vfio.nix
    ../../modules/core
    ../../modules/kernel/rt
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

  # Bootloader.
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      systemd-boot.configurationLimit = 7;
    };
    plymouth.enable = true;
    kernel.sysctl = {
      "kernel.panic" = 60;
      "net.ipv4.tcp_mtu_probing" = 1;
    };
  };

  networking = {
    hostName = "beast";
    networkmanager.enable = true;
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

  xdg.portal = {
    enable = true;
    config.common.default = "xdg-desktop-portal-hyprland";
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-kde
    ];
  };

  zramSwap = {
    enable = true;
    priority = 100;
    memoryPercent = 10;
    swapDevices = 1;
    algorithm = "zstd";
  };

  hardware = {
    bluetooth.enable = true;
    keyboard.qmk.enable = true;
    pulseaudio.enable = false;
    graphics = {
      enable = true;
      #driSupport32Bit = true;
      #driSupport = true;
    };

  };
  #sound.enable = true;
  security = {
    rtkit.enable = true;
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
    tailscale = {
      enable = true;
      useRoutingFeatures = "client";
      interfaceName = "userspace-networking";
    };
    xserver = {
      enable = true;
      displayManager.gdm.enable = true;
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
      extraConfig.pipewire."92-rates" = {
        "context.properties" = {
          "default.clock.rate" = 44100;
        };
      };
    };
  };
  security.polkit.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  programs = {
    fish.enable = true;
    hyprland = {
      enable = true;
      xwayland.enable = true;
    };
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "kusuriya" ];
    };
    neovim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      withRuby = true;
    };
    tmux = {
      enable = true;
      extraConfig = ''
        set -g update-environment 'DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY TERM'
        set -g default-terminal screen-256color

        set -g history-limit 100000
        set -q -g status-utf8 on                  # expect UTF-8 (tmux < 2.2)
        setw -q -g utf8 on
     
        setw -g automatic-rename on   # rename window to reflect current program
        set -g renumber-windows on    # renumber windows when a window is closed
     
        set -g set-titles on          # set terminal title
     
        set -g display-panes-time 800 # slightly longer pane indicators display time
        set -g display-time 1000      # slightly longer status messages display time
     
        set -g status-interval 5 # redraw status line every 10 seconds
     
        set -g status-bg colour235
        set -g status-fg yellow
        set -g status-right-length 150
        set -g status-right '[ #{host_short} | %a %F %R]'

        set -g window-status-current-format "#[fg=colour117,bg=colour31] #I:#W "
     
        # Mouse mode on!
        setw -g mouse on
      '';
    };
    dconf.enable = true;
  };

  fonts = {
    packages = with pkgs; [
      dejavu_fonts
      emacs-all-the-icons-fonts
      jetbrains-mono
      font-awesome
      noto-fonts
      noto-fonts-emoji
      nerdfonts
    ];
    fontconfig = {
      enable = true;
      antialias = true;
      allowType1 = true;
      allowBitmaps = true;
      hinting.autohint = true;
      hinting.enable = true;
      subpixel.rgba = "rgb";
    };
  };

  environment = {
    systemPackages = with pkgs; [
      wget
      git
      curl
      distrobox
      neovim
      linux-firmware
      glib
      glib-networking
      appimage-run
      kdePackages.kdeconnect-kde
      btrfs-progs
      btrfs-snap
      timeshift
      swtpm
      unstable.OVMFFull
      looking-glass-client
      dnsmasq

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
    };
  };
  boot.binfmt.registrations.appimage = {
    wrapInterpreterInShell = false;
    interpreter = "${pkgs.appimage-run}/bin/appimage-run";
    recognitionType = "magic";
    offset = 0;
    mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
    magicOrExtension = ''\x7fELF....AI\x02'';
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
        package = pkgs.qemu_kvm;
        runAsRoot = false;
        swtpm.enable = true;
        ovmf = {
          enable = true;
          packages = [ pkgs.unstable.OVMFFull.fd ];
        };
      };
    };
  };


  programs.kdeconnect = {
    enable = true;
  };

  networking.firewall.enable = false;
  system.stateVersion = "23.05"; # Did you read the comment
  vfio.enable = true;
}

