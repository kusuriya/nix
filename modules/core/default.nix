{ pkgs, lib, config, ... }:
{
  imports = [
    ./kusuriya.nix
    ./oom.nix
    ./home-manager.nix
    ./fonts.nix
    ./containers.nix
    ./polkit.nix
    ./packages.nix
    ./nix.nix
    ./locale.nix
  ];
  nix = {
    settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
      ];
      trusted-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
      auto-optimise-store = true;
    };
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="534d", ATTRS{idProduct}=="2109", TAG+="kusuriya"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="534d", ATTRS{idProduct}=="2109", TAG+="kusuriya"
    SUBSYSTEM=="ttyUSB", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", TAG+="kusuriya"
  '';
}