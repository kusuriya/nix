{ self
  , config
  , lib
  , pkgs
  , ...
}:
{
  services = {
    jellyfin = {
      enable = true;
      openFirewall = true;
    };
    plex = {
      enable = true;
      openFirewall = true;
      accelerationDevices = [
      "/dev/dri/card0"
      "/dev/dri/card1"
      "/dev/dri/renderD128"
      ];
    };
  };
  environment.systemPackages = [
    pkgs.jellyfin
    pkgs.jellyfin-web
    pkgs.jellyfin-ffmpeg
  ];
}
