{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    ./home-manager.nix
    ./hardware-configuration.nix
    ./oom.nix
    inputs.hardware.nixosModules.framework-13-7040-amd
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

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
    in {
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      allowed-users = [ "kusuriya" "root" ];
      trusted-users = [ "kusuriya" "root" ];
      nix-path = config.nix.nixPath;
      substituters = ["https://hyprland.cachix.org"];
      trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
    };
    registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
    gc = {
      automatic = true;
      dates = "weekly";
      # Keep the last week
      options = "--delete-older-than 7d";
    };
  };
  powerManagement.enable = true;
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';
  system = {
    autoUpgrade = {
      enable = true;
      flake = "github:kusuriya/nix";
      flags = [ "--cores 8" ];
      allowReboot = true;
      rebootWindow.lower = "00:01";
      rebootWindow.upper = "05:00";
      persistent = true;
    };
  };
  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 7;


  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.hostName = "framey";
  networking.networkmanager.enable = true;
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
  boot.plymouth.enable = true;
  services.power-profiles-daemon.enable = true;
  #services.desktopManager.cosmic.enable = true;
  services.flatpak.enable = true;
  services.dbus.enable = true;
  services.upower.enable = true;
  services.fprintd.enable = false;
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
  boot.tmp = {
    useTmpfs = true;
    tmpfsSize = "30%";
  };
  xdg.portal = {
    enable = true;
    config = pkgs.xdg-desktop-portal-hyprland
    extraPortals = [
      #pkgs.xdg-desktop-portal-hyprland
      pkgs.xdg-desktop-portal-gtk
      pkgs.xdg-desktop-portal-kde
    ];
  };
  services.greetd = {
    enable = true;
    settings = rec {
      initial_session = {
        command = "Hyprland";
	user = "kusuriya";
       };
       default_session = initial_session;
    };
   };
  services.xserver = { 
    enable = true;
    xkb = {
      layout = "us";
      variant = "";
    };    
    videoDrivers = [ "amdgpu" ];
  };
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    nssmdns6 = true;
    wideArea = true;
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

  hardware = {
    logitech.wireless = {
      enable = true;
      enableGraphical = true;
    };
    bluetooth.enable = true;
    keyboard.qmk.enable = true;
    pulseaudio.enable = false;
    graphics = {
      enable = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd
	clinfo
	amdvlk
      ];
    };

  };
  security.rtkit.enable = true;
  security.pam.services.login.enableGnomeKeyring = true;

  users.users.kusuriya = {
    isNormalUser = true;
    description = "kusuriya";
    extraGroups = [ "cdrom" "networkmanager" "wheel" "dialout" "audio" "video" "system" "libvirtd" "kvm" "render"];
    shell = pkgs.fish;

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
  };
  security.polkit.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1";
  programs = {
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [ thunar-archive-plugin thunar-volman thunar-media-tags-plugin];
    };
    fish.enable = true;
    #hyprland = {
    #  enable = true;
    #  xwayland.enable = true;
    #  package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    #};
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
  
  fonts.packages = with pkgs; [
    dejavu_fonts
    emacs-all-the-icons-fonts
    jetbrains-mono
    font-awesome
    noto-fonts
    noto-fonts-emoji
    nerdfonts
  ];
  
  environment = {
    systemPackages = with pkgs; [
     wget
     brightnessctl
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
     arc-kde-theme
     libsForQt5.qt5ct
     libsForQt5.qtstyleplugin-kvantum

     ];
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
 };


 programs.kdeconnect = {
    enable = true;
  };

  networking.firewall.enable = true;
  system.stateVersion = "23.05"; # Did you read the comment
}

