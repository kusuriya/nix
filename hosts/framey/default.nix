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
    ../../modules/desktop/sway
    ./hardware-configuration.nix
    ./packages.nix
    inputs.hardware.nixosModules.framework-13-7040-amd
    inputs.hardware.nixosModules.common-pc-ssd
    # ./disko.nix                    # TODO: uncomment after migration — importing before disk is reformatted will conflict
    # inputs.disko.nixosModules.disko  # TODO: uncomment after migration
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
        experimental-features = [ "nix-command" "flakes" ];
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
    };
  #powerManagement.enable = true;
  systemd = {
    settings.Manager.RuntimeWatchdogSec = "30s";
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
      plymouth.enable = true;
      kernel.sysctl = {
        "net.ipv4.tcp_mtu_probing" = 1;
        "kernel.panic" = 60;
        "net.core.default_qdisc" = "fq";
        "net.ipv4.tcp_congestion_control" = "bbr";
        "vm.swappiness" = 10;
        "vm.vfs_cache_pressure" = 50;
        "vm.dirty_ratio" = 10;
        "vm.dirty_background_ratio" = 5;
        "net.ipv4.tcp_fastopen" = 3;
        "net.ipv4.tcp_slow_start_after_idle" = 0;
        # --- Kernel hardening sysctls ---
        # Restrict access to kernel pointers (prevents info leaks via /proc)
        "kernel.kptr_restrict" = 2;
        # Restrict dmesg access to root only
        "kernel.dmesg_restrict" = 1;
        # Restrict perf events to root (prevents side-channel attacks)
        "kernel.perf_event_paranoid" = 3;
        # Restrict ptrace to parent processes only
        "kernel.yama.ptrace_scope" = 2;
        # --- Network hardening ---
        # Enable reverse path filtering (anti-spoofing)
        "net.ipv4.conf.all.rp_filter" = 1;
        "net.ipv4.conf.default.rp_filter" = 1;
        # Disable ICMP redirect acceptance (prevents route hijacking)
        "net.ipv4.conf.all.accept_redirects" = 0;
        "net.ipv4.conf.default.accept_redirects" = 0;
        # Disable ICMP redirect sending
        "net.ipv4.conf.all.send_redirects" = 0;
        "net.ipv4.conf.default.send_redirects" = 0;
        # Disable source-routed packet acceptance
        "net.ipv4.conf.all.accept_source_route" = 0;
        "net.ipv4.conf.default.accept_source_route" = 0;
        # IPv6: disable redirects and source routing
        "net.ipv6.conf.all.accept_redirects" = 0;
        "net.ipv6.conf.default.accept_redirects" = 0;
        "net.ipv6.conf.all.accept_source_route" = 0;
        "net.ipv6.conf.default.accept_source_route" = 0;
        # Ignore broadcast ICMP (Smurf attack prevention)
        "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
        # Enable TCP SYN cookies (SYN flood mitigation)
        "net.ipv4.tcp_syncookies" = 1;
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
    # --- Firewall ---
    # Default-deny firewall. Only SSH (22) is allowed, and only on the
    # Tailscale interface (tailscale0) — no inbound ports on physical NICs.
    # Tailscale itself punches outbound, so it works without open ports.
    firewall = {
      enable = true;
      allowPing = false;
      allowedTCPPorts = [ ];
      allowedUDPPorts = [ ];
      interfaces.tailscale0 = {
        allowedTCPPorts = [ 22 ];
      };
      logRefusedConnections = true;
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

  # zramSwap removed — btrfs on this host uses an NVMe SSD; zram was causing
  # unnecessary CPU overhead and competing with the btrfs compression (zstd).
  # Swap is now handled by the btrfs swapfile (if configured) or none at all.
  # (Block deleted — no replacement needed.)

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  xdg.mime = {
    enable = true;
    defaultApplications = {
      "text/html" = "vivaldi-stable.desktop";
      "x-scheme-handler/http" = "vivaldi-stable.desktop";
      "x-scheme-handler/https" = "vivaldi-stable.desktop";
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
    amdgpu = {
      opencl.enable = true;
      initrd.enable = true;
    };
    graphics = {
      enable = true;
      enable32Bit = true;
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
          fprintAuth = false;
        };
        login = {
          enableGnomeKeyring = true;
          fprintAuth = false;
        };
      };
    };
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
    fstrim = {
      enable = true;
      interval = "weekly";
    };

    # --- btrbk: automated btrfs snapshot management ---
    # Takes hourly snapshots of / and /home, retained on a sliding schedule:
    #   - minimum: 2 days of all snapshots
    #   - 48 hourly, 14 daily, 8 weekly, 6 monthly
    # Snapshots are stored in /.snapshots (a hidden subvolume at the root).
    # Uses mbuffer for faster data transfer during snapshot send/receive.
    btrbk = {
      enable = true;
      extraPackages = [ pkgs.mbuffer ];
      instances = {
        "framey-snapshots" = {
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

    # --- btrfs autoScrub: periodic data-integrity scrubbing ---
    # Runs monthly across / and /home to detect and repair silent corruption
    # (bit rot). Btrfs checksums every block; scrub verifies and self-heals
    # using redundant copies or parity.
    btrfs.autoScrub = {
      enable = true;
      interval = "monthly";
      fileSystems = [ "/" "/home" ];
    };

    # --- USBGuard: USB device authorization policy ---
    # Enforces a default-deny policy for USB devices. Known-safe device
    # classes (mass storage, HID, Bluetooth) are allowed automatically;
    # everything else is blocked until explicitly authorized via usbguard CLI.
    # Members of the 'wheel' group can manage the daemon via IPC.
    usbguard = {
      enable = true;
      IPCAllowedGroups = [ "wheel" ];
      rules = ''
        # Allow existing devices at boot
        allow with-interface == "{ 08* * }"  # mass storage
        allow with-interface == "{ 03* * }"  # HID
        allow with-interface == "{ e0* * }"  # Bluetooth
        # Block everything else by default
        block
      '';
    };
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
          "default.clock.quantum"     = 2048;
          "default.clock.min-quantum" = 1024;
          "default.clock.max-quantum" = 4096;
        };
      };

      # Grant QEMU's PipeWire client RT scheduling via WirePlumber policy.
      # libvirtd-launched QEMU bypasses normal RTKit session negotiation,
      # so we explicitly match on the binary name and set rt.prio.
      wireplumber.extraConfig."92-qemu-rt" = {
        "monitor.alsa.rules" = [];
        "wireplumber.settings" = {};
        "wireplumber.profiles" = {
          main."monitor.libcamera" = "disabled";
        };
        "node.rules" = [
          {
            matches = [ { "application.process.binary" = ".qemu-system-x86_64-wrapped"; } ];
            actions = {
              update-props = {
                "node.latency"  = "2048/48000";
                "rt.prio"       = 88;
                "rt.time.soft"  = 200000;
                "rt.time.hard"  = 200000;
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
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 20;

        #Optional helps save long term battery health
        START_CHARGE_THRESH_BAT0 = 25; # 40 and below it starts to charge
        STOP_CHARGE_THRESH_BAT0 = 90; # 80 and above it stops charging

      };
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
    dconf.enable = true;
    streamdeck-ui.enable = true;
  };

  environment = {
    systemPackages = with pkgs; [
      sbctl
      lm_sensors
      poweralertd
      unzip
      dig
      whois
      iotop
      networkmanager-openconnect
      vscode
    ];
    sessionVariables = {
      NIXOS_OZONE_WL = "1";
      EDITOR = "nvim";
      BROWSER = "vivaldi";
    };
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
    spiceUSBRedirection.enable = true;
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
      };
    };
  };
  system.stateVersion = "23.05";

  # --- NFS mounts from dozer (NAS) ---
  # Uses systemd automount (noauto) so the mount is only established on first
  # access, and unmounted after 5 minutes of idle to save bandwidth.
  # 'timeo=14' and 'retrans=2' tune timeout/retry for unreliable links.
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

  # fscrypt: Consider as future option for per-directory encryption in /home.
  # LUKS2 already provides full-disk encryption — fscrypt would add defense-in-depth.
  # See: https://nixos.org/manual/nixos/stable/#sec-fscrypt
}
