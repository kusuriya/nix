{
  description = "https://github.com/kusuriya/nix";
  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://hyprland.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
    warn-dirty = false;
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
    max-jobs = "auto";

  };
  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    # You can access packages and modules from different nixpkgs revs
    # at the same time. Here's an working example:
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";
    # Also see the 'unstable-packages' overlay at 'overlays/default.nix'.

    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    hardware.url = "github:nixos/nixos-hardware";
    hyprland.url = "git+https://github.com/hyprwm/Hyprland?submodules=1";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };
    lanzaboote = {
      url = "github:nix-community/lanzaboote/v0.4.1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    catppuccin.url = "github:catppuccin/nix";
    flake-utils.url = "github:numtide/flake-utils";
    sops-nix = {
      url = "github:mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    zen-browser.url = "github:kusuriya/zen-browser-flake";
    nixvim = {
      url = "github:nix-community/nixvim";
      # If you are not running an unstable channel of nixpkgs, select the corresponding branch of nixvim.
      # url = "github:nix-community/nixvim/nixos-24.05";

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
    , catppuccin
    , nixvim
    , firefox
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
          specialArgs = { inherit inputs self; };
          modules = [
            # Base configuration
            ./hosts/${hostname}
            ({ pkgs, inputs, config, ... }:
              {
                config = {
                  environment.systemPackages = [
                    inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin
                  ];
                };
              })
            # Conditional home-manager setup
            (nixpkgs.lib.mkIf homeManagerConfig {
              home-manager = {
                extraSpecialArgs = { inherit inputs self; };
                users.kusuriya = { imports = [ ./home-manager/home.nix catppuccin.homeManagerModules.catppuccin nixvim.homeManagerModules.nixvim ]; };
                useGlobalPkgs = true;
                useUserPackages = true;
              };
            })
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
            inputs.catppuccin.nixosModules.catppuccin

          ];
        };
        work = mkSystem {
          hostname = "wusc063016";
          extraModules = [
            inputs.hardware.nixosModules.common-pc-ssd
            inputs.hardware.nixosModules.lenovo-thinkpad-t14
            inputs.catppuccin.nixosModules.catppuccin
          ];
        };
        pve = mkSystem {
          hostname = "pve";
          homeManagerConfig = false;
          extraModules = [ ];
        };
      };
    };
}
