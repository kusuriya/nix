{ config
, lib
, ...
}:
with lib; {
  options = {
    autoUpdate = {
      enable = mkOption {
        description = "Enable Auto Update";
        default = true;
        example = true;
        type = lib.types.bool;
      };
    };
  };

  config = mkMerge [
    (mkIf config.autoUpdate.enable {
      system.autoUpgrade = {
        # enable is set in flake depending on the state of the tree
        # DIRTY means disabled, git revision means enabled
        allowReboot = mkDefault true;
        dates = "*-*-* *:05:00";
      };
    })
  ];
}

