# nix

Multi-host NixOS flake configuration.

## Hosts

| Host | Hardware | Role | Desktop | Encryption |
|------|----------|------|---------|------------|
| **framey** | Framework 13 AMD (Ryzen 7 7840U, 96 GB) | Laptop / daily driver | Sway | LUKS2 + Secure Boot (lanzaboote) + TPM2 |
| **beast** | Custom desktop (AMD, VFIO passthrough) | Desktop / gaming / VM host | Plasma6 + Sway | None |
| **pve** | Home server (Intel, ZFS) | Server (Proxmox host) | None | None |

## Structure

```
flake.nix              # Entry point — mkSystem helper, inputs, outputs
hosts/                 # Per-host configuration
  framey/              #   Laptop (disko, LUKS2, packages, README)
  beast/               #   Desktop (VFIO, hardware-configuration)
  pve/                 #   Server (Samba, roles)
modules/
  core/                # Shared modules (nix, packages, fonts, locale, etc.)
  desktop/sway/        # Sway desktop module
  kernel/latest/       # Latest kernel module
overlays/              # Custom overlays (additions, unstable-packages)
pkgs/                  # Custom packages (rd560, glowing-bear)
home-manager/          # Home-manager config + dotfiles
roles/                 # Server roles (mediaserver, lightning, etc.)
```

## Building

```bash
# Build and switch on the target host
sudo nixos-rebuild switch --flake ~/nix#<hostname>

# Build without switching (dry run)
nixos-rebuild build --flake ~/nix#<hostname>

# Update flake inputs (manual — autoUpgrade no longer bumps nixpkgs)
nix flake update
```

## License

BSD 3-Clause — see [LICENSE](LICENSE).