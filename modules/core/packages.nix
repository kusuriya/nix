{ config, pkgs, inputs, outputs, ... }:
{
  environment = {
    systemPackages = with pkgs; [

      #KDE Packages
      kdePackages.plasma-browser-integration
      kdePackages.ffmpegthumbs
      kdePackages.filelight
      kdePackages.flatpak-kcm
      kdePackages.francis
      kdePackages.kaccounts-integration
      kdePackages.kaccounts-providers
      kdePackages.kalk
      kdePackages.kamera
      kdePackages.kcalc
      kdePackages.kcron
      kdePackages.kdeconnect-kde
      kdePackages.kio
      kdePackages.kio-admin
      kdePackages.kio-extras
      kdePackages.kio-fuse
      kdePackages.kio-zeroconf
      kdePackages.korganizer
      kdePackages.krdc
      kdePackages.kmail
      syncthingtray
      syncthing



      openterface-qt
      lua-language-server
      pyright
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
      dnsmasq
      appimage-run
      openconnect
      p7zip
      mosh
      _1password-cli
      slurp
      swaybg
      swayidle
      swaylock
      kanshi
      wev
      sway-contrib.grimshot
      gcc
      clang
      zig
      blueman


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
      treefmt

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
      _1password-cli

      logseq
      parsec-bin
      rclone
      rsync
      yt-dlp
      inkscape
      cider
      libreoffice
      transmission_4-qt
      via
      drawio
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


      #Sec Stuff
      burpsuite
      nmap

      #electronics
      kicad
      freecad

      unstable.arrow-cpp
      #browser
      chromium
      inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin

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

    ];
  };
}
