# Beast Config Gap Analysis

**Goal:** Identify all gaps, inconsistencies, stale docs, and missing config in beast's NixOS configuration.

**Method:** Exhaustive cross-reference of every imported module (core, sway, sysctl, btrfs-snapshots, dozer-mounts, virtualization, rd560, hardware-configuration, disko, packages) + upstream nixos-hardware modules (common-cpu-amd, common-pc-ssd) + home-manager + install/post-install scripts + README.

---

## 🚨 HIGH — Functional Impact

### H1. Stale README: documents NVIDIA RTX 3060, actually has AMD Radeon RX 9070 XT

**Files:**
- `hosts/beast/README.md`
- `hosts/beast/post-install.sh`

**Evidence:** README sections "GPU Configuration" (lines 43-48), "Post-Install: Verify NVIDIA" (lines 212-217) prescribe NVIDIA-specific steps (`nvidia-smi`, `hardware.nvidia.open`, `hardware.nvidia.modesetting`). The actual config has zero `hardware.nvidia` references and correctly uses `hardware.amdgpu` instead. Post-install script step 5 also tries to verify NVIDIA.

**Fix:** Rewrite the GPU section to describe AMD RX 9070 XT (RDNA 4) config. Update post-install.sh to verify AMD GPU instead of NVIDIA.

### H2. Swapfile not activated on boot — missing NixOS swapDevices

**Files:** `hosts/beast/default.nix`

**Evidence:** README describes a 16GB swapfile created manually via `btrfs filesystem mkswapfile --size 16G /.swapvol/swapfile` and stored in `/.swapvol/swapfile`. Post-install.sh creates it (step 3, line 62-69). But there is **no `swapDevices`** entry anywhere in beast's NixOS config. The swapfile is usable in the session where it's created but will NOT be activated after reboot.

Contrast: framey handles this in `disko.nix` (line 124: `swap.swapfile.size = "96G"`) inside the subvolume definition, which generates the correct `swapDevices` automatically. Beast's disko.nix has no swap definition.

**Fix:** Add to `hosts/beast/default.nix`:
```nix
swapDevices = [{ device = "/.swapvol/swapfile"; }];
```

### H3. `system.stateVersion` at "23.05" — 3+ year old defaults

**File:** `hosts/beast/default.nix` (line 345)

**Evidence:** `system.stateVersion = "23.05"` means NixOS generates config files using 23.05-era defaults. Since 26.05, many defaults have changed: systemd-initrd (the one we just enabled), network config (`useNetworkd`), udev rules, etc. Some deprecated options may still be in use because stateVersion keeps old behaviour.

The comment says "Do not change on a rebuild" — this is correct guidance for avoiding config regeneration issues. But the gap between declared version and actual nixpkgs channel could eventually cause breakage.

**Fix:** Not urgent — follow the standard upgrade path (increment stateVersion one major at a time). For now, note it.

---

## 🟡 MEDIUM — Operational Risk

### M1. Plymouth + amdgpu RDNA 4 compatibility unverified

**Files:** `hosts/beast/default.nix` (line 95: `boot.plymouth.enable = true`)

**Evidence:** Plymouth with RDNA 4 (RX 9070 XT) has known upstream issues — flickering on some firmware versions, needing `amdgpu.dcdebugmask=0x10` kernel parameter. This isn't a gap per se, but should be tested. If beast boots to a Plymouth splash, great. If the screen flickers or Plymouth fails, this kernel param is the workaround.

**Risk level:** Low — worst case Plymouth doesn't render and boot messages show instead. System still boots fine.

### M2. `hardware.amdgpu.opencl.enable` — ROCm on RDNA 4 not verified

**Files:** `hosts/beast/default.nix` (line 109)

**Evidence:** Enables ROCm OpenCL stack. RDNA 4 support in ROCm was a late addition and may not be fully functional in the current nixpkgs-unstable. CL applications (Blender, DaVinci Resolve, LLM inference via ROCm) may or may not detect the GPU.

**Fix:** Verify with `clinfo` after build. If ROCm doesn't detect the 9070 XT, this may need a newer ROCm version or kernel patch.

### M3. Printer device URI is a placeholder

**Files:** `pkgs/rd560/default.nix` (line 35)

**Evidence:** `deviceUri = "usb://Labelrange/RD560"` — no serial number. This works for auto-detection but may not find the printer if multiple USB label printers or if the USB topology changes. The comment (line 29) acknowledges this.

