{ pkgs, ... }:
let
  pname = "azeron-software-appimage";
  version = "2.0.2";

  src = pkgs.fetchurl {
    url = "https://azeron-software-public.s3.us-east-1.amazonaws.com/live/${version}/Azeron-Software-v${version}.AppImage";
    hash = "sha256-D9d5Og3uIKmCs3Tw9hRozbjJ8oAhBR+Vv0oRWchoHh4=";
  };

  appimageContents = pkgs.appimageTools.extract {
    inherit pname version src;
  };

  # Upstream's desktop entry contains stray numbered keys (0=S, 1=t, ...).
  desktopFile = pkgs.writeText "azeron-software.desktop" ''
    [Desktop Entry]
    Type=Application
    Name=Azeron Software
    Exec=azeron-software-appimage %U
    Icon=azeron-software
    Terminal=false
    Categories=Utility;
    StartupWMClass=Azeron Software
  '';
in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ pkgs.makeWrapper ];
  extraPkgs = p: with p; [
    udev
    libusb1
  ];

  extraInstallCommands = ''
    install -Dm444 ${desktopFile} \
      $out/share/applications/azeron-software.desktop
    install -Dm444 ${appimageContents}/usr/share/icons/hicolor/256x256/apps/azeron-software.png \
      $out/share/icons/hicolor/256x256/apps/azeron-software.png
    install -Dm444 ${./70-azeron-devices.rules} \
      $out/lib/udev/rules.d/70-azeron-devices.rules

    # Upstream launches Electron with --no-sandbox in its desktop entry;
    # the bundled chrome-sandbox cannot be installed setuid from a Nix derivation.
    wrapProgram $out/bin/azeron-software-appimage --add-flags --no-sandbox
  '';

  meta = {
    description = "Azeron Software 2.0 gaming keypad configurator (upstream AppImage)";
    homepage = "https://azeron.com/pages/software";
    license = pkgs.lib.licenses.unfree;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
