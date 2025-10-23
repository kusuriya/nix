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

  ];
  services = {
    gnome.gnome-keyring.enable = true;
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
    light.enable = true;

  };
  security.polkit.enable = true;
  fonts = {
    packages = with pkgs; [
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-emoji
      font-awesome
      source-han-sans
      source-han-sans-japanese
      source-han-serif-japanese
    ];
    fontconfig.defaultFonts = {
      serif = [ "Noto Serif" "Source Han Serif" ];
      sansSerif = [ "Noto Sans" "Source Han Sans" ];
    };
  };
}
