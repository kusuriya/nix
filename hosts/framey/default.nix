{ inputs
, lib
, config
, pkgs
, self
, ...
}:
{
  imports = [
    ../../modules/core
    ../../modules/kernel/latest
    ../../modules/desktop/sway
    ../../modules/desktop/sysctl
    ../../modules/desktop/btrfs-snapshots
    ../../modules/desktop/dozer-mounts
    ../../modules/desktop/virtualization
    ./hardware-configuration.nix
    ./packages.nix
    ./disko.nix
    inputs.disko.nixosModules.disko
    inputs.hardware.nixosModules.framework-13-7040-amd
    inputs.hardware.nixosModules.common-pc-ssd
  ];
  nixpkgs = {
    overlays = [
      self.overlays.unstable-packages
      self.overlays.custom-packages
    ];
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-27.3.11"
        "electron-39.8.10"
      ];

    };
  };

  nix =
    let
      flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in
    {
      settings = {
        allowed-users = [ "kusuriya" "root" ];
        trusted-users = [ "kusuriya" "root" ];
        nix-path = config.nix.nixPath;
      };
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    };
  # powerManagement.powertop.enable = true; # Disabled — USB autosuspend kills the mouse
  systemd = {
    settings.Manager.RuntimeWatchdogSec = "30s";
  };
  system = {
    autoUpgrade = {
      enable = true;
      flake = inputs.self.outPath;
      flags = [
        "-L"
      ];
      allowReboot = false;
      dates = "Sun 01:00";
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
          configurationLimit = 5;
          consoleMode = "max";
          # Disabled in favour of lanzaboote (secure boot). Using mkForce
          # because the hardware-configuration.nix or other modules may set
          # this to true — we need it off so lanzaboote's bootctl stub takes over.
          enable = lib.mkForce false;
        };
      };
      # Lanzaboote: enables Secure Boot with a UKI-based boot flow.
      # Keys are auto-generated into /etc/secureboot on first activation.
      # Use `sbctl` (already in systemPackages) to verify and manage keys.
      lanzaboote = {
        enable = true;
        pkiBundle = "/etc/secureboot";
        autoGenerateKeys.enable = true;
      };
      initrd = {
        compressor = "zstd";
        systemd.enable = true;
        # TPM kernel modules needed in initrd so the system can unlock
        # LUKS2 via TPM2 sealed credentials during early boot.
        kernelModules = [ "tpm_crb" "tpm_tis" ];
      };
      kernelParams = [ "audit=1" "amdgpu.runpm=1" ];
      plymouth.enable = true;
      binfmt.registrations.appimage = {
        wrapInterpreterInShell = false;
        interpreter = "${pkgs.appimage-run}/bin/appimage-run";
        recognitionType = "magic";
        offset = 0;
        mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
        magicOrExtension = ''\x7fELF....AI\x02'';
      };
      tmp.useTmpfs = true;
      tmp.tmpfsSize = "8G";
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
    # --- Firewall ---
    # Default-deny firewall. Only SSH (22) is allowed, and only on the
    # Tailscale interface (tailscale0) — no inbound ports on physical NICs.
    # Tailscale itself punches outbound, so it works without open ports.
    firewall = {
      enable = true;
      allowPing = false;
      # Quassel IRC core (127.0.0.1-only by default — see services.quassel)
      allowedTCPPorts = [
        4242
      ];
      allowedUDPPorts = [ ];
      interfaces.tailscale0 = {
        allowedTCPPorts = [ 22 ];
      };
      logRefusedConnections = true;
    };
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  xdg.mime = {
    enable = true;
    defaultApplications = {
      "text/html" = "vivaldi-stable.desktop";
      "x-scheme-handler/about" = "vivaldi-stable.desktop";
      "x-scheme-handler/unknown" = "vivaldi-stable.desktop";
    };
  };


  hardware = {
    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
    bluetooth.enable = true;
    keyboard.qmk.enable = true;
    fw-fanctrl = {
      enable = true;
      config = {
        defaultStrategy = "quiet";
        strategies = {
          quiet = {
            fanSpeedUpdateFrequency = 5;
            movingAverageInterval = 20;
            speedCurve = [
              { temp = 50; speed = 0; }
              { temp = 60; speed = 10; }
              { temp = 70; speed = 25; }
              { temp = 80; speed = 50; }
              { temp = 90; speed = 100; }
            ];
          };
        };
      };
    };
    amdgpu = {
      opencl.enable = true;
      initrd.enable = true;
    };
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
    tpm2 = {
      enable = true;
      pkcs11.enable = true;
      tctiEnvironment.enable = true;
    };
    pam = {
      services = {
        greetd = {
          enableGnomeKeyring = true;
          fprintAuth = false;
        };
        login = {
          enableGnomeKeyring = true;
          fprintAuth = false;
        };
      };
    };
  };

  # Let sway handle lid close (bindswitch) instead of logind.
  # When docked with external monitors, lid close does nothing.
  # When undocked, lid close triggers suspend via idle-guard.sh.
  services.logind.settings.Login.HandleLidSwitch = "ignore";
  services.logind.settings.Login.HandlePowerKey = "suspend";

  services = {
    thermald.enable = true;
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

    # USBGuard removed — broke Caldigit dock (Thunderbolt USB hub).
    # Can revisit with per-device-ID rules later, but class-based rules
    # don't cover dock passthrough devices properly.
    # See: https://usbguard.github.io/documentation/rule-language

    gvfs.enable = true;
    hardware.bolt.enable = true;
    power-profiles-daemon = {
      enable = false;
    };
    udev =
      {
        packages = [ pkgs.via ];
        extraRules = ''
          # Set scheduler for NVMe
          ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/scheduler}="none"
          # Set scheduler for SSD and disks
          ACTION=="add|change", KERNEL=="sd[a-z]|mmcblk[0-9]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
          # Prevent keyboard/touchpad from being power-suspended
          ACTION=="add", SUBSYSTEM=="i2c", DRIVER=="i2c_hid_acpi", ATTR{power/control}="on"
        '';
      };
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

      # Raise quantum to give QEMU's non-RT audio thread enough buffer to
      # avoid underruns. 2048/48000 = 42.7ms — large enough to absorb
      # scheduler jitter from libvirtd-launched QEMU processes.
      extraConfig.pipewire."92-qemu-quantum" = {
        "context.properties" = {
          "default.clock.quantum" = 2048;
          "default.clock.min-quantum" = 1024;
          "default.clock.max-quantum" = 4096;
        };
      };

      # Grant QEMU's PipeWire client RT scheduling via WirePlumber policy.
      # libvirtd-launched QEMU bypasses normal RTKit session negotiation,
      # so we explicitly match on the binary name and set rt.prio.
      wireplumber.extraConfig."92-qemu-rt" = {
        "monitor.alsa.rules" = [ ];
        "wireplumber.settings" = { };
        "wireplumber.profiles" = {
          main."monitor.libcamera" = "disabled";
        };
        "node.rules" = [
          {
            matches = [{ "application.process.binary" = ".qemu-system-x86_64-wrapped"; }];
            actions = {
              update-props = {
                "node.latency" = "2048/48000";
                "rt.prio" = 88;
                "rt.time.soft" = 200000;
                "rt.time.hard" = 200000;
              };
            };
          }
        ];
      };
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
    # Quassel IRC — split client/core. The NixOS module only provides
    # quasselDaemon (the core binary). The Qt CLIENT is a separate
    # package — `pkgs.quassel` — and must be added to systemPackages
    # explicitly (see packages.nix). Classic service-module-enables-
    # daemon-but-not-user-tooling pitfall.
    #
    # Running as the desktop user (`user = "kusuriya"`) keeps the
    # SQLite DB in $HOME where the client also looks for it. Default
    # `interfaces = [ "127.0.0.1" ]` is correct for framey: this is a
    # laptop on untrusted networks, so the core only accepts loopback
    # connections. To connect from another host, SSH-tunnel:
    #   ssh -L 4242:127.0.0.1:4242 framey
    # then point a remote Quassel client at localhost:4242. Bump to
    # `interfaces = [ "0.0.0.0" ]` + remove the SSH-tunnel dance if
    # you ever want to expose it directly (and add to tailscale0
    # firewall only — never to the physical NIC).
    quassel = {
      enable = true;
      user = "kusuriya";
    };
    flatpak.enable = true;
    dbus.enable = true;
    xserver = {
      enable = true;
      xkb = {
        layout = "us";
        variant = "";
      };
    };
    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "schedutil";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 70;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        START_CHARGE_THRESH_BAT0 = 25;
        STOP_CHARGE_THRESH_BAT0 = 90;

        # Prevent Kinesis Adv360 Pro keyboard from being autosuspended
        USB_BLACKLIST = "29ea:0362";
      };
    };

  };

  # KDE Connect — phone pairing, clipboard sync, file share, notification mirror.
  # The NixOS module:
  #   * enables kdeconnectd as a system service (auto-starts on boot)
  #   * opens TCP+UDP ports 1714-1764 for LAN discovery + transport
  #   * adds `package` (kdePackages.kdeconnect-kde by default) to
  #     environment.systemPackages so kdeconnect-cli is on PATH
  # Note: this is `programs.kdeconnect`, NOT `services.kdeconnect` — the
  # option moved from services to programs in 25.11. The legacy path is
  # gone. See nixpkgs/nixos/modules/programs/kdeconnect.nix.
  programs.kdeconnect = {
    enable = true;
    # Optional: swap to GSConnect in Vivaldi/Firefox instead of the KDE
    # full stack. Not used here; default is kdePackages.kdeconnect-kde.
    # package = pkgs.gnomeExtensions.gsconnect;
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
    dconf.enable = true;
    streamdeck-ui.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      sbctl
      lm_sensors
      poweralertd
      ryzenadj
      unzip
      dig
      whois
      iotop
      networkmanager-openconnect
      vscode
      nemo
    ];
    sessionVariables = {
      # mkForce: home-manager's neovim module auto-sets VISUAL/EDITOR to nvim.
      # We override: nvim is the TTY/SSH editor, code is the GUI editor.
      NIXOS_OZONE_WL = "1";
      EDITOR = lib.mkForce "nvim";
      VISUAL = lib.mkForce "code";
      BROWSER = "vivaldi";
      XCURSOR_THEME = "Adwaita";
      XCURSOR_SIZE = "24";
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

  # ryzenadj power-limit service — caps CPU power limits to reduce heat/noise
  systemd.services.ryzenadj-power-limit = {
    description = "RyzenAdj power limit caps for quiet fans";
    wantedBy = [ "multi-user.target" ];
    serviceConfig.Type = "oneshot";
    script = ''
      ${pkgs.ryzenadj}/bin/ryzenadj \
        --stapm-limit=25000 \
        --fast-limit=30000 \
        --slow-limit=25000 \
        --power-saving
    '';
  };

  system.stateVersion = "25.11";

  # fscrypt: Consider as future option for per-directory encryption in /home.
  # See: https://nixos.org/manual/nixos/stable/#sec-fscrypt
}
