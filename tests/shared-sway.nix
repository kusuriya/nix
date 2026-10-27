# Run: nix eval --impure --json --expr \
# 'import ./tests/shared-sway.nix { flake = builtins.getFlake ("path:" + toString ./.); }'
{ flake }:
let
  lib = flake.inputs.nixpkgs.lib;
  checkHost = host:
    let
      c = flake.nixosConfigurations.${host}.config;
      hm = c.home-manager.users.kusuriya;
      n = hm.programs.noctalia.settings;
      supervised = [ "sway-kanshi" "sway-clipboard" "sway-notifications" "sway-polkit" "sway-kdeconnect" "noctalia" "noctalia-clipboard-status" ];
      checks = {
        ddc = n.brightness.enable_ddcutil && c.hardware.i2c.enable
          && builtins.elem "i2c-dev" c.boot.kernelModules
          && builtins.any (p: lib.getName p == "ddcutil") c.environment.systemPackages
          && lib.hasPrefix "${flake.nixosConfigurations.${host}.pkgs.ddcutil}/bin:" c.systemd.user.services.noctalia.environment.PATH;
        uwsm = c.programs.uwsm.enable && !c.programs.sway.wrapperFeatures.base;
        greetd = lib.hasInfix "uwsm start" c.services.greetd.settings.initial_session.command
          && c.services.greetd.settings.initial_session.command == c.services.greetd.settings.default_session.command;
        supervisedServices = builtins.all
          (name:
            let s = c.systemd.user.services.${name}; in
            s.enable && s.wantedBy == [ "graphical-session.target" ]
            && s.partOf == [ "graphical-session.target" ]
            && s.unitConfig.ConditionEnvironment == (if name == "sway-clipboard" then "WAYLAND_DISPLAY" else "SWAYSOCK")
          )
          supervised;
        oldAppletsDisabled = builtins.all (name: !c.systemd.user.services.${name}.enable)
          [ "sway-waybar" "sway-network-applet" "sway-bluetooth-applet" ];
        oneNoctaliaOwner = hm.programs.noctalia.enable && !hm.programs.noctalia.systemd.enable;
        upperRight = n.shell.panel.control_center_placement == "attached"
          && n.shell.panel.control_center_position == "top_right"
          && !n.shell.panel.open_near_click_control_center;
        preserveExternalOwners = !n.shell.clipboard_enabled && !n.shell.polkit_agent
          && !n.notification.enable_daemon && !n.wallpaper.enabled
          && !n.lockscreen.enabled
          && builtins.all (b: !b.enabled) (builtins.attrValues n.idle.behavior);
        clipboardStatus = builtins.elem "clipboard-status" n.bar.main.end
          && n.widget.clipboard-status.type == "custom_button";
        shortcuts = lib.hasInfix "$mod+Ctrl+n" hm.home.file.".config/sway/config.d/noctalia.conf".text
          && lib.hasInfix "$mod+Ctrl+a" hm.home.file.".config/sway/config.d/noctalia.conf".text;
        noDuplicateAutostarts = builtins.all
          (name:
            lib.hasInfix "Hidden=true" hm.xdg.configFile."autostart/${name}.desktop".text
          ) [ "blueman" "nm-applet" "polkit-gnome-authentication-agent-1" ];
      };
    in
    assert lib.assertMsg (builtins.all (v: v) (builtins.attrValues checks))
      "Shared Sway regression on ${host}: ${builtins.toJSON checks}";
    checks;
in
{
  beast = checkHost "beast";
  framey = checkHost "framey";
  sameSwayConfig = assert
    flake.nixosConfigurations.beast.config.home-manager.users.kusuriya.home.file.".config/sway/config".source
    == flake.nixosConfigurations.framey.config.home-manager.users.kusuriya.home.file.".config/sway/config".source;
    true;
}
