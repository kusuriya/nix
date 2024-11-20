{ config, lib, pkgs, ... }:
{
  programs. hyprlock = {
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
          text = "cmd[update:1000] date";
          color = "rgba(200, 200, 200, 1.0)";
          halign = "right";
          valign = "bottom";
          font_size = "55";
        }
      ];
    };
  };
}
