{ pkgs, ... }:
let
  pname = "veilamp-appimage";
  version = "0.3.6";

  # Resolved from upstream's latest-release link; pin the release and bytes.
  src = pkgs.fetchurl {
    url = "https://gitlab.com/api/v4/projects/86817098/packages/generic/veilamp/v${version}/veilamp-linux-amd64.AppImage";
    hash = "sha256-AEmDyLMzEOs1uBoPO8GQAZT+JvvEsiyrF9wOfB1WSiw=";
  };

  appimageContents = pkgs.appimageTools.extract {
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
    libopenmpt
    alsa-lib
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
  ];

  extraInstallCommands = ''
    install -Dm444 ${appimageContents}/veilamp.desktop \
      $out/share/applications/veilamp.desktop
    cp -r ${appimageContents}/usr/share/icons $out/share/
    substituteInPlace $out/share/applications/veilamp.desktop \
      --replace-fail 'Exec=veilamp' 'Exec=veilamp-appimage' \
      --replace-fail 'Name=veilamp' 'Name=Veilamp'
    wrapProgram $out/bin/veilamp-appimage \
      --set GIO_EXTRA_MODULES "${pkgs.glib-networking}/lib/gio/modules" \
      --set SSL_CERT_FILE "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
  '';

  meta = {
    description = "Retro-styled P2P audio player (upstream AppImage)";
    homepage = "https://gitlab.com/wrewtopia-labs-group/veilamp";
    mainProgram = pname;
    platforms = [ "x86_64-linux" ];
  };
}
