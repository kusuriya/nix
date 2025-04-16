# /etc/nixos/overlays/openconnect-git.nix
self: super: {
  openconnect = super.openconnect.overrideAttrs (oldAttrs: rec {
    version = "git-${src.shortRev or "unknown"}";
    src = super.fetchGit {
      url = "https://gitlab.com/openconnect/openconnect.git";
      # You can optionally specify a specific branch, tag, or commit hash (rev)
      # rev = "refs/heads/master"; # Or a specific commit hash like "abcdef123..."
      # fetchSubmodules = true; # If the project uses Git submodules
      rev = "master";
      sha256 = "";
      # You can get the sha256 hash by first trying to build with a placeholder like lib.fakeSha
    };

    # You might need to adjust build inputs or configure flags if the Git version
    # has different dependencies or build requirements than the version in nixpkgs.
    # buildInputs = oldAttrs.buildInputs ++ [ /* any new dependencies */ ];
    # configureFlags = oldAttrs.configureFlags ++ [ "--some-new-flag" ];

    # Sometimes patches applied in nixpkgs might need removing or adjusting
    # patches = []; 
  });
}

