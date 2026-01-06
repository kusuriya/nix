{ inputs
, lib
, config
, pkgs
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
    ../../modules/desktop/sway
    ../../pkgs/rd560
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
      timeout = 0;
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
      enable = false;
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
    };
  };
  #sound.enable = true;
  security = {
    rtkit.enable = true;
    sudo.wheelNeedsPassword = false;
    audit.enable = true;
    auditd.enable = true;
    apparmor = {
      enable = false;
      killUnconfinedConfinables = false;
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
    keyd = {
      enable = true;
    };
    btrfs.autoScrub = {
      enable = true;
      interval = "weekly";
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
    desktopManager.plasma6.enable = true;
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
          	  SUBSYSTEM=="kvmfr", OWNER="kusuriya", GROUP="kvm", MODE="0660"
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
  };
  programs = {
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
    dconf = {
      enable = true;
    };
    steam = {
            enable = true;
            extraCompatPackages = [ pkgs.proton-ge-bin ];
            remotePlay.openFirewall = true;
            localNetworkGameTransfers.openFirewall = true;
        };
  };

  environment = {
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
          		  firefox-nightly
                    	'';
        mode = "0755";
      };
      "modules-load.d/kvmfr.conf".text = ''
        kvmfr
      '';
      "modprobe.d/kvmfr.conf".text = ''
        options kvmfr static_size_mb=256
      '';
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
        verbatimConfig = ''
                    cgroup_device_acl = [
                    "/dev/kvmfr0",
          	    "/dev/kvm0",
          	    "/dev/null",
                    "/dev/full",
                    "/dev/zero",
                    "/dev/random",
                    "/dev/urandom",
                    "/dev/ptmx",
                    "/dev/kvm",
                    "/dev/kqemu",
                    "/dev/rtc",
                    "/dev/hpet",
                    ]
        '';
        runAsRoot = true;
        swtpm.enable = true;
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
}

