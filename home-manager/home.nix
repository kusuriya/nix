{ config, pkgs, inputs, lib, osConfig, ... }:
{
  imports = [
  ];
  nixpkgs.config.allowUnfree = true;
  home.username = "kusuriya";
  home.homeDirectory = "/home/kusuriya";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    gnome-boxes
    virt-manager
    networkmanagerapplet
    handbrake
    blender
    obsidian
    parsec-bin
    _1password-gui
    _1password
    unzip
    unrar
    p7zip
    gnupg
    rclone
    rsync
    slack
    zoom-us
    yt-dlp
    plantuml
    mosh
    nix-prefetch-git
    jq
    inkscape
    cider
    libreoffice
    coreutils
    wl-clipboard
    discord
    signal-desktop
    gparted
    socat
    transmission_4-qt
    (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))
    vscode
    via
    distrobox
    microsoft-edge
    tailscale-systray
    telegram-desktop
    freecad
    calibre
    alacritty
    wofi
    waybar
    mpv
    hyprpaper
    pavucontrol
    hyprshot
    hypridle
    hyprlock
    hyprpicker
    eww
    hyprnotify
    chromium
    clipman
    wineWowPackages.staging
    winetricks
    cascadia-code
    tokyo-night-gtk
    pamixer
    dunst
    appimage-run
    swayosd
    avizo
    wlogout
    clipman


    #Sec Stuff
    burpsuite
    nmap
  ];
  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
    ".config/hypr" = {
      source = config.lib.file.mkOutOfStoreSymlink ./dot-files/hypr;
      recursive = true;
    };
    ".config/alacritty" = {
      source = config.lib.file.mkOutOfStoreSymlink ./dot-files/alacritty;
      recursive = true;
    };
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    XDG_BIN_HOME = "\${HOME}/.local/bin";
    NIXOS_OZONE_WL = "1";

  };
  programs = {
    obs-studio = {
      enable = true;
      plugins = with pkgs.obs-studio-plugins; [
        wlrobs
	input-overlay
	looking-glass-obs
	obs-pipewire-audio-capture
	obs-backgroundremoval
	obs-composite-blur
      ];
    };
    home-manager.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    fish = {
      enable = true;
      plugins = [
        { name = "fzf"; src = pkgs.fishPlugins.fzf-fish; }
      ];
    };
    zsh = {
      enable = true;
      history = {
        size = 10000;
        path = ".config/zsh/history";
	expireDuplicatesFirst = true;
	#ignoreAllDups = true;
      };
      enableCompletion = true;
      enableVteIntegration = true;
      autocd = true;
      dotDir = ".config/zsh";
      shellAliases = {
        vi = "nvim";
	vim = "nvim";
	ll = "ls -c -l";
	ls = "ls -c";
	update = "sudo nixos-rebuild switch --flake /etc/nixos";
      };
      oh-my-zsh = {
        enable = true;
	plugins = [
	  "git"
	];
        theme = "gentoo";
      };
    };
    git = {
      enable = true;
      userName = "Jason Barbier";
      userEmail = "jason@corrupted.io";
    };
    firefox = {
      enable = true;
      package = pkgs.firefox-wayland;
    };
    eww = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      configDir = ./dot-files/eww;
    };
  };
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Tokyonight-Dark-B-LB";
    };
  };
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
  systemd.user.startServices = "sd-switch";
}
