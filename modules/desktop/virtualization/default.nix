{ config, pkgs, ... }:
{
  # --- libvirtd (non-passthrough VMs) ---
  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_full;
        runAsRoot = true;
        swtpm.enable = true;
      };
    };
    spiceUSBRedirection.enable = true;
  };

  # OVMF firmware paths for libvirtd/virt-manager VMs
  environment.etc."ovmf/edk2-x86_64-secure-code.fd" = {
    source = "${config.virtualisation.libvirtd.qemu.package}/share/qemu/edk2-x86_64-secure-code.fd";
  };
  environment.etc."ovmf/edk2-i386-vars.fd" = {
    source = "${config.virtualisation.libvirtd.qemu.package}/share/qemu/edk2-i386-vars.fd";
    mode = "0644";
    user = "libvirtd";
  };
}
