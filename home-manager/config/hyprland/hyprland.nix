{config, pkgs, inputs, lib, osConfig,...}:
{
  wayland.windowManager.hyprland = {
    enable = true;
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
        "desc:HP Inc. HP X27q 6CM1210654,preferred,0x0,1"
	"desc:BOE NE135A1M-NY1,preferred,auto-right,2.0"
        "desc:LG Electronics LG SDQHD 302NTCZF0715,preferred,auto-left,1.25"
        ",preferred,auto,auto"
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
       "Thunar --daemon"
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
        border_size = 1;
        "col.active_border" = "rgba(7aa2f7aa)";
        "col.inactive_border" = "rgba(414868aa)";
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
      animations = { enabled = false; };
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
        mouse_move_enables_dpms = true;
        key_press_enables_dpms = false;
	vrr = 1;
	allow_session_lock_restore = true;
      };
      group = {
        drag_into_group = 2;
        groupbar = {
	  enabled = true;
	  font_size = 12;
	  height = 24;
	  "col.active" = "rgba(7aa2f7aa)";
	  "col.inactive" = "rgba(414868aa)";
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
        "$mainMod, V, exec, cliphist list|wofi --dmenu|cliphist decode|wl-copy"
        "$mainMod Control, S, exec, hyprshot --clipboard-only -m region -z"
        "$mainMod, S, togglespecialworkspace, magic"
        "$mainMod SHIFT, S, movetoworkspace, special:magic"
        "$mainMod ALT, RIGHT, movecurrentworkspacetomonitor, -1"
        "$mainMod ALT, LEFT, movecurrentworkspacetomonitor, +1"
	"$mainMod SHIFT, RIGHT, workspace, m-1"
	"$mainMod SHIFT, LEFT, workspace, m+1"
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
       ",XF86AudioPlay, exec, playerctl play-pause"
       ",XF86AudioNext, exec, playerctl next"
       ",XF86AudioPrev, exec, playerctl previous"
       ",XF86MonBrightnessUp, exec, brightnessctl s 5%+"
       ",XF86MonBrightnessDown, exec, brightnessctl s 5%-"
      ];
      env = [ 
        "XCURSOR_SIZE,32"
        "HYPRCURSOR_SIZE,32"
        "GDK_SCALE,2"
        "MOZ_ENABLE_WAYLAND,1"
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
	      ];
      windowrule = [
	# pavucontrol
	"float,pavucontrol"
	"size 1280 720, pavucontrol"
      ];
    };
  };
}
