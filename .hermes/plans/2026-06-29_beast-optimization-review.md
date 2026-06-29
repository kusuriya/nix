# Beast Config: Exhaustive Review & Optimization

**Date:** 2026-06-29  
**Method:** SSH to beast (192.168.1.149) + full config chain audit  
**Rule:** No changes — review only, waiting for your approval.

---

## 1. HARDWARE REALITY VS CONFIG

| Component | Actual | Config says | Match? |
|-----------|--------|-------------|--------|
| **CPU** | AMD Ryzen 9 3950X (16C/32T) | `kvm-amd` kernel module ✓ | ✅ |
| **GPU** | AMD Radeon RX 9070 XT (Navi 48) | `hardware.amdgpu` settings ✓ | ✅ |
| **Motherboard** | Gigabyte X570 AORUS MASTER | No specific module | Could add `nixos-hardware` for Gigabyte/X570 |
| **RAM** | 31 GiB (4×8 GiB approx.) | No explicit setting | Fine, detected automatically |
| **NVMe 1** | Sabrent Rocket 4.0 1TB (nvme0n1) | disko.nix ✓ | ✅ Boot + NixOS |
| **NVMe 2** | SHPP41-1000GM (nvme1n1) | disko.nix mentions post-install add | ⚠️ **Not added to btrfs pool** |
| **NVMe 3** | SHPP41-1000GM (nvme2n1) | Reserved for Windows | ✅ Untouched |
| **Network** | enp8s0 (2.5GbE), enp7s0 (2.5GbE), wlp6s0 (WiFi) | NetworkManager managed | ✅ |
| **Bluetooth** | Intel AX200? (hci0 issue) | `hardware.bluetooth.enable = true` | ⚠️ hci0 config fails |
| **Firmware** | BIOS F37c (2023-03-23), X570 AORUS MASTER | `boot.loader.systemd-boot` ✓ | ✅ |

---

## 2. CRITICAL ISSUES

### 🔴 C1: No swap — systemd-oomd degraded

**Evidence (live system):**
```
$ swapon --show
# empty — no swap
$ journalctl -p warning:
systemd-oomd[1063]: No swap; memory pressure usage will be degraded
```

**Impact:** systemd-oomd explicitly warns that without swap, memory pressure management is degraded. The configured OOM policies (`ManagedOOMMemoryPressure = "kill"` at 99%) rely on swap pressure metrics. Without swap, OOM decisions are less effective.

**Root cause:** The swapfile at `/.swapvol/swapfile` was never created. The post-install.sh was never run after initial installation (or it ran but the swapfile creation failed). My `swapDevices` config change is correct but the file must exist.

**Fix options:**
- Option A: Use `size = 16384` (MiB) in swapDevices — NixOS creates the swapfile automatically via `mkswap-*.service`
- Option B: Manually create the swapfile: `sudo btrfs filesystem mkswapfile --size 16G /.swapvol/swapfile`

### 🔴 C2: Generation is 28.1 GiB — very large

**Evidence:** `nix path-info -Sh /run/current-system` → 28.1 GiB. Typical NixOS desktop with Steam is ~5-8 GiB.

**Impact:** Slower rebuilds, more disk space, larger GC roots. This affects every `nixos-rebuild switch`.

**Likely contributors (in order of impact):**
1. **Chromium with WideVine** — ~1-2 GiB (packages.nix line 46)
2. **Steam + proton-ge-bin** — ~5-8 GiB (default.nix lines 308-313)
3. **Vivaldi** — ~1 GiB (packages.nix line 49)
4. **Obsidian** — ~1 GiB (Electron) (packages.nix line 51)
5. **Discord** — ~500 MiB (Electron) (packages.nix line 52)
6. **Element + Signal** — ~1 GiB each (Electron) (packages.nix lines 53-54)
7. **Hermes Desktop** — ~500 MiB (Electron) (packages.nix line 50)
8. **AMD ROCm OpenCL** — ~2-3 GiB (default.nix line 109)
9. **CUPS printer drivers** — hplipWithPlugin + gutenprint + canon-cups-ufr2 = ~2 GB
10. **Neovim with python/ruby/node** — ruby + nodejs + python deps (home-manager)
11. **libvirtd + qemu_full + OVMF + swtpm** — ~2-4 GiB

**Fix options:**
- Trim Electron duplicates (do you regularly use all of Discord, Element, Signal, and Obsidian? Some could be demoted to flathub)
- Remove chromium if vivaldi is the primary browser (both installed)
- The packages.nix has `python3` and `uv` — `python3` is already part of the system via nixpkgs, the explicit package likely adds pip

