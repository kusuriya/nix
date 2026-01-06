{ pkgs, ... }:
{
  rd560driver = pkgs.stdenv.mkDerivation {
    pname = "RD560-driver";
    version = "1.0";
    buildInputs = [ pkgs.cups ]; # Needed for cups-genppdupdate if applicable
    installPhase = ''
      mkdir -p $out/share/cups/model/
      cp ./RD560-printer.ppd $out/share/cups/model/RD560-printer.ppd
      cp ./RD560-printer-AD.ppd $out/share/cups/model/RD560-printer-AD.ppd
      mkdir -p $out/lib/cups/filter/
      cp ./labelrange_printer_filter $out/lib/cups/filter/
    '';
    #meta = { ... };
  };
}
