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
    kernelModules = [ "kvm-amd" "kvmfr" ];
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback kvmfr ];
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
        device = "/dev/disk/by-uuid/36d05ddc-0479-4168-a2dc-bddfeda7ff1c";
        fsType = "btrfs";
        options = [ "subvol=@" ];
      };

    "/boot" =
      {
        device = "/dev/disk/by-uuid/91B4-ECA3";
        fsType = "vfat";
        options = [ "fmask=0077" "dmask=0077" ];
      };
    "/virt" =
      {
        device = "/dev/disk/by-id/nvme-SHPP41-1000GM_AJD1N59571050210X";
        fsType = "bcachefs";
      };
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  };
}
