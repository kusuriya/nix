{ config, pkgs, inputs, outputs, ... }:
{
  environment = {
    systemPackages = with pkgs; [

      _1password
      _1password-cli
      kdePackages.plasma-browser-integration
    
      openterface-qt
      wget
      git
      curl
      distrobox
      neovim
      linux-firmware
      glib
      glib-networking
      btrfs-progs
      btrfs-snap
      timeshift
      swtpm
      edk2
      dnsmasq
      appimage-run
      openconnect
      p7zip
      mosh

      # nix
      nix-diff
      nix-index
      nix-output-monitor
      nix-prefetch-git
      nil
      sops
      age
      nixpkgs-fmt
      deadnix
      statix

      usbutils
      coreutils
      pciutils
      brightnessctl
      virt-viewer
      spice-gtk


      (OVMF.override {
        tpmSupport = true;
        secureBoot = true;
        msVarsTemplate = true;
        httpSupport = true;
        tlsSupport = true;
      })
      #passwords
      _1password-gui
      _1password-cli

      lmstudio
      logseq
      parsec-bin
      rclone
      rsync
      yt-dlp
      inkscape
      gimp
      cider
      libreoffice
      transmission_4-qt
      via
      drawio
      calibre
      alacritty
      appimage-run
      btop
      moonlight-qt
      element-desktop
      virt-manager
      imagemagick
      pandoc
      catt
      unstable.looking-glass-client
      texliveFull
      kdePackages.kmail
      devenv
      direnv
      distrobox
      gnome-icon-theme
      adwaita-icon-theme
      cascadia-code


      #communication
      discord
      signal-desktop-bin
      slack
      telegram-desktop
      zoom-us
      weechat


      #nix
      nixpkgs-fmt
      statix
      deadnix
      treefmt

      #Sec Stuff
      burpsuite
      nmap

      #electronics
      kicad
      freecad

      #browser
      chromium
      (vivaldi.overrideAttrs (oldAttrs: {
        dontWrapQtApps = false;
        dontPatchELF = true;
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.kdePackages.wrapQtAppsHook ];
      }))
      vivaldi-ffmpeg-codecs
      inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin
      librewolf

      #Dictonary
      (aspellWithDicts (
        dicts: with dicts; [
          en
          en-computers
          en-science
        ]
      ))

      libva
      libva-utils
      vulkan-tools
      vulkan-validation-layers
      mesa-demos
      mesa
      gnome-boxes
    ];
  };
}
