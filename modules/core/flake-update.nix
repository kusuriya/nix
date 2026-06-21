{ lib, pkgs, config, ... }:
{
  systemd.services.flake-update = {
    description = "Update Nix Flakes";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "update-flakes" ''
        FLAKE_DIR="''${FLAKE_DIR:-/etc/nixos}"
        cd "$FLAKE_DIR"
        ${pkgs.nix}/bin/nix flake update
      ''}";
      User = "root";
    };
  };

  systemd.timers.flake-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      # Weekly to avoid overlapping with autoUpgrade schedules.
      # autoUpgrade also updates nixpkgs input; running both daily causes races.
      OnCalendar = "weekly";
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
