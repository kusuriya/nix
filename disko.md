# framey — encrypted btrfs migration

Instructions for applying the LUKS-encrypted btrfs layout defined in
`hosts/framey/disko.nix`.

> **This is destructive.** disko reformats the whole disk. It does **not**
> run on a normal `nixos-rebuild` — formatting only happens when you
> explicitly run the disko tool from a live USB. Back up your data first.

## Layout

- **ESP** (1 GB, vfat, `/boot`) — unencrypted, required for
  systemd-boot/lanzaboote (kernel + initrd live here in the clear, which is
  why Secure Boot matters on this host).
- **LUKS2 container** filling the rest, opening as `cryptroot`, with
  `tpm2-device=auto` for TPM-backed auto-unlock (falls back to passphrase).
- **btrfs** inside with `@root`, `@home`, `@nix`, `@log` subvolumes
  (zstd + noatime).
- **Encrypted swapfile** (`@swap`, 32 G) — inside the LUKS volume, so it's
  encrypted. Set to >= RAM if you want hibernation (framey = 32 G).

## Steps

### 1. Wire it into the flake

Add the disko module + the layout file to `framey` in `flake.nix`:

```nix
framey = mkSystem {
  hostname = "framey";
  extraModules = [
    inputs.disko.nixosModules.disko
    ./hosts/framey/disko.nix
    inputs.hardware.nixosModules.framework-13-7040-amd
    inputs.hardware.nixosModules.common-pc-ssd
    inputs.lanzaboote.nixosModules.lanzaboote
  ];
};
```

(or import `./disko.nix` from `hosts/framey/default.nix` — either works.)

### 2. Remove conflicting fileSystems

disko generates `fileSystems.*` and `swapDevices`, so the existing `/`,
`/boot`, and `swapDevices` entries in `hosts/framey/hardware-configuration.nix`
will collide. Delete those; keep only the `boot.initrd.*`, `kernelModules`,
and microcode bits.

> Don't commit steps 1 + 2 until you're about to migrate — the flake won't
> evaluate against the running ext4 system once the fileSystems are gone.

### 3. Verify the device path

Confirm the disk in `disko.nix` (`/dev/nvme0n1`) with `lsblk` from the
installer. A `/dev/disk/by-id/...` path is more robust against reordering.

### 4. Format + install (from a NixOS live USB)

```sh
sudo nix run github:nix-community/disko -- --mode disko --flake .#framey
sudo nixos-install --flake .#framey
```

disko prompts for the LUKS passphrase during formatting.

### 5. Enroll the TPM (after first boot)

So the disk auto-unlocks without typing a passphrase every boot:

```sh
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+2+7 /dev/nvme0n1p2
```

Keep the passphrase as a fallback. Binding PCR 7 ties unlock to Secure Boot
state.

### 6. Enable Secure Boot (recommended companion)

You already have lanzaboote staged. Flip `boot.lanzaboote.enable = true` and
set up the keys with `sbctl` so an attacker can't bypass the TPM measurement
by swapping the bootloader. Requires `boot.initrd.systemd.enable = true`
(already set on framey), which is also what makes `tpm2-device=auto` work.
