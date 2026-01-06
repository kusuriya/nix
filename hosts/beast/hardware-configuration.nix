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
      "quiet"
      "amd_iommu=on" # Since you have AMD CPU
      "iommu=pt"
    ];
  };
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/50565520-b705-43ac-9623-694f06e62510";
      fsType = "btrfs";
      options = [ "subvol=@" ];
    };

  fileSystems."/home" =
    { device = "/dev/disk/by-uuid/50565520-b705-43ac-9623-694f06e62510";
      fsType = "btrfs";
      options = [ "subvol=@home" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/30AB-C111";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
