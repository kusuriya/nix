{ config, lib, pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_lts;
}

