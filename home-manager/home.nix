{ config
, pkgs
, ...
}:
{
  imports = [
    ../programs/hyprland/hyprland.nix
  ];
  nixpkgs.config.allowUnfree = true;
  home = {
    username = "kusuriya";
    homeDirectory = "/home/kusuriya";
    stateVersion = "23.05";
    packages = with pkgs; [
      _1password-gui
      _1password-cli
      arc-kde-theme
      dconf
      libsForQt5.qt5ct
      libsForQt5.qtstyleplugin-kvantum
      cliphist
      overskride
      helvum
      networkmanagerapplet
      parsec-bin
      unzip
      unrar
      p7zip
      gnupg
      rclone
      rsync
      yt-dlp
      plantuml
      jq
      inkscape
      cider
      libreoffice
      wl-clipboard-rs
      transmission_4-qt
      (aspellWithDicts (
        dicts: with dicts; [
          en
          en-computers
          en-science
        ]
      ))
      via
      distrobox
      tailscale-systray
      freecad
      calibre
      alacritty
      wofi
      waybar
      mpv
      pavucontrol
      hyprshot
      hyprpolkitagent
      hyprcursor
      hyprutils
      hyprnotify
      chromium
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
      polkit
      polkit_gnome
      rofi-wayland
      rofi-bluetooth
      wayprompt
      btop
      playerctl
      devenv
      direnv

      # themes
      tango-icon-theme
      papirus-icon-theme
      gnome-icon-theme
      adwaita-icon-theme
      rose-pine-cursor
      cascadia-code
      tokyo-night-gtk


      #communication
      vesktop
      signal-desktop
      zoom-us
      discord
      telegram-desktop
      dissent
      slack

      #nix
      nixpkgs-fmt
      statix
      deadnix
      treefmt

      #Sec Stuff
      burpsuite
      nmap
    ];
    file = {
      # ".screenrc".source = dotfiles/screenrc;
    };
    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "firefox";
      TERMINAL = "alacritty";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      XDG_BIN_HOME = "\${HOME}/.local/bin";
      NIXOS_OZONE_WL = "1";
      WLR_RENDERER = "vulkan";

    };
  };
  services = {
    kdeconnect.enable = true;
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
          font = "Cascadia Code 12";
          frame_color = "#1a1b26";
          background_color = "#7a2f7a";
          geometry = "500x5-5+30";
          format = "<b>%s</b>\\n%b";
          icon_position = "left";
        };
      };
    };
  };
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
        {
          name = "fzf";
          src = pkgs.fishPlugins.fzf-fish;
        }
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
              "browser.search.defaultenginename" = "DuckDuckGo";
              "browser.search.order.1" = "DuckDuckGo";
              "signon.rememberSignons" = false;
              "widget.use-xdg-desktop-portal.file-picker" = 1;
              "browser.aboutConfig.showWarning" = false;
              "browser.compactmode.show" = true;
              "browser.cache.disk.enable" = false; # Be kind to hard drive
              "widget.disable-workspace-management" = true;
            };
          };
        };
      };
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
        setw -g mouse on
      '';
    };

  };
  dconf = {
  enable = true;
  settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Tokyonight-Dark-B-LB";
    };
  };
  };
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };
  systemd.user.startServices = "sd-switch";
}
