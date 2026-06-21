{ lib
, config
, ...
}:
{
  nix = {
    settings = {
      allowed-users = [ "kusuriya" ];
      trusted-users = [ "kusuriya" ];
      auto-optimise-store = true;
      experimental-features = [ "nix-command" "flakes" ];
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";

    };
  };
}
