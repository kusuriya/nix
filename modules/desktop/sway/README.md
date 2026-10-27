# Shared Sway desktop

Both beast and framey import this directory. No host-local Sway/UWSM or
Noctalia imports are needed. The shared stack includes:

- `uwsm.nix`: greetd starts Sway through UWSM; Sway finalizes its socket and
  display environment, then the graphical session starts supervised services.
  Terminal/launcher/startup apps launch through `uwsm app`; logout uses UWSM.
- `noctalia.nix`: Noctalia 5.4.0 bar and unified audio/network/Bluetooth
  controls replace Waybar, nm-applet and blueman-applet. Control Center drops
  down from the **top-right**, attached to the top bar, regardless of cursor.
- `clipboard.nix`: session-only cliphist with pause/resume/delete/clear and
  a live Noctalia button reporting **off / recording / paused** from the
  capture service. Left: history; right: pause/resume; middle: delete entry.
- `screenshots.nix`: region capture and Satty annotation.
- `../gaming`: common gaming tools and integration.

Fuzzel, swaync (Mod+N), Kanshi, wallpaper, swaylock/swayidle, Polkit,
screenshot bindings and media keys retain their existing owners. Noctalia's
clipboard capture, lock/idle handling and external app theme templates are
explicitly disabled. Hardware, monitor profiles and laptop power policies
are not changed by this migration.

## Reversible Noctalia trial without sudo or logout

Push changes to GitHub first, then on either host:

```sh
cd ~/nix
git pull --ff-only
bash modules/desktop/sway/noctalia-trial.sh
```

The script chooses the local hostname (`beast` or `framey`), builds and
validates that host's config, stops the existing bar/applets, and runs
transient services with isolated state in `~/.local/state/noctalia-trial`.
It does not activate Home Manager, switch the system, or migrate the live
compositor to UWSM. It opens the audio panel.

- Mod+Ctrl+N: unified control center
- Mod+Ctrl+A: audio controls

Restore the previously active services and original shortcuts:

```sh
bash ~/nix/modules/desktop/sway/noctalia-trial.sh --stop
```

The original `hosts/beast/noctalia-trial.sh` command remains a compatibility
wrapper. If Waybar was already stopped before the trial, restore it with
`systemctl --user start sway-waybar.service` if desired.

## Persistent activation

Stop any trial first to avoid duplicate Noctalia instances, then rebuild
with the local hostname and existing lock (currently intentionally ignored
by this repository):

```sh
bash ~/nix/modules/desktop/sway/noctalia-trial.sh --stop
sudo nixos-rebuild switch --flake "path:$HOME/nix#$(hostname)" \
  --option extra-substituters https://noctalia.cachix.org \
  --option extra-trusted-public-keys 'noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4='
```

**Framey needs a fresh login after its first switch** so UWSM, not the old
Sway wrapper, owns the session. Save work before switching; greetd changes
can affect the login/session service. Do not treat a running Noctalia trial
as proof of UWSM login/logout behavior.

After login check `systemctl --user status noctalia
noctalia-clipboard-status sway-clipboard` and `systemctl --user
show-environment` for `SWAYSOCK` and `WAYLAND_DISPLAY`. Check only one bar is
running, test launcher, portals, lock/suspend/resume, and logout separately.

GUI settings in `~/.local/state/noctalia/settings.toml` override base config;
the trial's isolated state is not copied there automatically.

To undo persistently, revert the shared migration in the source checkout,
push, pull on the target and rebuild. Do not edit target Git checkouts over
SSH. Build/evaluation and source synchronization are not system activation.

## External monitor brightness (DDC/CI)

The shared module enables `brightness.enable_ddcutil`, installs `ddcutil`,
loads `i2c-dev`, and uses NixOS's active-seat I²C uaccess rules. No extra
brightness daemon or global i2c group membership is required. Noctalia's
supervised service and trial both have an explicit path to `ddcutil`.

The hardware/udev prerequisites require a system switch, unlike the
unprivileged shell trial. Enable DDC/CI in each monitor's own on-screen menu
if necessary. As the logged-in desktop user, check `ddcutil detect` and
`ddcutil --display N getvcp 10` for a detected display number before trying
the brightness slider. Docks/adapters and some monitors may not pass DDC.
The laptop's internal backlight continues using the normal backlight API.

## Regression evaluation

From the repository root:

```sh
nix eval --impure --json --expr \
  'import ./tests/shared-sway.nix { flake = builtins.getFlake ("path:" + toString ./.); }'
```

This asserts both hosts' UWSM ownership, session service activation, disabled
legacy applets/autostarts, shared Sway config, upper-right Control Center,
clipboard indicator, shortcuts and preservation of external service owners.
