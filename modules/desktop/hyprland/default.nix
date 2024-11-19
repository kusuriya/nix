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
        wofi
        pavucontrol
        networkmanagerapplet
        polkit_gnome
        cliphist
        alacritty
      ];

    wayland.windowManager.hyprland = {
      enable = true;
      catppuccin.enable = true;
      package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
      xwayland.enable = true;
      systemd = {
        enable = true;
        enableXdgAutostart = true;
        variables = [ "--all" ];
      };
      sourceFirst = true;
      settings = {
        "$mainMod" = "SUPER";
        "$terminal" = "alacritty";
        "$fileManager" = "thunar";
        "$menu" = "wofi -i -I --show drun,run";
        monitor = cfg.monitors;
        exec-once = [
          "hyprlock"
          "waybar"
          "gnome-keyring-daemon -s -d -c secrets"
          "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
          "dbus-update-activation-environment --all"
          "systemctl --user import-environment"
          "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1"
          "nm-applet &"
          "hypridle"
          "hyprpolkitagent"
          "wl-paste --type text --watch cliphist store"
          "wl-paste --type image --watch cliphist store"
          "hyprctl setcursor rose-pine-hyprcursor 24"
          "1password --silent"
          "tailscale-systray"

        ];
        input = {
          kb_layout = "us";
          follow_mouse = "1";
          accel_profile = "adaptive";
          touchpad = {
            natural_scroll = false;
            disable_while_typing = true;
            clickfinger_behavior = true;
          };
        };
        general = {
          gaps_in = 0;
          gaps_out = 4;
          border_size = 2;
          "col.active_border" = "$overlay1";
          "col.inactive_border" = "$surface0";
          layout = "dwindle";
          allow_tearing = true;
          resize_on_border = true;
        };
        cursor = {
          hide_on_key_press = true;
          inactive_timeout = 60;
        };
        xwayland = {
          force_zero_scaling = true;
          use_nearest_neighbor = false;
        };
        animations = {
          enabled = false;
        };
        decoration = {
          rounding = 4;
        };
        dwindle = {
          pseudotile = true;
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
          disable_splash_rendering = true;
          mouse_move_enables_dpms = true;
          key_press_enables_dpms = false;
          vrr = 0;
          allow_session_lock_restore = true;
          render_unfocused_fps = 60;
        };
        group = {
          drag_into_group = 2;
          "col.border_active" = "$overlay1";
          "col.border_inactive" = "$surface0";
          groupbar = {
            enabled = true;
            font_size = 12;
            text_color = "$text";
            height = 24;
            "col.active" = "$surface1";
            "col.inactive" = "$surface0";
          };
        };
        bind = [
          "$mainMod, K, killactive,"
          "$mainMod, F, focusurgentorlast"
          "$mainMod, L, exec, hyprlock"
          "$mainMod SHIFT, F, togglefloating,"
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
          "$mainMod SHIFT, V, exec, cliphist list|wofi --dmenu|cliphist decode|wl-copy"
          "$mainMod, V, sendshortcut, SHIFT, INSERT,"
          "$mainMod, C, sendshortcut, CONTROL, INSERT,"
          "$mainMod Control, S, exec, hyprshot --clipboard-only -m region -z"
          "$mainMod, S, togglespecialworkspace, magic"
          "$mainMod SHIFT, S, movetoworkspace, special:magic"
          "$mainMod ALT, RIGHT, movecurrentworkspacetomonitor, -1"
          "$mainMod ALT, LEFT, movecurrentworkspacetomonitor, +1"
          "$mainMod SHIFT, RIGHT, workspace, m+1"
          "$mainMod SHIFT, LEFT, workspace, m-1"
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
          "CONTROL, Space, exec, 1password --quick-access"
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
          "HYPRCURSOR_THEME,rose-pine-hyprcursor"
          "HYPRCURSOR_SIZE,24"
          "GDK_SCALE,1.5"
          "XDG_CURRENT_DESKTOP,Hyprland"
          "XDG_SESSION_DESKTOP,Hyprland"
          "XDG_SESSION_TYPE,wayland"
          "GDK_BACKEND,wayland,x11,*"
          "NIXOS_OZONE_WL,1"
          "MOZ_ENABLE_WAYLAND,1" # disable if You're having issues with firefox
          "SDL_VIDEODRIVER,wayland"
          "OZONE_PLATFORM,wayland"
          "CLUTTER_BACKEND,wayland"
          "QT_QPA_PLATFORM,wayland;xcb"
          "QT_WAYLAND_DISABLE_WINDOWDECORATION,1"
          "QT_QPA_PLATFORMTHEME,qt6ct"
          "QT_AUTO_SCREEN_SCALE_FACTOR,1"
          "WLR_RENDERER_ALLOW_SOFTWARE,1"
        ];
        windowrulev2 = [
          "suppressevent maximize, class:.*"
          "suppressevent minimize, class:.*"
          "opacity 0.0 override, class:^(xwaylandvideobridge)$"
          "noanim, class:^(xwaylandvideobridge)$"
          "noinitialfocus, class:^(xwaylandvideobridge)$"
          "maxsize 1 1, class:^(xwaylandvideobridge)$"
          "noblur, class:^(xwaylandvideobridge)$"
          # Firefox PIP
          "float,class:^(firefox)$,title:^(Picture-in-Picture)$"
          "pin,class:^(firefox)$,title:^(Picture-in-Picture)$"
          "float,class:^(firefox)$,title:^(Firefox — Sharing Indicator)$"
          # modals
          "float,title:^(Open)$"
          "float,title:^(Choose Files)$"
          "float,title:^(Save As)$"
          "float,class:^(google-chrome)$,title:^(Open Files)$"
          "float,class:^(google-chrome)$,title:^(Open File)$"
          "float,class:^(xdg-desktop-portal-gtk)$"
          "stayfocused, title:Quick Access — 1Password"
          "stayfocused, class:polkit-gnome-authentication-agent-1"
        ];
        windowrule = [
          # pavucontrol
          "float,pavucontrol"
          "size 1280 720, pavucontrol"
        ];
        workspace = [
          "3, monitor:desc:LG Electronics LG SDQHD 302NTCZF0715, default=true, defaultname=comms"
          "1, monitor:desc:HP Inc. HP X27q 6CM1210654, default=true, defaultname=term"
          "2, monitor:desc:BOE NE135A1M-NY1, default=true,defaultname=browse"
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
    programs = {
      waybar = {
        enable = true;
        style = ''
                * {
              font-family: FontAwesome,"CasckaydiaCove NF",sans-serif,monospace;
          }

          #window {
              padding: 0 2px;
          }

          window#waybar {
              border: none;
              border-radius: 0;
              box-shadow: none;
              text-shadow: none;
              transition-duration: 0s;
              color: @text;
              background: @crust; 
          } 

          #workspaces {
              margin: 0 5px;
          }

          #workspaces button.urgent {
              background-color: @red;
              color: white;
          }

          #tray,
          #mode,
          #battery,
          #temperature,
          #cpu,
          #memory,
          #network,
          #wireplumber,
          #idle_inhibitor,
          #backlight {
              margin: 0px 0px 0px 6px;
              padding: 0 2px;
          }

          #clock {
              margin:     0px 6px 0px 6px;
          }

          #battery {
          	font-size: 18px;
          }
          #battery.warning {
              color: orange;
          }

          #battery.critical {
              color: red;
          }

          #battery.charging {
              color: rgba(217, 216, 216, 1);
          }


        '';
      };
      hyprlock = {
        enable = true;
        settings = {
          background = {
            monitor = "";
            color = "rgba(5,5,5,1.0)";
          };
          input-field = {
            monitor = "";
            fade_on_empty = false;
            rounding = "-1";
            placeholder_text = "Password";
            halign = "center";
            valign = "center";
          };
          label = [
            {
              monitor = "";
              position = "0, -300";
              text = "cmd[update:1000] date +\"%-I:%M%p\"";
              color = "rgba(200, 200, 200, 1.0)";
              halign = "right";
              valign = "bottom";
              font_size = "55";
              font_family = "Fira Semibold";
            }
          ];
        };
      };
    };
    services = {
      hypridle = {
        enable = true;
        settings = {
          general = {
            # avoid starting multiple hyprlock instances.
            lock_cmd = "pidof hyprlock || ${pkgs.hyprlock}/bin/hyprlock";
            # lock before suspend.
            before_sleep_cmd = "loginctl lock-session";
            # to avoid having to press a key twice to turn on the display.
            after_sleep_cmd = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
          };

          listener = [
            {
              # 5 minutes
              timeout = 300;
              # set monitor backlight to minimum, avoid 0 on OLED monitor.
              on-timeout = "${pkgs.brightnessctl}/bin/brightnessctl -s set 10";
              # monitor backlight restore.
              on-resume = "${pkgs.brightnessctl}/bin/brightnessctl -r";
            }
            {
              # 10 minutes
              timeout = 600;
              # lock screen when timeout has passed
              on-timeout = "loginctl lock-session";
            }
            {
              # 11 minutes
              timeout = 660;
              # screen off when timeout has passed
              on-timeout = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
              # screen on when activity is detected after timeout has fired.
              on-resume = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
            }
          ];
        };
      };
      swayosd.enable = true;
    };
  };
}
