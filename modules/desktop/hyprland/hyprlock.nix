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
    };
  };
}
