{ pkgs, ... }:
let
  pname = "orca-slicer-appimage";
  version = "2.4.2";

  src = pkgs.fetchurl {
    url = "https://github.com/OrcaSlicer/OrcaSlicer/releases/download/v${version}/OrcaSlicer_Linux_AppImage_Ubuntu2404_V${version}.AppImage";
    hash = "sha256-0S+4yOrBrs0t+2N3rNSPmU+PpDntUpL6Uy3YKIDwKf0=";
  };

  appimageContents = pkgs.appimageTools.extractType2 {
    inherit pname version src;
  };
in
pkgs.appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ pkgs.makeWrapper ];

  extraPkgs = p: with p; [
    cacert
    glib-networking
    libsecret
    libsoup_3
    webkitgtk_4_1
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    (gst_all_1.gst-plugins-good.override { gtkSupport = true; })
    gst_all_1.gst-plugins-bad
  ];

  extraInstallCommands = ''
    install -m 444 -D \
      ${appimageContents}/usr/share/applications/com.orcaslicer.OrcaSlicer.desktop \
      $out/share/applications/orca-slicer.desktop
    install -m 444 -D \
      ${appimageContents}/usr/share/icons/hicolor/192x192/apps/OrcaSlicer.png \
      $out/share/icons/hicolor/192x192/apps/OrcaSlicer.png

    substituteInPlace $out/share/applications/orca-slicer.desktop \
      --replace-fail 'Exec=AppRun %F' 'Exec=orca-slicer-appimage %F'

    wrapProgram $out/bin/orca-slicer-appimage \
      --set GIO_MODULE_DIR "${pkgs.glib-networking}/lib/gio/modules" \
      --set GIO_EXTRA_MODULES "${pkgs.glib-networking}/lib/gio/modules" \
      --set GIO_USE_TLS gnutls \
      --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
      --set CURL_CA_BUNDLE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt" \
      --set GST_PLUGIN_PATH_1_0 /usr/lib64/gstreamer-1.0 \
      --set GST_PLUGIN_SCANNER /usr/libexec/gstreamer-1.0/gst-plugin-scanner
  '';

  meta = {
    description = "OrcaSlicer upstream AppImage with its NixOS host runtime";
    homepage = "https://github.com/OrcaSlicer/OrcaSlicer";
    license = pkgs.lib.licenses.agpl3Only;
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
