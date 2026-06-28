{
  description = "https://github.com/kusuriya/nix";
  # These settings apply to the Nix CLI when running commands against this
  # flake directly (e.g. `nix build .#`). The NixOS system daemon settings
  # are in modules/core/nix.nix — both are needed, they configure different
  # things.
  nixConfig = {
    warn-dirty = false;
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = "auto";
  };
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable"; # Default channel — daily rebuilds, accessed via `pkgs`
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11"; # Pinned stable — libvirt/qemu live here, accessed via `pkgs-stable`
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master"; # Bleeding edge — accessed via `pkgs.unstable` overlay
    disko.url = "github:nix-community/disko"; # Declarative disk partitioning (btrfs)
    disko.inputs.nixpkgs.follows = "nixpkgs";

    home-manager = {
      url = "github:nix-community/home-manager/master"; # User-level dotfiles and configs
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hardware.url = "github:nixos/nixos-hardware"; # Hardware-specific profiles (Framework, common-*)
    lanzaboote = {
      url = "github:nix-community/lanzaboote/"; # Secure Boot (framey only)
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox = {
      url = "github:nix-community/flake-firefox-nightly"; # Firefox Nightly (desktop hosts)
    };
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , ...
    }@inputs:
    let
      # Supported systems for your flake packages, shell, etc.
      systems = [
        "x86_64-linux"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      # Helper function to create system configurations
      mkSystem = { hostname, system ? "x86_64-linux", extraModules ? [ ], homeManagerConfig ? true }:
        nixpkgs.lib.nixosSystem {
          nixpkgs.hostPlatform.system = system;
          specialArgs = {
            inherit inputs self;
            pkgs-stable = nixpkgs-stable.legacyPackages.${system};
          };
          modules = [
            {
              nixpkgs.overlays = [
                (final: _: {
                  libvirt = nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.libvirt;
                  qemu = nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.qemu;
                  qemu_kvm = nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.qemu_kvm;
                  virt-manager = nixpkgs-stable.legacyPackages.${final.stdenv.hostPlatform.system}.virt-manager;
                })
              ];
            }
            # Base configuration
            ./hosts/${hostname}
            # Conditional home-manager setup
            (nixpkgs.lib.mkIf homeManagerConfig {
              home-manager = {
                extraSpecialArgs = { inherit inputs self; };
                users.kusuriya = { imports = [ ./home-manager/home.nix ]; };
              };
            })
          ] ++ extraModules;
        };
    in
    {
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShellNoCC {
          packages = with nixpkgs.legacyPackages.${system}; [
            nixpkgs-fmt
            deadnix
            treefmt
            nix-output-monitor
          ];
        };
      });

      overlays = import ./overlays { inherit inputs; };
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake https://github.com/kusuriya/nix/#hostname'
      nixosConfigurations = {
        # Desktop configuration (VFIO passthrough rig, Sway + gaming)
        beast = mkSystem {
          hostname = "beast";
          extraModules = [
            inputs.hardware.nixosModules.common-cpu-amd
            inputs.hardware.nixosModules.common-gpu-nvidia
            inputs.hardware.nixosModules.common-pc-ssd
          ];
        };

        # Laptop (Framework 13 AMD, LUKS2 + Secure Boot + TPM2)
        framey = mkSystem {
          hostname = "framey";
          extraModules = [
            inputs.hardware.nixosModules.framework-13-7040-amd
            inputs.hardware.nixosModules.common-pc-ssd
            inputs.lanzaboote.nixosModules.lanzaboote
          ];
        };

        # Home server (Proxmox host, ZFS, containers, no home-manager)
        pve = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs self; };
          modules = [ ./hosts/pve ];
        };
      };
    };
}
