# This file defines overlays
{ inputs, ... }: {
  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final.stdenv.hostPlatform) system;
      config.allowUnfree = true;
    };
  };

  # Custom packages defined in ./pkgs (hermes-desktop, glowing-bear-electron, etc.)
  custom-packages = final: _prev: import ../pkgs { pkgs = final; };
}
