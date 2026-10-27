{ config
, inputs
, lib
, pkgs
, ...
}:
let
  package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default;
  noctalia = lib.getExe package;
  clipboard = lib.findFirst (p: lib.getName p == "sway-clipboard")
    (throw "Noctalia clipboard status requires the shared Sway clipboard helper")
    config.environment.systemPackages;
  clipboardStatus = pkgs.writeShellScript "noctalia-clipboard-status" ''
    previous=
    while true; do
      state=$(${clipboard}/bin/sway-clipboard status) || state=off
      if [ "$state" != "$previous" ]; then
        # Only write on state transitions, not on every poll. Use the public
        # IPC so the bar reflects the actual external capture service.
        if ${noctalia} msg config-set widget.clipboard-status.label "\"Clip: $state\"" >/dev/null 2>&1; then
          previous=$state
        fi
      fi
      ${pkgs.coreutils}/bin/sleep 2
    done
  '';
in
{
  # Beast-only trial: the compositor, launcher, clipboard privacy, wallpaper,
  # notifications and lock/idle policy keep their existing owners.
  system.build.noctalia-trial = pkgs.linkFarm "noctalia-trial" [
    { name = "bin"; path = "${package}/bin"; }
    { name = "config.toml"; path = config.home-manager.users.kusuriya.xdg.configFile."noctalia/config.toml".source; }
    { name = "clipboard-status"; path = clipboardStatus; }
    { name = "clipboard"; path = "${clipboard}/bin/sway-clipboard"; }
  ];
  nix.settings = {
    extra-substituters = [ "https://noctalia.cachix.org" ];
    extra-trusted-public-keys = [ "noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=" ];
  };
  environment.systemPackages = [ package ];
  systemd.user.services.sway-waybar.enable = lib.mkForce false;
  systemd.user.services.sway-network-applet.enable = lib.mkForce false;
  systemd.user.services.sway-bluetooth-applet.enable = lib.mkForce false;
  systemd.user.services.noctalia = {
    description = "Noctalia bar and control center";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "graphical-session.target" ];
    unitConfig.ConditionEnvironment = "SWAYSOCK";
    environment.PATH = lib.mkForce "/run/wrappers/bin:/etc/profiles/per-user/%u/bin:%h/.nix-profile/bin:/run/current-system/sw/bin";
    restartTriggers = [ config.home-manager.users.kusuriya.xdg.configFile."noctalia/config.toml".source ];
    serviceConfig = {
      ExecStart = noctalia;
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
  systemd.user.services.noctalia-clipboard-status = {
    description = "External clipboard capture status in Noctalia";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    after = [ "noctalia.service" ];
    unitConfig.ConditionEnvironment = "SWAYSOCK";
    serviceConfig = {
      ExecStart = clipboardStatus;
      Restart = "on-failure";
      RestartSec = 3;
    };
  };
  home-manager.users.kusuriya = {
    imports = [ inputs.noctalia.homeModules.default ];
    programs.noctalia = {
      enable = true;
      inherit package;
      systemd.enable = false; # NixOS unit above is the sole persistent owner.
      settings = {
        shell = {
          font_family = "JetBrainsMono Nerd Font";
          polkit_agent = false;
          clipboard_enabled = false;
          screen_time_enabled = false;
          telemetry_enabled = false;
          external_ip_enabled = false;
          setup_wizard_enabled = false;
          launch_apps_as_systemd_services = true;
        };
        theme = {
          mode = "dark";
          source = "builtin";
          builtin = "Catppuccin";
          templates = {
            enable_builtin_templates = false;
            enable_community_templates = false;
            builtin_ids = [ ];
            community_ids = [ ];
          };
        };
        wallpaper = {
          enabled = false;
          automation.enabled = false;
        };
        lockscreen.enabled = false;
        idle.behavior = {
          lock.enabled = false;
          screen-off.enabled = false;
          suspend.enabled = false;
        };
        notification.enable_daemon = false; # Retain swaync and Mod+N.
        weather.enabled = false;
        dock.enabled = false;
        bar.main = {
          enabled = true;
          position = "top";
          margin_ends = 0;
          thickness = 32;
          start = [ "workspaces" ];
          center = [ "clock" ];
          end = [ "media" "clipboard-status" "tray" "network" "bluetooth" "volume" "control-center" ];
        };
        widget.clipboard-status = {
          type = "custom_button";
          label = "Clip: off";
          tooltip = "Clipboard capture status. Left: history; right: pause/resume; middle: delete entry.";
          actions = {
            left = "exec ${clipboard}/bin/sway-clipboard pick";
            right = "exec ${clipboard}/bin/sway-clipboard pause";
            middle = "exec ${clipboard}/bin/sway-clipboard delete";
          };
        };
      };
    };
    home.file.".config/sway/config.d/noctalia.conf".text = ''
      bindsym $mod+Ctrl+n exec ${noctalia} msg panel-toggle control-center
      bindsym $mod+Ctrl+a exec ${noctalia} msg panel-toggle control-center audio
    '';
  };
}
