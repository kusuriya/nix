{ config
, pkgs
, inputs
, ...
}:
{
  imports = [
    ../modules/desktop/hyprland
    inputs.catppuccin.homeManagerModules.catppuccin
  ];

  nixpkgs.config =
    {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-27.3.11"
      ];
    };
  modules.hyprland = {
    enable = true;
    monitors = [
      "desc:HP Inc. HP X27q 6CM1210654,preferred,0x0,1,vrr,1"
      "desc:BOE NE135A1M-NY1,preferred,auto-right,2,vrr,1"
      "desc:LG Electronics LG SDQHD 302NTCZF0715,preferred,auto-left,1.25,vrr,1"
      ",preferred,auto,auto"
    ];
  };
  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };

  home = {
    username = "kusuriya";
    homeDirectory = "/home/kusuriya";
    stateVersion = "24.11";
    packages = with pkgs; [
      _1password-gui
      _1password-cli
      arc-kde-theme
      dconf
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
      #calibre
      alacritty
      orca-slicer
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
      logseq

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
      weechat

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
          geometry = "550x25-5+30";
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
      #package = pkgs.firefox-wayland;
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
        set -g update-environment 'DISPLAY SSH_ASKPASS SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY TERM HYPRLAND_CMD HYPRLAND_INSTANCE_SIGNATURE'
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
