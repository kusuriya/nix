{ ... }:
{
  imports = [
    ./kusuriya.nix
    ./home-manager.nix
    ./fonts.nix
    ./packages.nix
    ./nix.nix
    ./locale.nix
  ];
  nix = {
    settings = {
      substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://home-manager.cachix.org"
        "https://disko.cachix.org"
        "https://lanzaboote.cachix.org"
      ];
      trusted-substituters = [
        "https://cache.nixos.org"
        "https://nix-community.cachix.org"
        "https://hyprland.cachix.org"
        "https://home-manager.cachix.org"
        "https://disko.cachix.org"
        "https://lanzaboote.cachix.org"
      ];

      trusted-public-keys = [
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
        "home-manager.cachix.org-1:2FvFoQTAMCk3jMkU3LRIMpQfs6h3eC27nZ5c5FiooXE="
        "disko.cachix.org-1:gM/PbZ+sp2rUZx2pDh7p5LrV0V58mdaUNb7X2hRq7XI="
        "lanzaboote.cachix.org-1:XZ+6CHbs6GbbF1ff6Bn95vEqgpXFNPCpRdTGr/+fIlA="
      ];
    };
  };
  services.udev.extraRules = ''
    SUBSYSTEM=="usb", ATTRS{idVendor}=="534d", ATTRS{idProduct}=="2109", TAG+="kusuriya"
    SUBSYSTEM=="hidraw", ATTRS{idVendor}=="534d", ATTRS{idProduct}=="2109", TAG+="kusuriya"
    SUBSYSTEM=="ttyUSB", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="7523", TAG+="kusuriya"
  '';

  # --- Build-time optimizations ---
  # Skip doc generation — saves ~30-60s per nixos-rebuild
  documentation = {
    nixos.enable = false;
    info.enable = false;
  };

  # Clean /tmp on every boot (especially useful on laptops that suspend/resume)
  boot.tmp.cleanOnBoot = true;

  # Rate-limit journald — auditd generates significant log volume
  services.journald = {
    rateLimitBurst = 10000;
    rateLimitInterval = "30s";
  };

  # OOM configuration:
  systemd = {
    # Create a separate slice for nix-daemon that is
    # memory-managed by the userspace systemd-oomd killer
    slices."nix-daemon".sliceConfig = {
      ManagedOOMMemoryPressure = "kill";
      ManagedOOMMemoryPressureLimit = "99%";
    };
    services."nix-daemon".serviceConfig.Slice = "nix-daemon.slice";

    # If a kernel-level OOM event does occur anyway,
    # strongly prefer killing nix-daemon child processes
    services."nix-daemon".serviceConfig.OOMScoreAdjust = 1000;
  };

  security.polkit = {
    enable = true;
    extraConfig = ''
        polkit.addRule(function(action, subject) {
        if (
          subject.isInGroup("users")
            && (
              action.id == "org.freedesktop.login1.reboot" ||
              action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
              action.id == "org.freedesktop.login1.power-off" ||
              action.id == "org.freedesktop.login1.power-off-multiple-sessions"
            )
          )
        {
          return polkit.Result.YES;
        }
      }); 
    '';
  };

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;
      dockerCompat = true;
      defaultNetwork.settings.dns_enabled = true;
    };
    waydroid.enable = false;
  };
}