**Fix:** Run `lpinfo -v` on beast after connecting the printer, update with the real URI.

### M4. No `kernel.panic` alignment with hardware watchdog

**Files:**
- `hosts/beast/default.nix` (line 72: `RuntimeWatchdogSec = "30s"`)
- `modules/desktop/sysctl/default.nix` (line 40: `kernel.panic = 60`)

**Evidence:** The hardware watchdog will reboot after 30s of hang. The kernel panic timeout is 60s. If the kernel panics, the watchdog timeout of 30s will fire before the 60s panic timeout, causing a hard reset during the panic (losing the panic log). Either lower kernel.panic to match (< 30s) or raise the watchdog.

Minor — the watchdog only fires on systemd hang, not kernel panic. They're independent paths. But `kernel.panic = 30` would be more aligned if the intent is "reboot fast."

---

## 🔵 LOW — Cleanup / Documentation

### L1. `services.fstrim.enable` duplicate

**Files:**
- `hosts/beast/default.nix` (line 236-238)
- `inputs.hardware.nixosModules.common-pc-ssd` (sets it to `lib.mkDefault true`)

**Evidence:** `common-pc-ssd` already sets `services.fstrim.enable = lib.mkDefault true`. Beast's explicit `enable = true` is redundant. Not harmful, but unnecessary.

**Fix:** Remove lines 236-238 from beast's default.nix.

### L2. Install script references "NVIDIA driver"

**Files:** `hosts/beast/post-install.sh` (line 86-94)

**Evidence:** Step 5 runs `nvidia-smi` to verify NVIDIA. Should verify AMD GPU instead.

**Fix:** Replace step 5 with AMD verification: `amdgpu_top`, `glxinfo | grep "OpenGL renderer"`, or `lsmod | grep amdgpu`.

### L3. No `nixos-anywhere` support for rd560/labelrange driver persistence

**Files:** `hosts/beast/install.sh`

**Evidence:** The driver for the LabelRange RD560 is a local package (`../../pkgs/rd560`). If fresh-installing via nixos-anywhere, the package needs to be in a form the installer can access. The install script handles local clones correctly so this is likely fine — just worth noting.

---

## 📋 Summary Table

| # | Area | Severity | Status |
|---|------|----------|--------|
| H1 | README documents wrong GPU | 🔴 HIGH | Needs rewrite |
| H2 | Swapfile not activated on boot | 🔴 HIGH | Needs swapDevices |
| H3 | stateVersion 23.05 | 🔴 HIGH | Monitor, upgrade path |
| M1 | Plymouth + RDNA 4 untested | 🟡 MEDIUM | Verify on next build |
| M2 | ROCm on RDNA 4 unverified | 🟡 MEDIUM | Verify with clinfo |
| M3 | Printer URI placeholder | 🟡 MEDIUM | Update from lpinfo -v |
| M4 | Watchdog/panic timeout mismatch | 🟡 MEDIUM | Consider aligning |
| L1 | fstrim duplicate | 🔵 LOW | Remove redundant block |
| L2 | Post-install verifies NVIDIA | 🔵 LOW | Update to AMD check |
| L3 | Local package on fresh install | 🔵 LOW | Verify once |

---

## Known Goods (no issues found)

- ✅ `boot.initrd.systemd.enable = true` — just migrated, working
- ✅ systemd-boot with configuration limit
- ✅ AppArmor enabled with killUnconfinedConfinables
- ✅ Auditd enabled
- ✅ Kernel hardening sysctls (kptr_restrict, dmesg_restrict, perf_event_paranoid, etc.)
- ✅ TCP BBR with fq qdisc
- ✅ scx_lavd scheduler at boot
- ✅ KVM nesting enabled (hardware-configuration.nix)
- ✅ Samba share with tmpfiles directory creation
- ✅ OVMF firmware paths for libvirt VMs
- ✅ QEMU security wrapper (cap_net_admin)
- ✅ Sway + greetd + Wayland config
- ✅ NFS automounts from dozer
- ✅ btrbk hourly snapshots
- ✅ btrfs monthly autoScrub
- ✅ 1Password GUI + CLI with polkit
- ✅ Steam with proton-ge-bin
- ✅ Waydroid explicitly disabled
- ✅ JACK audio support (pipewire)
- ✅ corectrl enabled (AMD GPU control)
- ✅ Tailscale as client
- ✅ Avahi/mDNS with browse domains
- ✅ Polkit rules for shutdown/reboot without password
- ✅ Podman with docker compat
