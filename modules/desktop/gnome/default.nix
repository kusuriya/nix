{ config
, pkgs
, inputs
, lib
, osConfig
, ...
}:
{
  services = {
    displayManager =
      {
        gdm = {
          enable = true;
        };
      };
    desktopManager.gnome.enable = true;
  };
  programs = {
    dconf.enable = true;
  };
  environment.systemPackages = with pkgs; [
    gnomeExtensions.appindicator
  ];
  programs.dconf.profiles.user.databases = [
    {
      settings = {
        "org/gnome/mutter" = {
          experimental-features = [
            "scale-monitor-framebuffer" # Enables fractional scaling (125% 150% 175%)
            "variable-refresh-rate" # Enables Variable Refresh Rate (VRR) on compatible displays
            "xwayland-native-scaling" # Scales Xwayland applications to look crisp on HiDPI screens
          ];
        };
      };
    }
  ];
}
