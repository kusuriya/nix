# nix

Multi-host NixOS flake
  configuration.## Hosts

  | Host |
  Hardware |
  Role |
  Desktop |
  Encryption |
  | - -----|----------|------|---------|------------|
| * * framey * * | Framework 13 AMD (Ryzen 7 7840 U, 96 GB) | Laptop / daily driver | Sway | LUKS2 + Secure Boot (lanzaboote) + TPM2 |
| **beast** | Custom desktop (AMD, NVIDIA RTX 3060) | Desktop / gaming / VM host | Sway | None |
| **pve** | Home server (Intel, ZFS) | Server (Proxmox host) | None | None |

## Quick start

```bash
# Clone and set up
git clone https://github.com/kusuriya/nix ~/nix
cd ~/nix

# One-time setup (hooks + direnv)
just init

# Build and switch on the target host
sudo nixos-rebuild switch --flake ~/nix#<hostname>

# Update flake inputs
nix flake update
```

## Common tasks (via just)

| Command | What |
|---------|------|
| `just switch` | Build + switch to framey |
| `just switch h=beast` | Build + switch to beast |
| `just build` | Dry-run build |
| `just check` | Format + lint all Nix files |
| `just update` | Update all flake inputs |
| `just gc` | Nix garbage collection (keep 7 days) |
| `just diff` | Show package diff since last rebuild |
| `just shell` | Enter devShell (fmt/lint tools) |
| `just init` | Install git hooks + allow direnv |

## Structure

```
flake.nix              # Entry point — mkSystem helper, inputs, outputs
hosts/                 # Per-host configuration
framey/              #   Laptop (disko, LUKS2, packages)
beast/               #   Desktop (disko, NVIDIA, packages)
pve/                 #   Server (Samba, roles)
modules/
core/                # Shared config (nix, packages, fonts, locale, etc.)
desktop/sway/        # Sway + greetd + Waybar + wayland stack
kernel/latest/       # Latest kernel pin
overlays/              # Custom overlays (additions, unstable-packages)
pkgs/                  # Custom packages (labelrange-rd560, glowing-bear)
home-manager/          # Home-manager config + dotfiles
roles/                 # Server roles (mediaserver, paperlessngx, etc.)
.github/workflows/     # CI — format/lint/build on push
.githooks/             # Pre-commit hooks (auto-format staged Nix files)
```

## Agent support

This repo includes `AGENTS.md`, `CLAUDE.md` → `AGENTS.md`, `.cursorrules` → `AGENTS.md`, a `justfile`, `.envrc` (direnv), and CI — all designed so AI agents can navigate, edit, and validate the config without guessing.

## License

BSD 3-Clause — see [LICENSE](LICENSE).
