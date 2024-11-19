{ inputs, outputs, ... }:
{
  imports = [
    # Import home-manager's NixOS module
    inputs.home-manager.nixosModules.home-manager
  ];

  home-manager = {
    extraSpecialArgs = {
      inherit inputs outputs;
    };
    users = {
      # Import your home-manager configuration
      kusuriya = import ../home-manager/home.nix;
    };
    backupFileExtension = "backup";
  };
  system.stateVersion = "23.05";
}
