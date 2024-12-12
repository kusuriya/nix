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
        cores = 0; # Use all cores
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
      allowReboot = true;
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
    kernelPackages = pkgs.linuxPackages_latest;
    plymouth.enable = true;
    kernel.sysctl = {
      "net.ipv4.tcp_mtu_probing" = 1;
      "kernel.panic" = 60;
      "net.core.default_qdisc" = "fq";
      "net.ipv4.tcp_congestion_control" = "bbr";
      "vm.swappiness" = 5;
      "vm.vfs_cache_pressure" = 50;
      "kernel.sched_autogroup_enabled" = 1;
      "kernel.sched_cfs_bandwidth_slice_us" = 500;
    };
    supportedFilesystems = [
      "bcachefs"
    ];
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
    memoryPercent = 50;
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
      enable = true;
      settings = rec {
        initial_session = {
          command = "Hyprland";
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
    };
  };
  programs = {
    steam.enable = true;
    seahorse.enable = true;
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
      OVMFFull
      looking-glass-client
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
          packages = [ pkgs.OVMFFull.fd ];
        };
        verbatimConfig = ''
          memory_backing_dir = "/dev/hugepages"
          nvram = [ "${pkgs.OVMFFull}/FV/OVMF.fd:/run/libvirt/nix-ovmf/OVMF_CODE.fd" ]
          cgroup_device_acl = [
            "/dev/null", "/dev/full", "/dev/zero",
            "/dev/random", "/dev/urandom",
            "/dev/ptmx", "/dev/kvm", "/dev/kqemu",
            "/dev/rtc","/dev/hpet",
            "/dev/vfio/vfio", "/dev/vfio/1"
          ]
        '';
      };
    };
  };


  system.stateVersion = "23.05"; # Did you read the comment
  vfio.enable = true;
}

