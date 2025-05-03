{ config
, pkgs
, inputs
, lib
, osConfig
, ...
}:
{
  services = {
    displayManager =
      {
        sddm = {
          enable = true;
          wayland.enable = true;
        };
      };
    desktopManager.plasma6.enable = true;
  };
  programs = {
    dconf.enable = true;
  };
  environment.systemPackages = with pkgs; [
  ];
}
