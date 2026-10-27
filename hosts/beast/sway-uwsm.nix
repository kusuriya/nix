{ config
, lib
, pkgs
, ...
}:
let
  uwsm = lib.getExe pkgs.uwsm;
  sessionServices = [
    "sway-kanshi"
    "sway-waybar"
    "sway-notifications"
    "sway-polkit"
    "sway-network-applet"
    "sway-bluetooth-applet"
    "sway-kdeconnect"
  ];
  launcher = pkgs.writeShellScriptBin "sway-uwsm-launcher" ''
    if [ "''${1:-drun}" = run ]; then
      selection=$(${pkgs.wofi}/bin/wofi --show run --define=run-print_command=true) || exit 0
      [ -n "$selection" ] || exit 0
      exec ${uwsm} app -- ${pkgs.runtimeShell} -c "$selection"
    fi
    selection=$(${pkgs.wofi}/bin/wofi --show drun --define=drun-print_desktop_file=true) || exit 0
    [ -n "$selection" ] || exit 0
    case "$selection" in
      *'.desktop '*) selection="''${selection%.desktop *}.desktop:''${selection#*.desktop }" ;;
    esac
    exec ${uwsm} app -- "$selection"
  '';
  swayConfig = builtins.replaceStrings
    [
      "set $term ghostty"
      "set $menu wofi --show \"drun,run,dmenu\""
      "'swaymsg exit'"
    ]
    [
      "set $term ${uwsm} app -- ghostty"
      "set $menu ${launcher}/bin/sway-uwsm-launcher\nbindsym $mod+Ctrl+space exec ${launcher}/bin/sway-uwsm-launcher run"
      "'${uwsm} stop'"
    ]
    (builtins.readFile ../../home-manager/dotfiles/sway/config);
  startupConfig = builtins.replaceStrings
    [ "exec " ]
    [ "exec ${uwsm} app -- " ]
    (builtins.readFile ../../home-manager/dotfiles/sway/config.d/exec.conf);
in
{
  # Beast-only migration. Framey retains the existing Sway session owner.
  programs.uwsm = {
    enable = true;
    waylandCompositors.sway = {
      prettyName = "Sway";
      comment = "Sway managed by UWSM";
      binPath = "/run/current-system/sw/bin/sway";
    };
  };
  # UWSM owns the login bus/session; do not nest Sway's dbus-run-session wrapper.
  programs.sway.wrapperFeatures.base = lib.mkForce false;
  services.greetd.settings = {
    initial_session.command = lib.mkForce "${uwsm} start -D sway -F -- /run/current-system/sw/bin/sway";
    default_session.command = lib.mkForce "${uwsm} start -D sway -F -- /run/current-system/sw/bin/sway";
  };

  # Replace the upstream Sway target/start/stop glue, retaining the include in
  # the user config. Finalization exports SWAYSOCK before desktop services start.
  environment.etc."sway/config.d/nixos.conf".source = lib.mkForce
    (pkgs.writeText "sway-uwsm.conf" ''
      exec ${uwsm} finalize SWAYSOCK I3SOCK XCURSOR_SIZE XCURSOR_THEME
    '');

  systemd.user.services = lib.genAttrs sessionServices (_: {
    wantedBy = lib.mkForce [ "graphical-session.target" ];
    partOf = lib.mkForce [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
  });

  home-manager.users.kusuriya = {
    home.file = {
      ".config/sway/config".source = lib.mkForce (pkgs.writeText "sway-uwsm-config" swayConfig);
      ".config/sway/config.d/exec.conf".source = lib.mkForce
        (pkgs.writeText "sway-uwsm-startup.conf" startupConfig);
    };
    # Explicit supervised services own these applets, not XDG autostart.
    # Other user autostarts (Bitwarden, Remmina, Azeron) remain enabled.
    xdg.configFile = lib.genAttrs
      [ "autostart/blueman.desktop" "autostart/nm-applet.desktop" "autostart/polkit-gnome-authentication-agent-1.desktop" ]
      (_: {
        text = ''
          [Desktop Entry]
          Type=Application
          Hidden=true
        '';
      });
  };

  assertions = [{
    assertion = config.programs.sway.enable && !config.programs.sway.wrapperFeatures.base;
    message = "Beast UWSM requires Sway without the nested base session wrapper.";
  }];
}
