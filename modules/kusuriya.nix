{ lib, config, pkgs, ... }:
{
  programs.fish.enable = true;
  users.users.kusuriya = {
    isNormalUser = true;
    description = "kusuriya";
    extraGroups = [
      "cdrom"
      "networkmanager"
      "wheel"
      "dialout"
      "audio"
      "video"
      "system"
      "libvirtd"
      "kvm"
      "render"
    ];
    shell = pkgs.fish;
  };
}
