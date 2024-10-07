{ pkgs, ... }:
let
  orcaslicer-nightly = pkgs.appimageTools.wrapType2 rec {
    name = "orcaslicer-nightly";
    pname = "orcaslicer-nightly";
    version = "2.1.0-beta";
    src = pkgs.fetchurl {
      url =
        "https://github.com/SoftFever/OrcaSlicer/releases/download/nightly-builds/OrcaSlicer_Linux_V${version}.AppImage";
      sha256 = "sha256-fkpd+jiotd3P5BycyE/GO5jN2eNlE7s2sB8sbjAjgjY=";
    };
    extraPkgs = pkgs: with pkgs; [ cacert curl glib glib-networking webkitgtk gst_all_1.gst-plugins-good gst_all_1.gst-plugins-bad gst_all_1.gst-plugins-base ];
  };

  orcaslicer = pkgs.appimageTools.wrapType2 rec {
    name = "orcaslicer";
    pname = "orcaslicer";
    version = "1.9.1";
    src = pkgs.fetchurl {
      url =
        "https://github.com/SoftFever/OrcaSlicer/releases/download/v${version}/OrcaSlicer_Linux_V${version}.AppImage";
      sha256 = "sha256-HHg0rkb7vcMcwc7PNug9M0cNqPc941KYoSSOeYxt6A4=";
    };
    extraPkgs = pkgs: with pkgs; [ cacert curl glib glib-networking webkitgtk gst_all_1.gst-plugins-good gst_all_1.gst-plugins-bad gst_all_1.gst-plugins-base ];
  };


  orcaslicer-desktop = pkgs.writeTextDir "share/applications/OrcaSlicer.desktop"
    "	[Desktop Entry]\n	Version=2.0.0-beta\n	Type=Application\n	Name=OrcaSlicer\n	Exec=orcaslicer\n";

orcaslicer-desktop-nightly = pkgs.writeTextDir "share/applications/OrcaSlicer-nightly.desktop"
    "	[Desktop Entry]\n	Version=2.0.0-beta\n	Type=Application\n	Name=OrcaSlicer-Nightly\n	Exec=orcaslicer-nightly\n";


in {
  home.packages =
    [ orcaslicer-nightly orcaslicer orcaslicer-desktop orcaslicer-desktop-nightly pkgs.glib-networking];
}

