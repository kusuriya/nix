# Custom packages, that can be defined similarly to ones from nixpkgs
# You can build them using 'nix build .#example'
pkgs: {
  hermes-desktop = pkgs.callPackage ./hermes-desktop.nix { };
}
