# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

{
  imports =
    [ 
      ./hardware-configuration.nix
      ./update.nix
    ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 7;

  boot.initrd.luks.devices."luks-cdf83528-1527-4f69-8214-e0e660a077d0".device = "/dev/disk/by-uuid/cdf83528-1527-4f69-8214-e0e660a077d0";
  boot.kernelPackages = pkgs.linuxPackages_latest;
  networking.hostName = "framey"; # Define your hostname.
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
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      allowed-users = [ "kusuriya" "root" ];
      trusted-users = [ "kusuriya" "root" ];
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
  services.udev.packages = [ pkgs.via ];
  services.printing.enable = true;
  sound.enable = true;
  security.rtkit.enable = true;
  services.fprintd.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
    #media-session.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kusuriya = {
    isNormalUser = true;
    description = "Jason Barbier";
    extraGroups = [ "networkmanager" "wheel" "dialout" ];
  };
  services.tailscale = {
    enable = true;
    useRoutingFeatures = "client";
    interfaceName = "userspace-networking";
  };
  services.fwupd.enable = true;
  services.fstrim.enable = true;
  services.thermald.enable = true;
  services.gvfs.enable = true;
  services.hardware.bolt.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ "kusuriya" ];
  };
  programs.tmux = {
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
  programs.dconf.enable = true;
  fonts.packages = with pkgs; [
    dejavu_fonts
    emacs-all-the-icons-fonts
    jetbrains-mono
    font-awesome
    noto-fonts
    noto-fonts-emoji
    nerdfonts
  ];
  
  nixpkgs.config.allowUnfree = true;
  
  environment.systemPackages = with pkgs; [
   vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
   wget
   curl
   distrobox
   neovim
   linux-firmware
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  
  networking.firewall.enable = true;
  system.stateVersion = "23.11"; # Did you read the comment?

}
