{ config, lib, pkgs, modulesPath, inputs, outputs, self, ... }:

{
  imports =
    [
      # Include the results of the hardware scan.
      (modulesPath + "/installer/scan/not-detected.nix")
      ./samba.nix
      ../../roles/mediaserver
      ../../roles/lightning
      ../../roles/paperlessngx
      ../../roles/ingress-controller
    ];
  nix =
    let
      flakeInputs = lib.filterAttrs
        (_: lib.isType "flake")
        inputs;
    in
    {
      settings = {
        experimental-features = "nix-command flakes";
        auto-optimise-store = true;
        allowed-users = [ "kusuriya" "root" ];
        trusted-users = [ "kusuriya" "root" ];
        nix-path = config.nix.nixPath;
        max-jobs = "auto";
        cores = 0; # Use all cores
      };
      registry = lib.mapAttrs (_: flake: { inherit flake; }) flakeInputs;
      nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
      gc = {
        automatic = true;
        dates = "weekly";
        # Keep the last week
        options = "--delete-older-than 7d";
      };
    };
  system = {
    autoUpgrade = {
      enable = true;
      flake = inputs.self.outPath;
      flags = [
        "--cores 30"
        "--update-input"
        "nixpkgs"
        "-L"
      ];
      allowReboot = false;
      dates = "01:00";
      randomizedDelaySec = "45min";
      rebootWindow.lower = "00:01";
      rebootWindow.upper = "05:00";
      persistent = true;
    };
  };

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = {
    btrfs = true;
    zfs = lib.mkForce true;
  };

  networking = {
    hostName = "pve"; # Define your hostname.
    hostId = "06904201";
    firewall = {
      enable = false;
      allowedTCPPorts = [ 80 443 81 82 8080 ];
    };
    nat = {
      enable = true;
      internalInterfaces = [ "ve-+" ];
      externalInterface = "eno2";
      enableIPv6 = true;
    };
    bridges = {
      br0 = {
        interfaces = [ "eno2" ];
      };
    };
    interfaces = {
      "br0" = {
        useDHCP = true;
      };
    };
  };
  users.users.kusuriya = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };
  environment.systemPackages = with pkgs; [
    vim
    wget
    zfs
    git
  ];
  services = {
    openssh = {
      enable = true;
      openFirewall = true;
    };
    zfs.autoScrub.enable = true;
  };
  system.stateVersion = "24.05"; # Did you read the comment?

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "ehci_pci" "mpt3sas" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.zfs = {
    extraPools = [ "dozer-files" ];
  };

  fileSystems."/" =
    {
      device = "/dev/disk/by-uuid/8a41f25b-dcb0-45da-9446-937546ba815f";
      fsType = "btrfs";
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/5177-1046";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault
    config.hardware.enableRedistributableFirmware;
}
