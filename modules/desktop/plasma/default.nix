{ lib
, pkgs
, ...
}:
{
  imports = [ ../gaming ];

  # Plasma's upstream module supplies KDE applications, KWallet/PAM, Polkit,
  # XWayland, Qt integration and the KDE screen-sharing/file-picker portals.
  services.desktopManager.plasma6.enable = lib.mkDefault true;
  services.displayManager.sddm = {
    enable = lib.mkDefault true;
    wayland.enable = lib.mkDefault true;
  };
  services.displayManager.defaultSession = lib.mkDefault "plasma";

  # These defaults make an otherwise minimal host usable, without choosing
  # interfaces, credentials, a user account, or hardware-specific GPU drivers.
  networking.networkmanager.enable = lib.mkDefault true;
  hardware.bluetooth.enable = lib.mkDefault true;
  security.rtkit.enable = lib.mkDefault true;
  services.pulseaudio.enable = lib.mkDefault false;
  services.pipewire = {
    enable = lib.mkDefault true;
    alsa = {
      enable = lib.mkDefault true;
      support32Bit = lib.mkDefault true;
    };
    pulse.enable = lib.mkDefault true;
    wireplumber.enable = lib.mkDefault true;
  };

  # Install phone integration without implicitly opening its LAN ports.
  # Hosts can opt in to the upstream firewall-enabled KDE Connect module.
  environment.systemPackages = [ pkgs.kdePackages.kdeconnect-kde ];
}
