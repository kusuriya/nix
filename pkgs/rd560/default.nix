{ config, pkgs, lib, ... }:

let
  # Import the driver package
  labelrange-rd560 = pkgs.callPackage ./labelrange-rd560.nix { };
in
{
  # Enable CUPS printing service
  services.printing = {
    enable = true;

    # Add the driver to CUPS
    drivers = [ labelrange-rd560 ];

    # Optional: Enable debug logging for troubleshooting
    # logLevel = "debug";
  };

  # Optional: Declarative printer configuration
  hardware.printers = {
    ensurePrinters = [
      {
        name = "LabelRange-RD560";
        location = "Office";
        description = "Labelrange RD560 Label Printer";

        # For USB connection:
        deviceUri = "usb://Labelrange/RD560?serial=YOUR_SERIAL";

        # For Bluetooth (after pairing):
        # deviceUri = "bluetooth://XX:XX:XX:XX:XX:XX";

        # Model should match the PPD filename (run `lpinfo -m` after rebuild to find it)
        model = "labelrange/RD560.ppd";  # Adjust based on actual PPD name

        ppdOptions = {
          PageSize = "w72h100";  # Common label size, adjust as needed
        };
      }
    ];
    ensureDefaultPrinter = "LabelRange-RD560";
  };

  # For Bluetooth printing support
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}

