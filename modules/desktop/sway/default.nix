{ pkgs
, lib
, ...
}:
{
  environment.systemPackages = with pkgs; [
    hicolor-icon-theme
    gnome-icon-theme
    adwaita-icon-theme
    adwaita-qt
    url-dispatcher
    waybar
    grim
    sway-contrib.grimshot
    slurp
    wl-clipboard
    swaynotificationcenter
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
    polkit_gnome
    xarchiver
  ];
  services = {
    gnome.gnome-keyring.enable = true;
    blueman.enable = true;
    greetd = {
      enable = true;
      settings = rec {
        initial_session = {
          command = "${lib.getExe pkgs.sway-session}";
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
      plugins = with pkgs; [
        thunar-archive-plugin
        thunar-media-tags-plugin
        thunar-volman
      ];
    };
  };
  # GVFS for Thunar volume management, trash, and MTP device support
  services.gvfs.enable = true;

  # Daily flake update check — sends a swaync notification when updates exist
  systemd.user.services.nixos-update-check = {
    description = "Check for NixOS flake updates";
    serviceConfig = {
      Type = "oneshot";
    };
    script = ''
      cd /home/kusuriya/nix
      OUTPUT=$(${lib.getExe pkgs.nix} flake update --dry-run 2>&1)
      if echo "$OUTPUT" | ${pkgs.gnugrep}/bin/grep -q "updating"; then
        COUNT=$(echo "$OUTPUT" | ${pkgs.gnugrep}/bin/grep "updating" | ${pkgs.coreutils}/bin/wc -l)
        ${pkgs.libnotify}/bin/notify-send "NixOS: $COUNT flake updates available" "Run 'just update && just switch' to apply"
      fi
    '';
  };

  systemd.user.timers.nixos-update-check = {
    description = "Daily NixOS flake update check";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "daily";
      Persistent = true;
    };
  };
}
