{ pkgs, ... }:
{
  # --- btrbk: automated btrfs snapshot management ---
  services.btrbk = {
    extraPackages = [ pkgs.mbuffer ];
    instances = {
      "desktop-snapshots" = {
        onCalendar = "hourly";
        settings = {
          timestamp_format = "long";
          snapshot_preserve_min = "2d";
          snapshot_preserve = "48h 14d 8w 6m";
          snapshot_dir = "/.snapshots";
          subvolume = {
            "/" = { };
            "/home" = { };
          };
        };
      };
    };
  };

  # --- btrfs autoScrub ---
  services.btrfs.autoScrub = {
    enable = true;
    interval = "monthly";
    fileSystems = [ "/" "/home" ];
  };
}
