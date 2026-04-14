{ config, pkgs, inputs, outputs, ... }:
{
  environment = {
    systemPackages = with pkgs; [

      syncthingtray
      nemo
      syncthing
      ada
      ncurses
      zlib
      gnumake
      bison
      gnat
      flex
      gnupatch
      wireguard-ui
      wireguard-tools
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
      gnome-boxes
      orca-slicer
      nfs-utils
      virt-viewer
      makemkv
      ghostty
      handbrake

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
      signal-desktop
      slack
      telegram-desktop
      zoom-us
      weechat


      #Sec Stuff
      burpsuite
      nmap

      #electronics
      freecad

      unstable.arrow-cpp
      #browser
      chromium
      inputs.firefox.packages.${pkgs.system}.firefox-nightly-bin
      vivaldi

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
