
{ lib
, stdenv
, fetchurl
, cups
, dpkg  # if driver comes as .deb
, autoPatchelfHook
, makeWrapper
, ghostscript  # common dependency for thermal printers
}:

stdenv.mkDerivation rec {
  pname = "labelrange-rd560";
  version = "1.0";  # Update based on actual driver version

  # Option 1: If you have the driver file locally
  src = ./rd560.tar.gz;  # Adjust filename

  nativeBuildInputs = [
    autoPatchelfHook  # Automatically patches ELF binaries
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

    # Copy filter binary (adjust path based on actual driver contents)
    # Common locations in Linux printer drivers:
    # - usr/lib/cups/filter/
    # - opt/<vendor>/bin/
    # - usr/local/lib/cups/filter/

    # Example - adjust these paths after examining the driver:
    if [ -f $TMPDIR/unpacked/usr/lib/cups/filter/rastertord560 ]; then
      cp -v $TMPDIR/unpacked/usr/lib/cups/filter/rastertord560 $out/lib/cups/filter/
    fi

    # If filter is in a different location:
    # cp -v $TMPDIR/unpacked/opt/labelrange/bin/filter_binary $out/lib/cups/filter/rastertord560

    chmod +x $out/lib/cups/filter/*

    # Copy PPD file (adjust path based on actual driver contents)
    # Common locations:
    # - usr/share/cups/model/
    # - usr/share/ppd/
    # - opt/<vendor>/ppd/

    cp -v $TMPDIR/unpacked/usr/share/cups/model/*.ppd $out/share/cups/model/labelrange/ \
      || cp -v $TMPDIR/unpacked/usr/share/ppd/*.ppd $out/share/cups/model/labelrange/ \
      || true

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
