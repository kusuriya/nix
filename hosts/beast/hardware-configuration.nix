{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot = {
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "ahci"
        "usbhid"
        "uas"
        "sd_mod"
      ];
      kernelModules = [
      ];
    };
    kernelModules = [ "kvm-amd" "kvmfr" ];
    extraModulePackages = with config.boot.kernelPackages; [ kvmfr ];
    extraModprobeConfig = ''
      options kvm-amd nested=1
    '';
    kernelParams = [
      "amd_iommu=on" # Since you have AMD CPU
      "iommu=pt"
    ];
  };
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/8e9d6da6-f89c-4ea7-b2bc-115ec941996f";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/1BF9-63A0";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
