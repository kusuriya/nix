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

  # Pi coding agent — overlay from lukasl-dev/pi.nix. Exposes
  # pkgs.pi-coding-agent (npm-built) and pkgs.pi-coding-agent-bun (Bun-built,
  # faster startup). See earendil-works/pi#2310 for the upstream packaging
  # request that would make this overlay unnecessary someday.
  pi-packages = final: _prev:
    import inputs.pi {
      inherit (final) system;
      pkgs = final;
    };
}
