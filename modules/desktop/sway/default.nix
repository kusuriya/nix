{ pkgs
, ...
}:
{
  environment.systemPackages = with pkgs; [
    waybar
    grim
    sway-contrib.grimshot
    slurp
    wl-clipboard
    mako
    sway
    networkmanagerapplet
    wofi
    swaybg
    kanshi
    swayidle
    pavucontrol
    brightnessctl
    swaylock
    ghostty
    playerctl
    xarchiver
  ];
  services = {
    gnome.gnome-keyring.enable = true;
    blueman.enable = true;
    greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "${pkgs.sway}/bin/sway";
          user = "kusuriya";
        };
        default_session = initial_session;
      };
    };
  };
  programs = {
    sway = {
      enable = true;
      wrapperFeatures.gtk = true;
      xwayland.enable = true;
    };
    thunar = {
      enable = true;
      plugins = with pkgs.xfce; [
        thunar-archive-plugin
        thunar-media-tags-plugin
        thunar-volman
      ];
    };
  };
  # GVFS for Thunar volume management, trash, and MTP device support
  services.gvfs.enable = true;
}