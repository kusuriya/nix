{ config, pkgs, inputs, lib, osConfig, ... }:
{
  nixpkgs.config.allowUnfree = true;
  home.username = "kusuriya";
  home.homeDirectory = "/home/kusuriya";
  home.stateVersion = "23.11";
  home.packages = with pkgs; [
    neovim
    obsidian
    parsec-bin
    fortune
    htop
    _1password-gui
    _1password
    unzip
    unrar
    p7zip
    gnupg
    wget
    curl
    netcat
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
    fluffychat
    element-desktop
    discord
    signal-desktop
    gparted
    transmission-qt
    (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))
    vscode
    distrobox
    microsoft-edge
    gnomeExtensions.gsconnect
    tailscale-systray
    gnomeExtensions.tailscale-qs
    via
    telegram-desktop
  ];
  services = {
    ssh-agent.enable = true;
  };
  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    XDG_BIN_HOME = "\${HOME}/.local/bin";
  };

  programs = {
    home-manager.enable = true;
    fzf = {
      enable = true;
      enableZshIntegration = true;
    };
    zsh = {
      enable = true;
      history = {
        size = 10000;
        path = ".config/zsh/history";
	expireDuplicatesFirst = true;
	ignoreAllDups = true;
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
	update = "sudo nixos-rebuild switch";
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
}
