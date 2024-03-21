{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: {
  # You can import other NixOS modules here
  imports = [
    hardware.nixosModules.framework-13-7040-amd
    ./home-manager.nix
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    # You can add overlays here
    overlays = [
      # Add overlays your own flake exports (from overlays and pkgs dir):
      outputs.overlays.additions
      outputs.overlays.modifications
      outputs.overlays.unstable-packages

      # You can also add overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      allowUnfree = true;
    };
  };

  # This will add each flake input as a registry
  # To make nix3 commands consistent with your flake
  nix.registry = (lib.mapAttrs (_: flake: {inherit flake;})) ((lib.filterAttrs (_: lib.isType "flake")) inputs);

  # This will additionally add your inputs to the system's legacy channels
  # Making legacy nix commands consistent as well, awesome!
  nix.nixPath = ["/etc/nix/path"];
  environment.etc =
    lib.mapAttrs'
    (name: value: {
      name = "nix/path/${name}";
      value.source = value.flake;
    })
    config.nix.registry;

  nix = {
    settings = {
      experimental-features = "nix-command flakes";
      auto-optimise-store = true;
      allowed-users = [ "kusuriya" "root" ];
      trusted-users = [ "kusuriya" "root" ];
    };
    gc = {
      automatic = true;
      dates = "weekly";
      # Keep the last 3 generations
      options = "--delete-older-than +3";
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 7;

  boot.initrd.luks.devices."luks-cdf83528-1527-4f69-8214-e0e660a077d0".device = "/dev/disk/by-uuid/cdf83528-1527-4f69-8214-e0e660a077d0";
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
  
  services.xserver = { 
    enable = true;
    displayManager.gdm.enable = true;
    desktopManager.gnome = {
      enable = true;
      extraGSettingsOverridePackages = [ pkgs.gnome.mutter ];
       extraGSettingsOverrides = ''
         [org.gnome.mutter]
         experimental-features=['scale-monitor-framebuffer']
       '';
    };
    libinput = {
    enable = true;
    touchpad = { 
      tapping = true;
      disableWhileTyping = true;
      clickMethod = "clickfinger";
      };
    };
    xkb = {
      layout = "us";
      variant = "";
    };    
  };
  hardware = {
    bluetooth.enable = true;
    keyboard.qmk.enable = true;
    pulseaudio.enable = false;
    opengl = {
      enable = true;
      driSupport32Bit = true;
      driSupport = true;
    };
  };

  sound.enable = true;
  security.rtkit.enable = true;

  users.users.kusuriya = {
    isNormalUser = true;
    description = "kusuriya";
    extraGroups = [ "networkmanager" "wheel" "dialout" "audio"];
  };
  
  services = { 
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
    printing.enable = true;
    fprintd.enable = false;
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      #jack.enable = true;
      #media-session.enable = true;
    };
  };

  programs = {
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "kusuriya" ];
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
  
  environment.systemPackages = with pkgs; [
   wget
   curl
   distrobox
   neovim
   linux-firmware
  ];
  
  networking.firewall.enable = true;
  system.stateVersion = "23.11"; # Did you read the comment?
}
