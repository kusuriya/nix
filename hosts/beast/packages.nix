# ============================================================================
# BEAST HOST-SPECIFIC PACKAGES
# ============================================================================
# Gaming/workhorse desktop packages for beast.
# These are NOT installed on other hosts (framey, pve).
#
# Imported by hosts/beast/default.nix via:
#   imports = [ ... ./packages.nix ... ];
# ============================================================================
{ config, pkgs, inputs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      # ====================================================================
      # GAMING
      # ====================================================================
      proton-ge-bin         # Custom Proton build for Steam Play (better compatibility)
      lutris               # Game launcher — GOG, Epic, Origin, standalone games
      heroic                # Epic Games + GOG launcher (native Linux)
      bottles               # Wine prefix manager — run Windows games/apps
      mcpelauncher-ui-qt    # Minecraft Bedrock Edition (unofficial Android launcher)
      gamescope             # Steam session compositor — micro-compositor for gaming

      # ====================================================================
      # GPU / MONITORING
      # ====================================================================
      nvtop                # GPU process monitor (NVIDIA)
      glxinfo              # OpenGL info (glxinfo -B for GPU info)
      vulkan-tools         # Vulkan diagnostics (vulkaninfo)
      mesa-demos           # OpenGL demos (glxgears, glxinfo)

      # ====================================================================
      # VIRTUALIZATION (non-passthrough)
      # ====================================================================
      virt-manager          # libvirt GUI — manage VMs (QEMU/KVM)
      virt-viewer          # SPICE/VNC viewer — connect to VM displays
      swtpm                # Software TPM — for Windows 11 VMs
      OVMF                 # UEFI firmware for VMs

      # ====================================================================
      # DESKTOP / GUI
      # ====================================================================
      vscode               # VS Code editor
      vivaldi              # Browser (primary — matches framey's default)
      nemo                 # File manager (Cinnamon's — lightweight GTK)
      unzip                # Archive extraction (common desktop need)
      dig                  # DNS lookup tool
      whois                # WHOIS client
      iotop                # I/O monitoring
      lm_sensors           # Hardware sensors (temperatures, fan speeds)
    ];
  };
}