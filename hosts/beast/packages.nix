# ============================================================================
# BEAST HOST-SPECIFIC PACKAGES
# ============================================================================
# Gaming/workhorse desktop packages for beast.
# These are NOT installed on other hosts (framey, pve).
#
# Imported by hosts/beast/default.nix via:
#   imports = [ ... ./packages.nix ... ];
# ============================================================================
{ pkgs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      # ====================================================================
      # GAMING
      # ====================================================================
      # proton-ge-bin is in programs.steam.extraCompatPackages instead
      # (installing it globally causes buildEnv man-paths merge to fail)
      scx.full # sched-ext CPU scheduler — scx_lavd as default (runtime-switchable)
      lutris # Game launcher — GOG, Epic, Origin, standalone games
      heroic # Epic Games + GOG launcher (native Linux)
      bottles # Wine prefix manager — run Windows games/apps
      mcpelauncher-ui-qt # Minecraft Bedrock Edition (unofficial Android launcher)
      gamescope # Steam session compositor — micro-compositor for gaming

      # ====================================================================
      # GPU / MONITORING
      # ====================================================================
      amdgpu_top # GPU process monitor (AMD)
      radeontop # AMD GPU utilization (terminal)
      vulkan-tools # Vulkan diagnostics (vulkaninfo)
      mesa-demos # OpenGL info (glxinfo) + demos (glxgears)

      # ====================================================================
      # VIRTUALIZATION (non-passthrough)
      # ====================================================================
      virt-manager # libvirt GUI — manage VMs (QEMU/KVM)
      virt-viewer # SPICE/VNC viewer — connect to VM displays
      swtpm # Software TPM — for Windows 11 VMs
      OVMF # UEFI firmware for VMs

      # ====================================================================
      # DESKTOP / GUI
      # ====================================================================
      vscode # VS Code editor
      (chromium.override {
        enableWideVine = true;
      }) # Chromium — daily driver, dev tools (Widevine DRM enabled)
      vivaldi # Browser (primary — matches framey's default)
      hermes-desktop # Hermes Desktop — nixpkgs electron wrapper
      obsidian # Note-taking / knowledge base
      discord # Communities, dev servers
      element-desktop # Matrix client — encrypted messaging
      signal-desktop # Secure messaging
      nemo # File manager (Cinnamon's — lightweight GTK)
      unzip # Archive extraction (common desktop need)
      dig # DNS lookup tool
      whois # WHOIS client
      iotop # I/O monitoring
      lm_sensors # Hardware sensors (temperatures, fan speeds)
      python3 # Python 3 with pip
      uv # Fast Python package manager (Rust)
      lazygit # TUI for git — staging hunks, cherry-pick, interactive rebase
      entr # Lightweight file watcher — `ls *.py | entr pytest`
      watchexec # File watcher — `watchexec -e py -- pytest`
      remmina # Remote desktop client — RDP, VNC, SSH, SPICE
    ];
  };
}
