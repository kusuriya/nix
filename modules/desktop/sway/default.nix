{ pkgs
, lib
, ...
}:
{
  imports = [ ../gaming ./clipboard.nix ];

  environment.systemPackages = with pkgs; [
    hicolor-icon-theme
    adwaita-icon-theme
    adwaita-qt
    waybar
    grim
    sway-contrib.grimshot
    slurp
    wl-clipboard
    swaynotificationcenter
    sway
    networkmanagerapplet
    fuzzel
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
    kdePackages.kdeconnect-kde
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
  # Explicit services own these processes; Sway reloads must not spawn copies.
  # NixOS starts sway-session.target after importing the compositor environment.
  systemd.user.services = (lib.mapAttrs
    (name: command: {
      description = "Sway session: ${name}";
      wantedBy = [ "sway-session.target" ];
      partOf = [ "sway-session.target" ];
      after = [ "graphical-session-pre.target" ];
      unitConfig.ConditionEnvironment = "SWAYSOCK";
      # Waybar custom modules and applets invoke desktop helpers by name.
      environment.PATH = lib.mkForce "/run/wrappers/bin:/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin:/run/current-system/sw/bin";
      serviceConfig = {
        ExecStart = command;
        Restart = "on-failure";
        RestartSec = 3;
      };
    })
    {
      sway-kanshi = "${pkgs.kanshi}/bin/kanshi";
      sway-waybar = "${pkgs.waybar}/bin/waybar";
      sway-notifications = "${pkgs.swaynotificationcenter}/bin/swaync";
      sway-polkit = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
      sway-network-applet = "${pkgs.networkmanagerapplet}/bin/nm-applet --indicator";
      sway-bluetooth-applet = "${pkgs.blueman}/bin/blueman-applet";
      sway-kdeconnect = "${pkgs.kdePackages.kdeconnect-kde}/bin/kdeconnect-indicator";
    }) // {
    # Daily flake update check — sends a swaync notification when updates exist
    nixos-update-check = {
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
