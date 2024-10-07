{ config, pkgs, inputs, lib, osConfig, ... }:
{
  imports = [
  ];
  nixpkgs.config.allowUnfree = true;
  home.username = "kusuriya";
  home.homeDirectory = "/home/kusuriya";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    neovim
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
    transmission_4-qt
    (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))
    vscode
    distrobox
    microsoft-edge
    tailscale-systray
    via
    kitty
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
    clipman
  ];
  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    XDG_BIN_HOME = "\${HOME}/.local/bin";
    NIXOS_OZONE_WL = "1";
  };

  programs = {
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
      enableAutosuggestions = true;
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
  };
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
  systemd.user.startServices = "sd-switch";
}
