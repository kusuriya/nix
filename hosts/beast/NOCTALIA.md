# Beast Noctalia trial

Beast imports `noctalia.nix`; framey is unchanged. Noctalia 5.4.0 is pinned
from upstream with its own nixpkgs so the upstream binary cache is usable.

The bar and unified audio/network/Bluetooth controls replace Waybar,
nm-applet and blueman-applet. Sway/UWSM, Fuzzel, swaync (Mod+N), Kanshi,
wallpaper, swaylock/swayidle, Polkit, screenshots and media keys stay as-is.
External application theme templates and Noctalia clipboard capture are off.
A custom button displays the actual external clipboard capture service state
(off/recording/paused), updated via public IPC only when the state changes.
Left-click opens cliphist; right-click pauses/resumes; middle-click deletes.

## Reversible trial without sudo or logout

Push changes to GitHub first, then on beast:

```sh
cd ~/nix
git pull --ff-only
bash hosts/beast/noctalia-trial.sh
```

This builds and validates the declared config, runs transient user services,
and uses isolated Noctalia configuration/state under
`~/.local/state/noctalia-trial`. It does not activate Home Manager or change
the booted system. It stops the old bar/applets but retains their definitions.
It opens the audio panel. Trial shortcuts:

- Mod+Ctrl+N: unified control center
- Mod+Ctrl+A: audio controls

Restore the services that were active before the trial and original shortcuts:

```sh
bash ~/nix/hosts/beast/noctalia-trial.sh --stop
```

If Waybar was already stopped before the trial, explicitly restore it with
`systemctl --user start sway-waybar.service`.

## Persistent activation

Stop the trial first to avoid two Noctalia instances. Build and switch from
beast's existing lock (intentionally untracked by this repository):

```sh
bash ~/nix/hosts/beast/noctalia-trial.sh --stop
sudo nixos-rebuild switch --flake path:$HOME/nix#beast \
  --option extra-substituters https://noctalia.cachix.org \
  --option extra-trusted-public-keys 'noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4='
```

After activation verify `systemctl --user status noctalia
noctalia-clipboard-status`. No logout is expected to be necessary. The
Noctalia cache is configured persistently by the module after switching.
GUI settings live in `~/.local/state/noctalia/settings.toml` and override
base config; the trial's isolated state is not copied there automatically.

To undo the persistent migration, remove `./noctalia.nix` from beast's
imports in the source checkout, push, pull on beast and rebuild. Do not edit
the target's Git checkout over SSH.