---

## 3. SERVICE ISSUES

### 🟡 S1: keyd service failing

**Evidence:**
```
× keyd.service - Failed with result 'start-limit-hit'
ExecStart=.../keyd (code=exited, status=255/EXCEPTION)
```

**Root cause:** keyd is trying to remap keyboard keys but is failing at runtime (exit code 255 with exception). This could be because:
- No keyboard connected during the headless boot
- Permission issue accessing `/dev/uinput` 
- Conflict with the Kinesis Adv360 Pro (which has its own firmware remapping)

**Impact:** Service tries to restart 5 times, fails, generates errors. Wastes boot time.

**Fix options:**
- Investigate `journalctl -u keyd -o cat` for the actual exception message
- If keyd isn't needed (Kinesis does all remapping in firmware), remove `services.keyd.enable = true`

### 🟡 S2: Printer service failing

**Evidence:**
```
cupsd[2375]: Unable to open ".../labelrange/RD560.ppd" - No such file or directory
systemd[1]: Failed to start Ensure NixOS-configured CUPS printers.
```

**Root cause:** The LabelRange RD560 PPD file path in `pkgs/rd560/default.nix` doesn't match what the package actually produces. The `model = "labelrange/RD560.ppd"` path is wrong.

**Impact:** CUPS printer setup fails every boot. The EPSON ET-2800 is actually present and working (separate manual setup), so this only affects the label printer.

**Fix:** Check the actual PPD path produced by the labelrange-rd560 package and fix the model path.

### 🟡 S3: No display running (greetd active, no Sway)

**Evidence:** greetd is running but `swaymsg` reports "sway not running". The session was started at boot (PAM session opened for kusuriya) but Sway didn't stay up.

**Impact:** Beast booted to a tty/black screen rather than a Sway desktop. If this is intended (headless/gaming machine controlled via SSH), then greetd is unnecessary overhead.

**Fix options:**
- If **headless/SSH-only**: remove greetd, sway, and all display-related packages from beast
- If **should have desktop**: investigate why Sway exits immediately

---

## 4. CONFIG OPTIMIZATIONS

### 🔵 O1: `max-jobs = 32` may be too aggressive

**File:** `modules/core/nix.nix` (line 7)

**Current:** `max-jobs = "auto"` — on 32-thread 3950X, this resolves to 32 parallel build jobs.

**Issue:** 32 concurrent builds on a machine with 31 GiB RAM can cause severe memory pressure. Each build job can use 1-2 GiB of RAM. 32 × 1.5 GiB = 48 GiB theoretical max, far exceeding available RAM. This causes swapping or OOM kills during large rebuilds.

**Fix:** Cap to 16 (physical cores) or 8 for safety:
```nix
max-jobs = 8;
```
Or keep auto but add:
```nix
extra-sandbox-paths = [ ];
build-cores = 16;
```

### 🔵 O2: Redundant browser — chromium + vivaldi

**File:** `hosts/beast/packages.nix` (lines 46-49)

**Current:** Both Chromium (with WideVine) and Vivaldi installed.

**Vivaldi is Chromium-based** and includes WideVine DRM already. The Chromium package is redundant unless you specifically need a separate Chromium profile.

**Fix:** Remove the chromium override from packages.nix if vivaldi is the primary browser.

### 🔵 O3: Flatpak enabled but empty

**File:** `hosts/beast/default.nix` (line 197)

**Current:** `services.flatpak.enable = true`. No flatpaks installed (empty list).

**Impact:** Flatpak adds its own services, repo config, and dependency graph (~500 MiB+ in the closure) with zero benefit when no flatpaks are installed.

**Fix:** Disable flatpak unless you plan to use it. Electron apps (Discord, Obsidian, etc.) are already native packages — they don't need flatpak.

### 🔵 O4: Tailscale service running but logged out

**Evidence:** `tailscaled.service` is running, `tailscale status` says "Logged out."

**Impact:** The service runs but has zero functionality. Uses ~50 MiB RAM doing nothing.

**Fix:** Either authenticate with `sudo tailscale up` on beast, or remove `services.tailscale.enable = true` from `default.nix` until you're ready to use it.

### 🔵 O5: Printer driver bloat

**Files:** `hosts/beast/default.nix` (lines 250-257) + `pkgs/rd560/default.nix`

**Current:** Three printer driver packages: `gutenprint` (generic), `hplipWithPlugin` (HP), `canon-cups-ufr2` (Canon) + LabelRange RD560 driver.

**hplipWithPlugin** is particularly large (~500 MiB+) because it includes the proprietary HP plugin. If you don't regularly print from beast, these add closure size with no benefit.

