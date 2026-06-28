{ ... }:
{
  nix = {
    settings = {
      experimental-features = [ "nix-command" "flakes" ];
      auto-optimise-store = true;
      max-jobs = "auto";
      max-substitution-jobs = 64;
      # Disk-full guard — trigger GC when free space drops, stop when enough is reclaimed
      min-free = 1073741824; # 1GB — start GC
      max-free = 4294967296; # 4GB — stop GC
    };
    optimise.automatic = true;
    gc = {
      automatic = true;
      dates = "weekly";
      options = "--delete-older-than 7d";
    };
  };
}
