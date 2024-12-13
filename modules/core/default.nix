{ pkgs, lib, config, ... }:
{
  imports = [
    ./kusuriya.nix
    ./oom.nix
    ./home-manager.nix
    ./fonts.nix
    ./containers.nix
  ];
  programs = {
    steam = {
      enable = true;
      extraCompatPackages = [ pkgs.proton-ge-bin ];
      fontPackages = [ pkgs.source-han-sans ];
      gamescopeSession.enable = true;
      localNetworkGameTransfers.openFirewall = true;

    };
    seahorse.enable = true;
    nix-ld = {
      enable = true;
    };
    corectrl = {
      enable = true;
    };
    _1password-gui = {
      enable = true;
      polkitPolicyOwners = [ "kusuriya" ];
    };
    dconf.enable = true;
  };

}
