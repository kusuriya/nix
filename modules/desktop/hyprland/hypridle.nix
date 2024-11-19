{config, lib, ...}:
{
services.hypridle = {
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
}