**EPSON ET-2800** is actually configured on the system (shown by `lpstat -p`) but there's no EPSON driver in the config — it must have been added manually.

**Fix:** Audit which printers you actually use from beast and remove unused drivers.

### 🔵 O6: `wpa_supplicant` killed on boot

**Evidence:** `wpa_supplicant.service: Control process exited, code=killed, status=15/TERM`

**Root cause:** wpa_supplicant starts for WiFi (wlp6s0) but there's no WiFi network configured. NetworkManager likely terminates it since it handles networking itself.

**Impact:** Harmless but generates a boot-time error.

**Fix:** None needed — NetworkManager handles this. Can suppress with `systemd.services.wpa_supplicant.enable = false` if the noise bothers you.

### 🔵 O7: usb port power management warning

**Evidence:** `kernel: usb: port power management may be unreliable`

**Root cause:** AM4/X570 chipset USB power management is known to be unreliable. The kernel is warning, but it's informational — USB works fine, just may not suspend properly.

**Fix:** Add `usbcore.autosuspend=-1` to `boot.kernelParams` to disable USB autosuspend. Or ignore it (harmless warning).

### 🔵 O8: `sched_ext` deprecation warning

**Evidence:** `kernel: Writing directly to p->scx.slice/dsq_vtime is deprecated`

**Root cause:** The `scx_lavd` scheduler version in nixpkgs uses a deprecated BPF API. The scx_lavd version is behind the kernel.

**Impact:** Warning only — scheduler runs fine. Will likely be fixed in a future scx update.

---

## 5. DEAD / UNUSED CONFIG

### ⚪ D1: `sched-ext CPU Scheduler` — verify it's effective

**File:** `hosts/beast/default.nix` (lines 320-331)

**Current:** `scx_lavd` is running (service is active). But with the deprecation warning above, it may not be operating optimally.

**Verify:** `scx_lavd --stats 2>/dev/null` or `cat /sys/kernel/debug/sched_ext/stats` if debugfs mounted.

### ⚪ D2: NFS `/dozer/files` mount not verified

**File:** `modules/desktop/dozer-mounts/default.nix`

**Current:** Two NFS mounts: `/data` (verified working — shows content from dozer) and `/dozer/files` (not checked — `ls /dozer/files` wasn't tested).

**Likely:** Both mounts use the same automount pattern, so if `/data` works, `/dozer/files` should too.

---

## 6. SUMMARY TABLE

| # | Issue | Severity | File | Approx. savings |
|---|-------|----------|------|-----------------|
| C1 | No swap → oomd degraded | 🔴 HIGH | `default.nix` (swapDevices) | Reliability fix |
| C2 | 28 GiB generation | 🔴 HIGH | Multiple | 5-20 GiB reduction potential |
| S1 | keyd service failing | 🟡 MED | `default.nix` | Boot time, error noise |
| S2 | Printer PPD path wrong | 🟡 MED | `pkgs/rd560/default.nix` | Boot failure fix |
| S3 | Sway not running | 🟡 MED | `default.nix` + `sway/default.nix` | Depends on usage model |
| O1 | max-jobs=32 too aggressive | 🔵 LOW | `modules/core/nix.nix` | Build stability |
| O2 | Redundant browser (chromium) | 🔵 LOW | `packages.nix` | ~1-2 GiB closure |
| O3 | Flatpak empty | 🔵 LOW | `default.nix` | ~500 MiB closure |
| O4 | Tailscale logged out | 🔵 LOW | `default.nix` | ~50 MiB RAM |
| O5 | Printer driver bloat | 🔵 LOW | `default.nix` + `pkgs/rd560` | ~500 MiB+ closure |
| O6 | wpa_supplicant error | 🔵 LOW | — | Error noise |
| O7 | USB power management warning | 🔵 LOW | — | Harmless |
| O8 | scx_lavd BPF deprecation | 🔵 LOW | — | Will self-fix with update |

---

## 7. Key Actual-vs-Config Discrepancies Found

- **NVMe 2 + 3 partitions** — nvme1n1/nvme2n1 have partition tables (from previous install?), but they haven't been added to the btrfs pool. The post-install.sh step was never completed.
- **CPU is Ryzen 3950X** (16-core, 32-thread) — was previously described as something else in memory but config is correct (`kvm-amd`)
- **EPSON ET-2800 printer** is configured outside of Nix — not in the config, was added manually
- **Vivaldi is installed and works** — `vivaldi 8.0.4033.50` confirmed working
- **Chromium also installed** — `Chromium 149.0.7827.196`
