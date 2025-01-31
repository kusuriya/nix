{ config, lib, pkgs, ... }:
{
  programs.hyprlock = {
    enable = true;
    settings = {
      general = {
        ignore_empty_input = true;
      };

      background = {
        path = "screenshot";
        blur_passes = 2;
        color = "rgba(5,5,5,1.0)";
        brightness = 0.2500;
      };
      input-field = {
        fade_on_empty = false;
        rounding = "25";
        placeholder_text = "Password";
        halign = "center";
        valign = "center";
        size = "15%,5%";
      };
    };
  };
}
