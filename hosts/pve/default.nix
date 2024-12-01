{ config, lib, pkgs, modulesPath, inputs, outputs, self, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      (modulesPath + "/installer/scan/not-detected.nix"
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFileSystems = {
    btrfs = true;
    zfs = lib.mkForce true;
  };
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking = {
    hostName = "pve"; # Define your hostname.
    hostId = "06904201";
};
services.zfs.autoScrub.enable = true;
users.users.kusuriya = {
  isNormalUser = true;
  extraGroups = [ "wheel" ];
};
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    zfs
    git
  ];
  services.openssh.enable = true;
  system.stateVersion = "24.05"; # Did you read the comment?

   boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "ehci_pci" "mpt3sas" "nvme" "usb_storage" "usbhid" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];
  boot.zfs = {
  extraPools = [ "dozer-files" ];
  };

  fileSystems."/" =
    { device = "/dev/disk/by-uuid/8a41f25b-dcb0-45da-9446-937546ba815f";
      fsType = "btrfs";
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/5177-1046";
      fsType = "vfat";
      options = [ "fmask=0022" "dmask=0022" ];
    };

  swapDevices = [ ];

  # Enables DHCP on each ethernet and wireless interface. In case of scripted networking
  # (the default) this is the recommended approach. When using systemd-networkd it's
  # still possible to use this option, but it's recommended to use it in conjunction
  # with explicit per-interface declarations with `networking.interfaces.<interface>.useDHCP`.
  networking.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno1.useDHCP = lib.mkDefault true;
  # networking.interfaces.eno2.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
