{ config, pkgs, inputs, lib, osConfig, ... }:
{
  imports = [
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
    avizo
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
  };
  xdg.portal.config.common.default = "*";
  wayland.windowManager.hyprland = {
    enable = true;
  #  plugins = [
  #    inputs.hyprland-plugins.packages.${pkgs.stdenv.hostPlatform.system}.hyprexpo
  #  ];
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    xwayland.enable = true;
    systemd = {
      enable = true;
      enableXdgAutostart = true;
    };
    settings = {
      "$mainMod" = "SUPER";
      "$terminal" = "alacritty";
      "$fileManager" = "thunar";
      "$menu" = "wofi -i -I --show drun,run";
      monitor = [
        "monitor=desc:HP Inc. HP X27q 6CM1210654,preferred,0x0,1"
        "monitor=desc:Dell Inc. DELL U2718Q 4K8X785O0L3L,preferred, 0x0, 1.5"
        "monitor=desc:LG Electronics LG SDQHD 302NTCZF0715,preferred,auto-left,1.25"
        "monitor=desc:BOE NE135A1M-NY1,preferred,auto-right,2.0"
        "monitor=,preferred,auto,auto"
     ];
     exec-once = [
       "waybar"
       "gnome-keyring-daemon -s -d -c secrets"
       "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
       "dbus-update-activation-environment --all"
       "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
       "nm-applet &"
       "hypridle"
       "hyprpolkitagent"
       "wl-paste --type text --watch cliphist store"
       "wl-paste --type image --watch cliphist store"

     ];
     input = {
        kb_layout = "us";
        follow_mouse = 1;
        force_no_accel = true;
	touchpad = {
	  natural_scroll = false;
	  disable_while_typing = true;
	  clickfinger_behavior = true;
	};
      };
      general = {
        gaps_in = 4;
        gaps_out = 4;
        border_size = 0;
        "col.active_border" = "rgba(7aa2f7aa)";
        "col.inactive_border" = "rgba(414868aa)";
        layout = "dwindle";
	allow_tearing = true;
	resize_on_border = true;
      };
      xwayland = {
        force_zero_scaling = true;
	use_nearest_neighbor = false;
      };
      animations = { enabled = false; };
      dwindle = {
        pseudotile = false;
        preserve_split = true;
      };
      master = {
        new_status = "master";
      };
      gestures = {
        workspace_swipe = true;
      };
      misc = {
        disable_hyprland_logo = true;
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = false;
	vrr = 1;
	allow_session_lock_restore = true;
      };
      group = {
        drag_into_group = 2;
        groupbar = {
	  enabled = true;
	  font_size = 14;
	  "col.active" = "rgba(7aa2f7aa)"
	  "col.inactive" = "rgba(414868aa)"
	};
      };
      bind = [
      "$mainMod, K, killactive,"
      "$mainMod, V, togglefloating,"
      "$mainMod, SPACE, exec, $menu"
      "$mainMod, P, pseudo,"
      "$mainMod, J, togglesplit,"
      "$mainMod SHIFT, J, swapsplit"
      "$mainMod, left, movefocus, l"
      "$mainMod, right, movefocus, r"
      "$mainMod, up, movefocus, u"
      "$mainMod, down, movefocus, d"
      "$mainMod, G, togglegroup"
      "$mainMod SHIFT, G, moveoutofgroup"
      "$mainMod, V, exec, cliphist list|wofi --dmenu|cliphist decode|wl-copy"
      "$mainMod, S, togglespecialworkspace, magic"
      "$mainMod SHIFT, S, movetoworkspace, special:magic"
      "$mainMod SHIFT, RIGHT, movecurrentworkspacetomonitor, -1"
      "$mainMod SHIFT, LEFT, movecurrentworkspacetomonitor, +1"
"
"HYPRCURSOR_SIZE,32"
"GDK_SCALE,2"
"MOZ_ENABLE_WAYLAND,1"

      "$mainMod, 1, workspace, 1"
      "$mainMod, 2, workspace, 2"
      "$mainMod, 3, workspace, 3"
      "$mainMod, 4, workspace, 4"
      "$mainMod, 5, workspace, 5"
      "$mainMod, 6, workspace, 6"
      "$mainMod, 7, workspace, 7"
      "$mainMod, 8, workspace, 8"
      "$mainMod, 9, workspace, 9"
      "$mainMod, 0, workspace, 10"
      "$mainMod SHIFT, 1, movetoworkspace, 1"
      "$mainMod SHIFT, 2, movetoworkspace, 2"
      "$mainMod SHIFT, 3, movetoworkspace, 3"
      "$mainMod SHIFT, 4, movetoworkspace, 4"
      "$mainMod SHIFT, 5, movetoworkspace, 5"
      "$mainMod SHIFT, 6, movetoworkspace, 6"
      "$mainMod SHIFT, 7, movetoworkspace, 7"
      "$mainMod SHIFT, 8, movetoworkspace, 8"
      "$mainMod SHIFT, 9, movetoworkspace, 9"
      "$mainMod SHIFT, 0, movetoworkspace, 10"

      "$mainMod, mouse_down, workspace, e+1"
      "$mainMod, mouse_up, workspace, e-1"
    ];
    bindm = [
      "$mainMod, mouse:272, movewindow"
      "$mainMod, mouse:273, resizewindow"
    ];
    bindel = [
     ",XF86AudioRaiseVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%+"
     ",XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 1%-"
     ",XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"
     ",XF86AudioMicMute, exec, wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"
     ",XF86MonBrightnessUp, exec, brightnessctl s 5%"
     ",XF86MonBrightnessDown, exec, brightnessctl s 5%-"
    ];
    env = {
      "XCURSOR_SIZE,32"
      "HYPRCURSOR_SIZE,32"
      "GDK_SCALE,2"
      "MOZ_ENABLE_WAYLAND,1"
    };
    };
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
