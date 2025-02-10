# modules/desktop/hyprland/default.nix

{ config
, pkgs
, inputs
, lib
, osConfig
, ...
}:
with lib;
let
  cfg = config.modules.hyprland;
in
{
  imports = [
    ./waybar.nix
    ./hyprlock.nix
    ./hypridle.nix
    ./swaync.nix
  ];
  options.modules.hyprland = {
    enable = mkEnableOption "Hyprland configuration";
    monitors = mkOption {
      type = types.listOf types.str;
      default = [ ",preferred,auto,auto" ];
      description = "Monitor configuration";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs;
      [
        dunst
        wl-clipboard-rs
        clipman
        nautilus
        gnome-keyring
        polkit
        polkit_gnome
        wofi
        pavucontrol
        networkmanagerapplet
        cliphist
        alacritty
        swayosd
        xarchiver
        mpv
        imv
        blueman
        pamixer
        wf-recorder
        grim
        slurp
        libnotify
        swww
        playerctl
        hyprshot
        hyprpolkitagent
        hypridle
        hyprcursor
        hyprutils
        hyprnotify
        networkmanagerapplet
        dconf
        unzip
        unrar
        p7zip
        gnupg
        tailscale-systray
        wlsunset
        overskride
      ];
    catppuccin.hyprland.enable = true;
    wayland.windowManager.hyprland = {
      enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      xwayland.enable = true;
      sourceFirst = true;
      settings = {
        xwayland = {
          enabled = true;
          use_nearest_neighbor = false;
        };
        "$mainMod" = "SUPER";
        "$terminal" = "alacritty";
        "$fileManager" = "thunar";
        "$menu" = "wofi -i -I --show drun,run";
        monitor = cfg.monitors;
        exec-once = [
          "systemctl --user import-environment"
          "waybar"
          "gnome-keyring-daemon -s -d -c secrets"
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
          "dbus-update-activation-environment --all"
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          "nm-applet"
          "hypridle"
          "wl-paste --type text cliphist store"
          "wl-paste --type image cliphist store"
          "1password --silent"
          "tailscale-systray"
          "wlsunset -t 5000 -T 6500 -l 47.253080 -L -122.441530"
          "swaync"

        ];
        input = {
          kb_layout = "us";
          follow_mouse = "0";
          accel_profile = "adaptive";
          touchpad = {
            natural_scroll = false;
            disable_while_typing = true;
            clickfinger_behavior = true;
          };
        };
        general = {
          gaps_in = 0;
          gaps_out = 3;
          border_size = 1;
          "col.active_border" = "$overlay1";
          "col.inactive_border" = "$surface0";
          layout = "dwindle";
        };
        cursor = {
          hide_on_key_press = true;
          inactive_timeout = 60;
        };
        dwindle = {
          pseudotile = true;
          preserve_split = true;
          force_split = 0;
          smart_split = false;
        };
        gestures = {
          workspace_swipe = true;
        };
        misc = {
          disable_hyprland_logo = true;
          disable_splash_rendering = true;
          enable_swallow = true;
        };
        group = {
          #drag_into_group = 2;
          merge_groups_on_drag = false;
          "col.border_active" = "$overlay1";
          "col.border_inactive" = "$surface0";
          groupbar = {
            enabled = true;
            font_size = 16;
            text_color = "$text";
            height = 25;
            "col.active" = "$surface2";
            "col.inactive" = "$surface0";
          };
        };
        bind = [
          "$mainMod, Q, killactive,"
          "$mainMod, F, focusurgentorlast"
          "$mainMod CTRL, L, exec, hyprlock"
          "$mainMod SHIFT, F, togglefloating,"
          "$mainMod, SPACE, exec, $menu"
          "$mainMod, P, pseudo,"
          "$mainMod SHIFT, J, togglesplit,"
          "$mainMod CTRL, J, swapsplit"
          "$mainMod, left, movefocus, l"
          "$mainMod, right, movefocus, r"
          "$mainMod, up, movefocus, u"
          "$mainMod, down, movefocus, d"
          "$mainMod, h, movefocus, l"
          "$mainMod, j, movefocus, d"
          "$mainMod, k, movefocus, u"
          "$mainMod, l, movefocus, r"
          # groups
          "$mainMod SHIFT, G, togglegroup"
          "$mainMod, Tab, changegroupactive, f"
          "mainMod CTRL, Tab, changegroupactive, b"
          "$mainMod, G, moveoutofgroup"

          "$mainMod SHIFT, V, exec, uwsm-app -- cliphist list|wofi --dmenu|cliphist decode|wl-copy"
          "$mainMod, V, sendshortcut, SHIFT, INSERT,"
          "$mainMod, C, sendshortcut, CONTROL, INSERT,"

          "$mainMod Ctrl, 4, exec, uwsm-app -- hyprshot --clipboard-only -m region -z"
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"
          "$mainMod ALT, RIGHT, movecurrentworkspacetomonitor, -1"
          "$mainMod ALT, LEFT, movecurrentworkspacetomonitor, +1"
          "$mainMod SHIFT, RIGHT, workspace, m+1"
          "$mainMod SHIFT, LEFT, workspace, m-1"
          "$mainMod ALT, H, movecurrentworkspacetomonitor, -1"
          "$mainMod ALT, L, movecurrentworkspacetomonitor, +1"
          "$mainMod SHIFT, h, workspace, m+1"
          "$mainMod SHIFT, l, workspace, m-1"

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
          "CONTROL, Space, exec, uwsm-app -- 1password --quick-access"
        ];
        bindm = [
          "$mainMod, mouse:272, movewindow"
          "$mainMod, mouse:273, resizewindow"
        ];
        bindel = [
          # Audio controls
          ", XF86AudioRaiseVolume, exec, ${pkgs.swayosd}/bin/swayosd-client --output-volume raise"
          ", XF86AudioLowerVolume, exec, ${pkgs.swayosd}/bin/swayosd-client --output-volume lower"
          ", XF86AudioMute, exec, ${pkgs.swayosd}/bin/swayosd-client --output-volume mute-toggle"
          ", XF86AudioMicMute, exec, ${pkgs.swayosd}/bin/swayosd-client --input-volume mute-toggle"

          # Playback controls
          ", XF86AudioPlay, exec, ${pkgs.playerctl}/bin/playerctl play-pause"
          ", XF86AudioNext, exec, ${pkgs.playerctl}/bin/playerctl next"
          ", XF86AudioPrev, exec, ${pkgs.playerctl}/bin/playerctl previous"
          ", XF86AudioStop, exec, ${pkgs.playerctl}/bin/playerctl stop"

          # Sreen brightness controls
          ", XF86MonBrightnessUp, exec, ${pkgs.swayosd}/bin/swayosd-client --brightness raise"
          ", XF86MonBrightnessDown, exec, ${pkgs.swayosd}/bin/swayosd-client --brightness lower"

        ];
        env = [
          "XCURSOR_SIZE,24"
          "HYPRCURSOR_SIZE,24"
          "GDK_SCALE,1.25"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "XDG_SESSION_TYPE,wayland"
          "GDK_BACKEND,wayland,x11,*"
          "NIXOS_OZONE_WL,1"
          "MOZ_ENABLE_WAYLAND,1"
          "SDL_VIDEODRIVER,wayland"
          "OZONE_PLATFORM,wayland"
          "WLR_RENDERER,vulkan"
          "_JAVA_AWT_WM_NONREPARENTING,1"
        ];
        windowrulev2 = [
          "suppressevent maximize, class:.*"
          "suppressevent minimize, class:.*"

          # modals
          "float,title:^(Open)$"
          "float,title:^(Choose Files)$"
          "float,title:^(Save As)$"
          "float,title:^(Open Files)$"
          "float,class:^(xdg-desktop-portal-gtk)$"
          "stayfocused, title:Quick Access — 1Password"
          "stayfocused, class:polkit-gnome-authentication-agent-1"
          "size 800 600, class:poklit-gnome-authentication-agent-1"
          "float,title:^(Volume Control)$"
          "size 800 600,title:^(Volume Control)$"
          "float,class:^(nm-connection-editor)$"
          "float,class:^(blueman-manager)$"
          "float,class:^(nm-connection-editor)$"
          "workspace special:magic silent,title:^(.*)(Picture-in-Picture)$"
          "float,class:^(1Password)$"
          "size 900 600,class:^(1Password)$"
          "float,class:^(easyeffects)$"
          "workspace,5,class:^(gamescope)$"

          # Center floating windows
          "center,class:^(pavucontrol)$"
          "center,class:^(blueman-manager)$"
          "center,class:^(1Password)$"

          ### Zoom
          "size 360 690,class:(^Zoom)$"
          "float,class:(^Zoom)$"
          "noanim,class:(^Zoom)$"
          "nodim,class:(^Zoom)$"
          "noblur,class:(^Zoom)$"

          ## ### Zoom Screen Sharing
          "float,title:^as_toolbar$,class:(^Zoom)$"
          "noborder,title:^as_toolbar$,class:(^Zoom)$"
          "noshadow,title:^as_toolbar$,class:(^Zoom)$"
          "noblur,title:^as_toolbar$,class:(^Zoom)$"

        ];
      };
      extraConfig = ''
        # Window resize
        bind = $mainMod, R, submap, resize

        submap = resize
        binde = , l, resizeactive, 10 0
        binde = , h, resizeactive, -10 0
        binde = , k, resizeactive, 0 -10
        binde = , j, resizeactive, 0 10
        binde = , right, resizeactive, 10 0
        binde = , left, resizeactive, -10 0
        binde = , up, resizeactive, 0 -10
        binde = , down, resizeactive, 0 10
        bind = , escape, submap, reset
        submap = reset
      '';
    };
    services.swayosd = {
      enable = true;
      display = "DP-1";
    };
  };
}
