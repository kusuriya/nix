{ lib, stdenv, cups, autoPatchelfHook, makeWrapper, ghostscript }:

stdenv.mkDerivation rec {
  pname = "labelrange-rd560";
  version = "1.0"; # Update based on actual driver version

  # Option 1: If you have the driver file locally
  src = ./rd560.tar.gz; # Adjust filename

  nativeBuildInputs = [
    autoPatchelfHook # Automatically patches ELF binaries
    makeWrapper
    # dpkg  # Uncomment if driver is a .deb file
  ];

  buildInputs = [
    cups.lib
    cups
    ghostscript
  ];

  # Adjust unpack phase based on driver format
  unpackPhase = ''
    runHook preUnpack
    mkdir -p $TMPDIR/unpacked

    # For tar.gz:
    tar -xzf $src -C $TMPDIR/unpacked

    # For .deb files, use instead:
    # dpkg-deb -x $src $TMPDIR/unpacked

    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    # Create CUPS directory structure
    mkdir -p $out/lib/cups/filter
    mkdir -p $out/share/cups/model/labelrange

    # Copy filter binary from tarball root
    FILTER_SRC="$TMPDIR/unpacked/labelrange_printer_filter"
    FILTER_DST="$out/lib/cups/filter/rastertord560"
    if [ -f "$FILTER_SRC" ]; then
      cp -v "$FILTER_SRC" "$FILTER_DST"
      chmod +x "$FILTER_DST"
    fi
    
    PPD_SRC="$TMPDIR/unpacked"
    for ppd in "$PPD_SRC"/*.ppd; do
      if [ -f "$ppd" ]; then
        cp -v "$ppd" "$out/share/cups/model/labelrange/"
      fi
    done

    # Patch PPD file to use correct filter path
    for ppd in $out/share/cups/model/labelrange/*.ppd; do
      if [ -f "$ppd" ]; then
        # Replace common FHS paths with Nix store path
        substituteInPlace "$ppd" \
          --replace "/usr/lib/cups/filter/" "$out/lib/cups/filter/" \
          --replace "/usr/local/lib/cups/filter/" "$out/lib/cups/filter/" \
          --replace "/opt/labelrange/bin/" "$out/lib/cups/filter/"
      fi
    done

    runHook postInstall
  '';

  meta = with lib; {
    description = "CUPS driver for Labelrange RD560 thermal label printer";
    homepage = "https://www.labelrange.com/";
    license = licenses.unfree;
    platforms = platforms.linux;
    maintainers = [ ];
  };
}
