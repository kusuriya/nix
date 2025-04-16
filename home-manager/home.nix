{ config
, pkgs
, inputs
, lib
, ...
}:
{
  imports = [
  ];
  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-27.3.11"
      ];
    };

  };
  home = {
    username = "kusuriya";
    homeDirectory = "/home/kusuriya";
    stateVersion = "24.11";
    packages = with pkgs; [

      #passwords
      _1password-gui
      _1password-cli

      logseq
      parsec-bin
      rclone
      rsync
      yt-dlp
      inkscape
      gimp
      cider
      libreoffice
      transmission_4-qt
      via
      freecad
      drawio
      calibre
      alacritty
      appimage-run
      btop
      moonlight-qt
      element-desktop
      virt-manager
      imagemagick
      pandoc
      catt
      unstable.looking-glass-client
      texliveFull
      kdePackages.kmail

      #dev
      devenv
      direnv
      distrobox


      # themes
      arc-kde-theme
      tango-icon-theme
      papirus-icon-theme
      gnome-icon-theme
      adwaita-icon-theme
      rose-pine-cursor
      cascadia-code
      tokyo-night-gtk


      #communication
      discord
      signal-desktop-bin
      slack
      telegram-desktop
      zoom-us
      weechat


      #nix
      nixpkgs-fmt
      statix
      deadnix
      treefmt

      #Sec Stuff
      burpsuite
      nmap

      #browser
      chromium
      microsoft-edge
      (vivaldi.overrideAttrs (oldAttrs: {
        dontWrapQtApps = false;
        dontPatchELF = true;
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.kdePackages.wrapQtAppsHook ];
      }))
      vivaldi-ffmpeg-codecs
      inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin
      librewolf

      #Dictonary
      (aspellWithDicts (
        dicts: with dicts; [
          en
          en-computers
          en-science
        ]
      ))

    ];
    file = {
      # ".screenrc".source = dotfiles/screenrc;
    };
    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "firefox-nightly";
      TERMINAL = "alacritty";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      XDG_BIN_HOME = "\${HOME}/.local/bin";
      NIXOS_OZONE_WL = "1";

    };
  };
  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };
  services = {
    kdeconnect = {
      enable = true;
      indicator = true;
    };
    gnome-keyring = {
      enable = true;
      components = [ "pkcs11" "secrets" "ssh" ];
    };
  };
  programs = {
    mpv.enable = true;
    imv.enable = true;
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
    vscode = {
      enable = true;
    };
    neovim = {
      enable = true;
      vimdiffAlias = true;
      viAlias = true;
      vimAlias = true;
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
        set -g status-right-length 150
        set -g status-right '[ #{host_short} | %a %F %R]'
        set -g window-status-current-format "#I:#W "
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
    };
  };
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

}
