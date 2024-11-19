{lib, pkgs, config, ... }:
{
systemd.services.flake-update = {
    description = "Update Nix Flakes";
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.writeShellScript "update-flakes" ''
        cd /etc/nixos  # or your flake directory
        ${pkgs.nix}/bin/nix flake update
      ''}";
      User = "root";
    };
  };

  systemd.timers.flake-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";  # or weekly, monthly, etc.
      Persistent = true;
      RandomizedDelaySec = "1h";
    };
  };
}
