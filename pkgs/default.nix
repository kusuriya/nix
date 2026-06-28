{ pkgs, ... }: {
  glowing-bear-electron = pkgs.callPackage ./glowing-bear-electron.nix { };
  labelrange-rd560 = pkgs.callPackage ./rd560/labelrange-rd560.nix { };
  hermes-desktop = pkgs.callPackage ./hermes-desktop { };
  sway-session = pkgs.callPackage ./sway-session { };
  url-dispatcher = pkgs.callPackage ./url-dispatcher { };
}
