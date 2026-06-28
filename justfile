# Nix flake — common operations
# `just <recipe>` instead of remembering nixos-rebuild flags

host := "framey"

# Build and switch the system, then reload Sway config
switch h=host:
    sudo nixos-rebuild switch --flake ~/nix#{{h}} && { swaymsg reload 2>/dev/null || true; }

# Build without switching (dry run)
build h=host:
    nixos-rebuild build --flake ~/nix#{{h}}

# Update all flake inputs
update:
    nix flake update

# Nix garbage collection — keep last 7 days
gc:
    sudo nix-collect-garbage --delete-older-than 7d
    nix-collect-garbage --delete-older-than 7d

# Format and lint all Nix files
check:
    treefmt --fail-on-change

# Enter devShell with formatter/lint tools
shell:
    nix develop

# Show diff between current and next generation
diff:
    nvd diff $(ls -dv /nix/var/nix/profiles/system-*-link | tail -1) /run/current-system

# One-time setup: install git hooks and allow direnv
init:
    git config core.hooksPath .githooks
    @echo "git hooks installed (core.hooksPath = .githooks)"
    direnv allow 2>/dev/null || true
    @echo "direnv allowed (if installed)"
