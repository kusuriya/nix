# ============================================================================
# UNIVERSAL CORE PACKAGES
# ============================================================================
# This file contains packages that should be installed on ALL hosts
# (framey, beast, wusc063016, pve).
#
# Host-specific packages (desktop, laptop, security, GUI apps, etc.) live
# in each host's own packages.nix file, imported via that host's default.nix.
#   e.g. /data/nix/hosts/framey/packages.nix
# ============================================================================
{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      # ============================================================================
      # SYSTEM CORE & UTILITIES
      # ============================================================================

      coreutils # GNU coreutils — ls, cp, mv, cat, etc. (baseline)
      gnumake # Make build system
      bison # Parser generator (build dep for some packages)
      flex # Lexer generator (build dep for some packages)
      gnat # GNU Ada compiler (build dep for some packages)
      gnupatch # GNU patch utility
      bc # Arbitrary-precision calculator
      ada # Ada language support
      ncurses # Terminal library (terminfo, clear, etc.)
      zlib # Compression library (runtime dep)
      glib # GLib — GObject/Sound/IO core lib (runtime dep)
      glib-networking # GNOME network stack (TLS, proxy support for glib apps)
      linux-firmware # Firmware blobs for kernel drivers (WiFi, GPU, etc.)
      p7zip # 7z archive handling
      usbutils # lsusb, usb-devices — USB diagnostics
      pciutils # lspci, setpci — PCI diagnostics
      brightnessctl # Backlight/brightness control for laptops/monitors

      # ============================================================================
      # NIX TOOLING
      # ============================================================================

      nil # Nix LSP — autocompletion, goto-definition in Neovim/VS Code
      nixd # Nix LSP (alternate) — better for flake-based setups in some cases
      nixpkgs-fmt # Nix file formatter (opinionated, stable)
      alejandra # Nix formatter (alternate, more opinionated than nixpkgs-fmt)
      deadnix # Find dead/unused code in nix expressions
      statix # Nix linter — catches anti-patterns, suggests fixes
      treefmt # Multi-language formatter orchestrator (nix + python + etc.)
      nix-diff # Diff two nix derivations — see what changed
      nix-index # nix-locate — find packages providing specific files/binaries
      nix-output-monitor # nom — better nix build output (progress, timing, diffs)
      nix-prefetch-git # Prefetch git repos for nix expressions (get hashes)
      nvd # Nix version diff — compare generations, see what changed between rebuilds
      nix-tree # Interactive dependency tree viewer — explore nixpkgs closure graph in TUI
      manix # Search NixOS options, man pages, and nixpkgs docs from CLI
      nix-init # Generate nix expressions from upstream sources — simplifies packaging

      # ============================================================================
      # SECRETS & PASSWORD MANAGEMENT (CLI only — GUI managers are host-specific)
      # ============================================================================

      _1password-cli # 1Password CLI — op command for secret/scripting access
      sops # Secrets ops — encrypt YAML/JSON/env files in git
      age # Modern file encryption — simpler than GPG, pairs with sops

      # ============================================================================
      # SHELL QOL — NAVIGATION & HISTORY
      # ============================================================================

      zoxide # Smarter cd with frecency — `z hermes` jumps to ~/projects/hermes
      atuin # Synced searchable shell history — Ctrl+R fuzzy, context restore
      fzf # Fuzzy finder — file search, git checkout, process kill, Cmd history
      starship # Cross-shell prompt — git branch, python env, nix shell, k8s context
      direnv # Auto-load/unload env per directory — `use flake` for nix shells
      carapace # Shell completion engine — multi-command completions for fish

      # ============================================================================
      # FILE VIEWING & LISTING
      # ============================================================================

      eza # Better ls — git status per file, icons, tree mode
      bat # Better cat — syntax highlighting, line numbers, git integration
      glow # Terminal markdown renderer — preview Obsidian notes, READMEs
      ncdu # Interactive disk usage — TUI, fast, navigable
      dust # Visual disk usage — Rust du alternative with tree display

      # ============================================================================
      # DEVELOPMENT — COMPILERS & BUILD TOOLCHAIN (baseline only)
      # ============================================================================

      gcc # GNU C/C++ compiler — baseline build toolchain

      # ============================================================================
      # DEVELOPMENT — TOOLS (CLI, needed on all hosts)
      # ============================================================================

      git # Version control — baseline
      delta # Side-by-side syntax-highlighted diffs — transforms git log/diff/show
      jq # JSON processor — parse APIs, configs, pipe filtering
      yq-go # YAML processor — jq for YAML (Hermes config, K8s, manifests)
      dasel # Multi-format data selector — JSON/YAML/TOML/XML/CSV in one tool
      gron # Flattens JSON for grepping — `gron file.json | grep host`
      fd # Better find — `fd "\.py$"`, respects .gitignore by default
      sd # Better sed — `sd 'old' 'new' file.txt`, regex-based, no delimiter mess
      ripgrep # Fast regex search — rg, essential. Already had it but making it explicit
      distrobox # Container-based dev environments (podman/docker integration)
      hexyl # Hex viewer — colorized, Rust, pipe-friendly. Better than xxd
      just # Modern make — justfile, simpler syntax, no tab requirements

      # ============================================================================
      # DEVELOPMENT — CONVENIENCE (CLI, universal)
      # ============================================================================

      tealdeer # Fast cheatsheets — `tldr tar` instead of `man tar`
      pandoc # Universal doc converter — Markdown → HTML/PDF/DOCX

      # ============================================================================
      # HTTP & NETWORK DIAGNOSTICS (baseline)
      # ============================================================================

      curl # HTTP client — baseline (already in core but explicit)
      wget # HTTP download — baseline
      doggo # Better dig — colorful DNS, multiple record types, JSON output

      # ============================================================================
      # PROCESS & SYSTEM MONITORING (lightweight, universal)
      # ============================================================================

      hyperfine # Benchmark commands — `hyperfine --warmup 3 'cmd1' 'cmd2'`
      tokei # Fast LOC counter — `tokei .` gives language breakdown instantly
    ];
  };
}
