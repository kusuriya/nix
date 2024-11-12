{ config, pkgs, inputs, lib, osConfig, ... }:
{
  imports = [
    ./config/hyprland/hyprland.nix
  ];
  nixpkgs.config.allowUnfree = true;
  home.username = "kusuriya";
  home.homeDirectory = "/home/kusuriya";
  home.stateVersion = "23.05";
  home.packages = with pkgs; [
    _1password-gui
    _1password-cli
    fractal
    cliphist
    rose-pine-cursor
    overskride
    dissent
    helvum
    tango-icon-theme
    papirus-icon-theme
    gnome-icon-theme
    adwaita-icon-theme
    virt-manager
    networkmanagerapplet
    parsec-bin
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
    hyprpolkitagent
    hyprcursor
    hyprutils
    eww
    hyprnotify
    chromium
    clipman
    cascadia-code
    tokyo-night-gtk
    pamixer
    dunst
    appimage-run
    swayosd
    wlogout
    clipman
    nautilus
    zenity
    eog
    gnome-keyring
    gnome-control-center
    polkit
    polkit_gnome
    rofi-wayland
    rofi-bluetooth
    wayprompt
    btop
    playerctl
    vesktop

    #Sec Stuff
    burpsuite
    nmap
  ];
  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
  };
  home.sessionVariables = {
    EDITOR = "nvim";
    BROWSER = "firefox";
    TERMINAL = "alacritty";
    MOZ_ENABLE_WAYLAND = "1";
    MOZ_USE_XINPUT2 = "1";
    XDG_BIN_HOME = "\${HOME}/.local/bin";
    NIXOS_OZONE_WL = "1";
    WLR_RENDERER = "vulkan";

  };
  services = {
    gnome-keyring = {
      enable = true;
      components = [ "secrets" ];
    };
    dunst = {
      enable = true;
      settings = {
        global = {
	  offset = "30x50";
	  origin = "bottom-right";
	  font = "Cascadia Code 14";
	  frame_color = "#1a1b26";
	  background_color = "#7a2f7a";
	};
      };
    };
  };
  xdg.portal.config.common.default = "*";
 programs = {
    alacritty = {
      enable = true;
      settings = {
        env.TERM = "xterm-256color";
	colors = {
	  primary = {
	    "background" = "#1a1b26";
            "foreground" = "#a9b1d6";
	  };
	  normal = {
	    "black" = "#32344a";
            "red" = "#f7768e";
            "green" = "#9ece6a";
            "yellow" = "#e0af68";
            "blue" = "#7aa2f7";
            "magenta" = "#ad8ee6";
            "cyan" = "#449dab";
            "white" = "#787c99";
	  };
	  bright = {
	    "black" = "#444b6a";
            "red" = "#ff7a93";
            "green" = "#b9f27c";
            "yellow" = "#ff9e64";
            "blue" = "#7da6ff";
            "magenta" = "#bb9af7";
            "cyan" = "#0db9d7";
            "white" = "#acb0d0";
	  };
	  selection = {
	    "background" = "#7aa2f7";
	  };
	};
      };
    };
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
    git = {
      enable = true;
      userName = "Jason Barbier";
      userEmail = "jason@corrupted.io";
    };
    firefox = {
      enable = true;
      package = pkgs.firefox-wayland;
      profiles = {
        default = {
	  id = 0;
	  name = "kusuriya";
	  isDefault = true;
	  settings = {
	    settings = {
            # "browser.startup.homepage" = "https://duckduckgo.com";
            "browser.search.defaultenginename" = "DuckDuckGo";
            "browser.search.order.1" = "DuckDuckGo";

            "signon.rememberSignons" = false;
            "widget.use-xdg-desktop-portal.file-picker" = 1;
            "browser.aboutConfig.showWarning" = false;
            "browser.compactmode.show" = true;
            "browser.cache.disk.enable" = false; # Be kind to hard drive
	    
	    "widget.disable-workspace-management" = true;
          };
          search = {
            force = true;
            default = "DuckDuckGo";
            order = [ "DuckDuckGo" "Google" ];
          };

	  };
	};
      };
    };
    eww = {
      enable = true;
      enableFishIntegration = true;
      enableZshIntegration = true;
      configDir = ./dot-files/eww;
    };
    neovim = {
      enable = true;
      defaultEditor = true;
      withRuby = true;
      withPython3 = true;
    };
    ranger = {
      enable = true;
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
