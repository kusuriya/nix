{ pkgs, ... }: {
  glowing-bear-electron = pkgs.callPackage ./glowing-bear-electron.nix { };
  labelrange-rd560 = pkgs.callPackage ./rd560/labelrange-rd560.nix { };
  hermes-desktop = pkgs.callPackage ./hermes-desktop { };
  orca-slicer-appimage = pkgs.callPackage ./orca-slicer-appimage { };
  sway-session = pkgs.callPackage ./sway-session { };
}
