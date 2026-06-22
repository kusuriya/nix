# Hardware configuration for beast — manually maintained.
# Disk mounts are managed by disko (see ./disko.nix).
{ lib, modulesPath, ... }:

{
  imports = [
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
      kernelModules = [ ];
    };
    # AMD CPU — KVM for virtualization (libvirtd retained for non-passthrough VMs)
    kernelModules = [ "kvm-amd" ];
    extraModprobeConfig = ''
      options kvm-amd nested=1
    '';
    kernelParams = [
      "quiet"
    ];
  };
  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware = {
    cpu.amd.updateMicrocode = lib.mkDefault true;
  };
}