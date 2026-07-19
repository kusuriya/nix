# ============================================================================
# BEAST HOST-SPECIFIC PACKAGES
# ============================================================================
# Gaming/workhorse desktop packages for beast.
# These are NOT installed on other hosts (framey, pve).
#
# Imported by hosts/beast/default.nix via:
#   imports = [ ... ./packages.nix ... ];
# ============================================================================
{ pkgs, pkgs-stable, ... }:
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
      pkgs-stable.bottles # 51.15: unstable 64.1 currently fails via Python 3.14 patool tests
      mcpelauncher-ui-qt # Minecraft Bedrock Edition (unofficial Android launcher)
      gamescope # Steam session compositor — micro-compositor for gaming
      moonlight-qt # Moonlight game/client stream client — low-latency remote desktop

      # ====================================================================
      # GPU / MONITORING
      # ====================================================================
      amdgpu_top # GPU process monitor (AMD)
      radeontop # AMD GPU utilization (terminal)
      vulkan-tools # Vulkan diagnostics (vulkaninfo)
      mesa-demos # OpenGL info (glxinfo) + demos (glxgears)
      v4l-utils # Video4Linux tools — v4l2-ctl for camera detection
      gst_all_1.gstreamer # GStreamer framework
      gst_all_1.gst-plugins-base # GStreamer base plugins
      gst_all_1.gst-plugins-good # GStreamer good plugins
      gst_all_1.gst-plugins-bad # GStreamer bad plugins — vp8enc, rtpvp8pay

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
      python3Packages.pygobject3 # Python GTK bindings — for tray apps
      libayatana-appindicator # AppIndicator library — tray icons in Sway+Waybar
      uv # Fast Python package manager (Rust)
      lazygit # TUI for git — staging hunks, cherry-pick, interactive rebase
      codex # OpenAI Codex CLI — AI coding agent in the terminal
      entr # Lightweight file watcher — `ls *.py | entr pytest`
      watchexec # File watcher — `watchexec -e py -- pytest`
      remmina # Remote desktop client — RDP, VNC, SSH, SPICE
      (freerdp.overrideAttrs (old: {
        cmakeFlags = old.cmakeFlags ++ [ (pkgs.lib.cmakeBool "CHANNEL_RDPECAM_CLIENT" true) ];
      })) # xfreerdp with camera redirection (MS-RDPECAM) — RDP, GRD-compatible

      # ====================================================================
      # AUDIO / VOICE RECORDING
      # ====================================================================
      tenacity # Multi-track audio editor/recorder — voiceovers, podcasting

      # ====================================================================
      # AGENTIC ENGINEERING / DEV TOOLCHAIN
      # ====================================================================
      # The agent is only as reliable as the tools it can reach. This block
      # gives AI coding agents (codex, claude-code, opencode) the surface
      # they need to (1) operate the full dev loop — PRs, builds, tests —
      # and (2) self-verify output before handing it back to a human.
      #
      # python3 + uv are already in DESKTOP / GUI above; direnv is wired
      # through home-manager. Not duplicating any of them.
      gh # GitHub CLI — agents open/list/merge PRs without a human handoff
      claude-code # Anthropic's agentic CLI — third AI lane alongside codex + the VS Code ext
      opencode # OpenCode — Go-based, MCP-native agentic CLI; lightweight alt to claude-code
      nodejs_22 # Node 22 LTS — JS/TS runtime; web tasks, MCP servers, npm tooling
      go # Go toolchain — Go projects + Go-based CLIs (opencode, tfsec, etc.)
      rustup # Rust toolchain manager — preferred over rustc/cargo for multi-version projects
      pipx # Isolated Python CLI installer — keeps global pip clean; safe one-off CLIs for agents
      actionlint # GitHub Actions workflow linter — catches YAML/syntax bugs before CI does
      tflint # Terraform linter — catches provider/version issues in HCL
      devenv # Per-project dev shells — gives agents a reproducible env per repo (direnv-driven)
      hadolint # Dockerfile linter — agents WILL write Dockerfiles; catches issues at write-time
      pi-coding-agent # Mario Zechner's pi — minimal, AGENTS.md-aware, skills/extensions-driven CLI
    ];
  };
}
