{ pkgs
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
        "electron-39.8.10"
      ];
    };

  };
  home = {
    username = "kusuriya";
    homeDirectory = "/home/kusuriya";
    stateVersion = "24.11";
    file = {
      ".config/sway/config" = { source = ./dotfiles/sway/config; };
      ".config/sway/config.d/exec.conf" = { source = ./dotfiles/sway/config.d/exec.conf; };
      ".config/sway/config.d/idle.conf" = { source = ./dotfiles/sway/config.d/idle.conf; };
      ".config/sway/idle-guard.sh" = { source = ./dotfiles/sway/idle-guard.sh; executable = true; };
      ".config/mako/config" = { source = ./dotfiles/mako/config; };
      ".config/swaync/config.json" = { source = ./dotfiles/swaync/config.json; };
      ".config/swaync/style.css" = { source = ./dotfiles/swaync/style.css; };
      ".config/eww/eww.yuck" = { source = ./dotfiles/eww/eww.yuck; };
      ".config/eww/eww.scss" = { source = ./dotfiles/eww/eww.scss; };
      ".config/kanshi/config" = { source = ./dotfiles/kanshi/config; };
      ".config/ghostty/config" = { source = ./dotfiles/ghostty/config; };
      ".config/ghostty/themes/catppuccin-mocha" = { source = ./dotfiles/ghostty/themes/catppuccin-mocha; };
      ".config/nvim" = {
        source = lib.cleanSourceWith {
          src = ./dotfiles/nvim;
          filter = path: _type:
            !lib.hasPrefix "${toString ./dotfiles/nvim}/undo" (toString path);
        };
        recursive = true;
      };
    };
    sessionVariables = {
      EDITOR = "nvim";
      TERMINAL = "alacritty";
      MOZ_ENABLE_WAYLAND = "1";
      MOZ_USE_XINPUT2 = "1";
      XDG_BIN_HOME = "\${HOME}/.local/bin";
      NIXOS_OZONE_WL = "1";

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
      enableFishIntegration = true;
    };
    direnv = {
      enable = true;
      nix-direnv.enable = true;
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
    starship = {
      enable = true;
      enableFishIntegration = true;
    };
    zoxide = {
      enable = true;
      enableFishIntegration = true;
    };
    yazi = {
      enable = true;
      enableFishIntegration = true;
      shellWrapperName = "y"; # silence legacy-default warning (default changed from "yy" in 26.05)
      settings = {
        mgr = {
          show_hidden = false;
          sort_by = "natural";
          sort_dir_first = true;
        };
      };
    };
    atuin = {
      enable = true;
      enableFishIntegration = true;
      settings = {
        enter_accept = false;
      };
    };
    git = {
      enable = true;
      settings = {
        user = {
          name = "Jason Barbier";
          email = "jason@corrupted.io";
        };
      };
    };
    delta = {
      enable = true;
      enableGitIntegration = true;
      options = {
        side-by-side = true;
        line-numbers = true;
        dark = true;
        syntax-theme = "Dracula";
        navigate = true;
      };
    };
    neovim = {
      enable = true;
      vimdiffAlias = true;
      viAlias = true;
      vimAlias = true;
      defaultEditor = true;
      withPython3 = true;
      withRuby = true;
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
  manual = {
    html.enable = false;
    json.enable = false;
    manpages.enable = false;
  };

}
