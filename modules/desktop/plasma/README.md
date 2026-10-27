# Plasma 6 + gaming

Import this directory in a NixOS host to enable Plasma 6 (KDE 6) on Wayland
with SDDM and a ready-to-configure gaming stack:

```nix
imports = [
  ../../modules/desktop/plasma
];
```

Replace the host's `../../modules/desktop/sway` import rather than adding this
beside it: that module enables greetd/autologin, which conflicts with SDDM.
No existing host is switched by adding this module. Stage/add these new files
before building a Git-backed flake; Nix ignores untracked files in such flakes.

## Included

- Plasma's upstream KDE applications: Dolphin, Konsole, Kate, Ark, Spectacle,
  System Settings, KWallet, KDE portals and Qt/GTK integration.
- SDDM with a Wayland greeter and Plasma Wayland as the default session.
- NetworkManager, Bluetooth and PipeWire (PulseAudio and 32-bit ALSA support).
- Steam, Steam Input's Wayland bridge, Steam controller udev rules,
  GE-Proton registered as a compatibility tool, and Protontricks.
- GameMode (normal user accounts added to its authorised group), Gamescope,
  MangoHud/GOverlay; Steam and Lutris runtimes include overlay/GameMode tools.
- Lutris, Heroic (Epic/GOG), Wine Staging, Winetricks and Moonlight client.
- Vulkan/OpenGL diagnostics (`vulkaninfo`, `glxinfo`).
- KDE Connect application, without automatically opening firewall ports.

Both Plasma and Sway import the shared `../gaming` module. It can also be
imported independently as `../../modules/desktop/gaming`.

## Host-owned choices

There is no autologin or hard-coded username, GPU vendor/driver, kernel,
CPU scheduler, overclock, global performance governor or global overlay.
Keep NVIDIA/PRIME configuration in the hardware/host module; AMD/Intel use
NixOS's normal Mesa stack. HDR/VRR and display settings are chosen in Plasma,
not forced globally. Games' anti-cheat compatibility is not fixed by a module.

Steam's unfree packages are permitted through a narrow default predicate;
this does not grant blanket unfree permission. Existing host policies win.
Firewall ports for Steam streaming, transfers and game servers stay closed.
On a trusted network a host may opt in:

```nix
programs.steam.remotePlay.openFirewall = true;
programs.steam.localNetworkGameTransfers.openFirewall = true;
# Opens KDE Connect's TCP/UDP 1714–1764 on all firewall interfaces:
programs.kdeconnect.enable = true;
```

For an optional Steam Big Picture login session:

```nix
programs.steam.gamescopeSession.enable = true;
```

Use per-game Steam launch options as needed (not every game likes overlays):

```text
gamemoderun mangohud %command%
gamescope -f -- %command%
```

Select GE-Proton in a game's Steam Properties → Compatibility when needed;
installing it does not force every game to use it. Heroic/Lutris can download
and select their own game-specific runners.

Most service toggles are defaults and can be overridden normally at the host.
Package lists merge; `programs.steam.enable = false` disables Steam but does
not remove the other launchers in this gaming profile.

If migrating an existing Sway host, also review host-local wlr portals and
Home Manager's Sway-specific autostarts/themes. This module intentionally does
not edit those, migrate user preferences or force-disable other desktops.
Build the target first, then switch explicitly; do not assume import changes
alone prove the actual GPU, controller, HDR or games work.
