{ config
, lib
, modulesPath
, ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];
  boot = {
    loader.timeout = 0;
    kernelParams = [
      "quiet"
      "splash"
      "amd_pstate=active"
      "nvme.noacpi=1"
      "page_alloc.shuffle=1"
      "randomize_kstack_offset=on"
    ];
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usbhid"
      ];
      kernelModules = [
        "v4l2loopback"
        "amdgpu"
      ];
      luks.devices."luks-b0bd2e7d-bb44-4105-a3b9-5d2b5e87065c".device = "/dev/disk/by-uuid/b0bd2e7d-bb44-4105-a3b9-5d2b5e87065c";
    };
    resumeDevice = "/dev/dm-0";
    kernelModules = [ "kvm-amd" ];
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
    '';
  };
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/173373b2-9db9-4890-993a-9c57c5340f75";
    fsType = "ext4";
  };
  fileSystems."/boot" = {
    device = "/dev/disk/by-uuid/750A-3B24";
    fsType = "vfat";
  };
  swapDevices = [
    {
      device = "/swapfile";
      size = 128 * 1024; # 128GB
    }
  ];
  networking.networkmanager.enable = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';
}