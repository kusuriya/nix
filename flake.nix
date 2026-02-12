{
  description = "https://github.com/kusuriya/nix";
  nixConfig = {
    warn-dirty = false;
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = "auto";
  };
  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/master";
    nixos-cosmic.url = "github:lilyinstarlight/nixos-cosmic";

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hardware.url = "github:nixos/nixos-hardware";
    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/"; #v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    firefox = {
      url = "github:nix-community/flake-firefox-nightly";
    };
  };

  outputs =
    { self
    , nixpkgs
    , home-manager
    , hardware
    , hyprland
    , lanzaboote
    , firefox
    , nixos-cosmic
    , nixpkgs-stable
    , nixpkgs-unstable
    , ...
    }@inputs:
    let
      inherit (self) outputs;
      # Supported systems for your flake packages, shell, etc.
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
      # Helper function to create system configurations
      mkSystem = { hostname, system ? "x86_64-linux", extraModules ? [ ], homeManagerConfig ? true }:
        nixpkgs.lib.nixosSystem {
          inherit system;
          specialArgs = {
            inherit inputs self;
            pkgs-stable = nixpkgs-stable.legacyPackages.x86_64-linux;

          };
          modules = [
            {
              disko.nixosModules.disko
              ./hosts/${hostname}/disko.nix
              nixpkgs.overlays = [
                (final: prev: {
                  libvirt = nixpkgs-stable.legacyPackages.${final.system}.libvirt;
                  qemu = nixpkgs-stable.legacyPackages.${final.system}.qemu;
                  qemu_kvm = nixpkgs-stable.legacyPackages.${final.system}.qemu_kvm;
                  virt-manager = nixpkgs-stable.legacyPackages.${final.system}.virt-manager;
                })
              ];
            }
            # Base configuration
            ./hosts/${hostname}
            nixos-cosmic.nixosModules.default
            # Conditional home-manager setup
            (nixpkgs.lib.mkIf homeManagerConfig {
              home-manager = {
                extraSpecialArgs = { inherit inputs self; };
                users.kusuriya = { imports = [ ./home-manager/home.nix ./modules/home-manager ]; };
              };
            })
            {
              nix.settings = {
                substituters = [ "https://cosmic.cachix.org/" ];
                trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
              };
            }
          ] ++ extraModules;
        };
    in
    {
      packages = forAllSystems (system: import ./pkgs nixpkgs.legacyPackages.${system});
      formatter = forAllSystems (system: nixpkgs.legacyPackages.${system}.nixpkgs-fmt);

      overlays = import ./overlays { inherit inputs; };
      nixosModules = import ./modules/nixos;
      homeManagerModules = import ./modules/home-manager;
      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake https://github.com/kusuriya/nix/#hostname'
      nixosConfigurations = {
        # Desktop configuration
        beast = mkSystem {
          hostname = "beast";
          extraModules = [
            inputs.hardware.nixosModules.common-cpu-amd
            inputs.hardware.nixosModules.common-gpu-intel
            inputs.hardware.nixosModules.common-pc-ssd
          ];
        };

        # Laptop configuration
        # Framework 13
        # AMD Ryzen 7 7040
        # 32
        framey = mkSystem {
          hostname = "framey";
          extraModules = [
            inputs.hardware.nixosModules.framework-13-7040-amd
            inputs.hardware.nixosModules.common-pc-ssd
            inputs.lanzaboote.nixosModules.lanzaboote

          ];
        };
        work = mkSystem {
          hostname = "wusc063016";
          extraModules = [
            inputs.hardware.nixosModules.common-pc-ssd
            inputs.hardware.nixosModules.lenovo-thinkpad-t14
          ];
        };
        pve = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit inputs self; };
          modules = [ ./hosts/pve ];
        };
      };
    };
}
