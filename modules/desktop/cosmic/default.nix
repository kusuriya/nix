{ config
, pkgs
, inputs
, lib
, osConfig
, ...
}:
{
  services = {
    desktopManager.cosmic.enable = true;
    displayManager = {
      cosmic-greeter.enable = true;
    };
  };
}
