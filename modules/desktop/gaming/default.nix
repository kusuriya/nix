{ config
, lib
, pkgs
, ...
}:
{
  # Steam is proprietary; permit only its packages, not all unfree software.
  # A host's existing allowUnfree policy still takes precedence.
  nixpkgs.config.allowUnfreePredicate = lib.mkDefault (pkg:
    builtins.elem (lib.getName pkg) [
      "steam"
      "steam-original"
      "steam-unwrapped"
      "steam-run"
    ]);

  hardware.graphics = {
    enable = lib.mkDefault true;
    enable32Bit = lib.mkDefault true;
  };

  programs.steam = {
    enable = lib.mkDefault true;
    extest.enable = lib.mkDefault true;
    protontricks.enable = lib.mkDefault true;
    extraCompatPackages = [ pkgs.proton-ge-bin ];

    # Steam's FHS container needs these tools/libraries inside its runtime,
    # not merely on the host PATH. extraLibraries is evaluated for both arches.
    extraPackages = with pkgs; [ gamescope mangohud gamemode ];
    package = lib.mkDefault (pkgs.steam.override {
      extraLibraries = p: [ p.mangohud p.gamemode ];
    });

    # Do not expose streaming/server ports on every network a laptop joins.
    remotePlay.openFirewall = lib.mkDefault false;
    localNetworkGameTransfers.openFirewall = lib.mkDefault false;
    dedicatedServer.openFirewall = lib.mkDefault false;
  };

  programs.gamemode.enable = lib.mkDefault true;
  programs.gamescope = {
    # Steam defaults this to its separate-session toggle (false). Give our
    # nested-compositor default priority over that, while host values still win.
    enable = lib.mkOverride 900 true;
    # A privileged gamescope can interfere with overlay/LD_PRELOAD tooling.
    capSysNice = lib.mkDefault false;
  };

  # The upstream GameMode policy authorises the gamemode group. Reuse each
  # host's declared interactive users instead of hard-coding a username.
  users.groups.gamemode.members = lib.attrNames
    (lib.filterAttrs (_: user: user.isNormalUser) config.users.users);

  environment.systemPackages = with pkgs; [
    (lutris.override { extraPkgs = p: [ p.mangohud p.gamemode ]; })
    heroic
    wineWow64Packages.staging
    winetricks
    mangohud
    goverlay
    moonlight-qt
    vulkan-tools
    mesa-demos
  ];
}
