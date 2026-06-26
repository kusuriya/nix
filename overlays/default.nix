# This file defines overlays
{ inputs, ... }: {
  # Brings custom packages from the 'pkgs' directory
  additions = final: _prev: {
    hermes-desktop = final.callPackage ../pkgs/hermes-desktop.nix { };
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };
}