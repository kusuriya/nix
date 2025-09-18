{ config, lib, pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_latest; # pkgs.linuxPackages_latest; lock the kernel to 6.12 until the nix issue with 6.13 is fixed
}

