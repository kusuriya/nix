{ config
, pkgs
, inputs
, lib
, osConfig
, ...
}:
{
  services = {
    xserver.enable = true;
    services.displayManager =
      {
        sddm = {
          enable = true;
          wayland.enable = true;
        };
        defaultSession = "plasma";
      };
    desktopManager.plasma6.enable = true;
  };
  qt = {
    enable = true;
    platformTheme = "qtct";
    style = "kvantum";
  };
  programs = {
    dconf.enable = true;
  };
  environment.systemPackages = with pkgs; [
    libsForQt5.qt5ct
    libsForQt5.qtstyleplugin-kvantum
  ];
  xdg.configFile = {
    "Kvantum/ArcDark".source = "${pkgs.arc-kde-theme}/share/Kvantum/ArcDark";
    "Kvantum/kvantum.kvconfig".text = "[General]\ntheme=ArcDark";
  };
}
