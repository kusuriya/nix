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
        "v4l2loopback"
      ];
    };
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
      options kvm-amd nested=1
    '';
    kernelParams = [
      "amd_iommu=on" # Since you have AMD CPU
      "iommu=pt"
    ];
  };
  fileSystems = {
    "/" =
      {
        device = "/dev/disk/by-uuid/46b5b039-153f-435f-ab9c-1585aee5f3d4";
        fsType = "btrfs";
        options = [ "subvol=@" ];
      };

    "/boot" =
      {
        device = "/dev/disk/by-uuid/EA86-9835";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
