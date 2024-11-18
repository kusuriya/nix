{ config
, lib
, modulesPath
, ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    ./disko.nix
  ]
  boot = {
    loader.timeout = 0;
    kernelParams = [
      "quiet"
      "splash"
    ];
    initrd = {
      availableKernelModules = [
        "nvme"
        "xhci_pci"
        "thunderbolt"
        "usbhid"
      ];
      systemd.enable = true;
      kernelModules = [
        "v4l2loopback"
      ];
    };
    resumeDevice = "/dev/dm-0";
    kernelModules = [ "intel-amd" ];
    extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];
    extraModprobeConfig = ''
      options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
    '';
  };
  swapDevices = [
    {
      device = "/swapfile";
      size = 128 * 1024; # 128GB
    }
  ];
  networking.networkmanager.enable = true;
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
  systemd.sleep.extraConfig = ''
    HibernateDelaySec=30m
    SuspendState=mem
  '';
}
