{ pkgs, ... }:
let
  pname = "curseforge-appimage";
  version = "1.321.1-39714";

  src = pkgs.fetchurl {
    url = "https://curseforge.overwolf.com/downloads/curseforge-latest-linux.AppImage";
    hash = "sha256-4DQZNlrJGY1gGAyqB74+vhhI9lCDPAEQrayhSX5G0Uc=";
  };

  desktopItem = pkgs.makeDesktopItem {
    name = pname;
    desktopName = "CurseForge";
    comment = "CurseForge desktop app";
    exec = pname;
    terminal = false;
    categories = [ "Game" ];
  };
in
pkgs.stdenv.mkDerivation {
  inherit pname version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;
  nativeBuildInputs = [ pkgs.makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ${src} "$out/share/${pname}/${pname}.AppImage"
    makeWrapper ${pkgs.appimage-run}/bin/appimage-run "$out/bin/${pname}" \
      --add-flags "$out/share/${pname}/${pname}.AppImage"
    install -Dm644 ${desktopItem}/share/applications/${pname}.desktop \
      "$out/share/applications/${pname}.desktop"
    runHook postInstall
  '';

  meta = {
    description = "CurseForge desktop app distributed as an upstream AppImage";
    homepage = "https://www.curseforge.com/download/app";
    license = pkgs.lib.licenses.unfree;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
