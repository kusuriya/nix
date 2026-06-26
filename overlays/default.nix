# This file defines overlays
{ inputs, ... }: {
  additions = final: _prev: {
    hermes-desktop-rs = final.callPackage ../pkgs/hermes-desktop-rs.nix { };
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