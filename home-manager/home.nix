{ config
, pkgs
, inputs
, lib
, ...
}:
{
  imports = [
    ../modules/desktop/hyprland
  ];
  #config = {
  #  environment.systemPackages = [
  #    inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin
  #  ];
  #};
  nixpkgs = {
    config = {
      allowUnfree = true;
      permittedInsecurePackages = [
        "electron-27.3.11"
      ];
    };

  };
  modules.hyprland = {
    enable = true;
    monitors = [
      "desc:HP Inc. HP X27q 6CM1210654,preferred,0x0,1.25"
      "desc:BOE NE135A1M-NY1,preferred,auto-right,2,vrr,2"
      "desc:LG Electronics LG SDQHD 302NTCZF0715,preferred,auto-left,1.25"
      "desc:LG Electronics LG SDQHD 409NTLE8K432,preferred,auto-right,1.25"
      "desc:Dell Inc. DELL U2718Q 4K8X785O0L3L,preferred,auto-right,1.5,transform,3"
      ",preferred,auto,auto"
    ];
  };
  systemd.user.startServices = "sd-switch";
  home = {
    username = "kusuriya";
    homeDirectory = "/home/kusuriya";
    stateVersion = "24.11";
    packages = with pkgs; [

      #passwords
      _1password-gui
      _1password-cli

      openconnect
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

      #dev
      devenv
      direnv
      distrobox

      logseq

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
      dissent
      discord
      signal-desktop
      slack
      telegram-desktop
      vesktop
      zoom-us
      weechat
      teams-for-linux

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
      inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin

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
      WLR_RENDERER = "vulkan";

    };
  };
  catppuccin = {
    enable = true;
    flavor = "macchiato";
  };
  services = {
    kdeconnect.enable = true;
    gnome-keyring = {
      enable = true;
      components = [ "pkcs11" "secrets" "ssh" ];
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
    nixvim = {
      enable = true;
      defaultEditor = true;
      vimdiffAlias = true;
      viAlias = true;
      vimAlias = true;
      colorschemes.catppuccin.enable = true;
      plugins = {
        lualine.enable = true;
        treesitter = {
          enable = true;
          folding = false;
          grammarPackages = pkgs.vimPlugins.nvim-treesitter.allGrammars;
          settings = {
            highlight.enable = true;
            auto_install = true;
            indent.enable = true;
          };
        };
        coq-nvim.enable = true;
        nix.enable = true;
        telescope.enable = true;
        lsp.enable = true;
        web-devicons.enable = true;
        cmp.enable = true;
        gitgutter.enable = true;
        nvim-tree = {
          enable = true;
          openOnSetupFile = true;
          autoReloadOnWrite = true;
          git.enable = true;
        };

      };
      opts = {
        number = true;
        relativenumber = true;
        shiftwidth = 2;
        tabstop = 2;
        smarttab = true;
        expandtab = true;
        mouse = "nvi";

      };
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
