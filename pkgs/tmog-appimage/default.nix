{ pkgs, ... }:
let
  pname = "tmog-appimage";
  version = "1.0.0";

  src = pkgs.fetchurl {
    url = "https://tmog.org/rtm/downloads/TaskManagerOG-${version}-x86_64.AppImage";
    hash = "sha256-7jd6c5SfiQhju8+tCd02tgugR28Me8vQ0Os0NeKQKpY=";
  };

  desktopItem = pkgs.makeDesktopItem {
    name = pname;
    desktopName = "Task Manager TMOG";
    comment = "Native system monitor and task manager";
    exec = pname;
    icon = "utilities-system-monitor";
    terminal = false;
    categories = [ "System" "Monitor" ];
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
    description = "TMOG task manager distributed as an upstream AppImage";
    homepage = "https://tmog.org/";
    license = pkgs.lib.licenses.unfree;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
