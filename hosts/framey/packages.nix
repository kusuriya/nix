# ============================================================================
# FRAMEY HOST-SPECIFIC PACKAGES
# ============================================================================
# Desktop/laptop packages for framey (Framework 13 AMD laptop).
# These are NOT installed on other hosts (beast, wusc063016, pve).
#
# This file is imported by /data/nix/hosts/framey/default.nix via:
#   imports = [ ... ./packages.nix ... ];
# ============================================================================
{ pkgs, inputs, ... }:
{
  environment = {
    systemPackages = with pkgs; [
      hermes-desktop # Hermes Desktop — nixpkgs electron wrapper, CLI via curl install

      # ============================================================================
      # SECRETS & PASSWORD MANAGEMENT (GUI/advanced — host-specific)
      # ============================================================================

      rage # Rust age implementation — drop-in compatible, faster
      gopass # Go password manager — pass-compatible, better UX + search
      pass # Unix password store — GPG-based, CLI-native, git-syncable
      agebox # Encrypt specific files in a repo while keeping structure — git-crypt with age

      # ============================================================================
      # SHELL & TERMINAL (desktop/laptop only)
      # ============================================================================

      neovim # Primary editor (with Neovim config)
      zellij # Terminal multiplexer (Rust, sane defaults, layouts)
      ghostty # GPU-accelerated terminal emulator (Mitchell Hashimoto)
      alacritty # GPU-accelerated terminal emulator (Rust, minimal)
      mosh # Mobile shell — robust SSH for flaky connections
      wev # Wayland event viewer — debug key/button events
      slurp # Wayland region selector — for screenshots/screen capture

      # ============================================================================
      # DEVELOPMENT — LANGUAGES & COMPILERS (desktop only)
      # ============================================================================

      clang # LLVM C/C++ compiler — alternate toolchain
      zig # Zig language — also useful as C/C++ build toolchain
      lua-language-server # Lua LSP — for Neovim plugin development, Lua scripting
      pyright # Python LSP — type checking, autocompletion (PEP 8)
      unstable.arrow-cpp # Apache Arrow — columnar data processing (Python/C++ interop)

      # ============================================================================
      # DEVELOPMENT — TOOLS (desktop/laptop only)
      # ============================================================================

      lazygit # TUI for git — staging hunks, cherry-pick, interactive rebase
      tig # Text-mode git repo viewer — fast commit graph, blame, tree browser
      gh # GitHub CLI — PR/issue/repo ops, auth, API scripting, gists
      claude-code # Anthropic Claude Code CLI — AI coding assistant
      claude-agent-acp # Claude Agent ACP transport — for Hermes delegation (renamed from claude-code-acp)
      claude-mergetool # Claude-powered merge conflict resolver
      fnm # Fast Node version manager — Rust, instant switching. Better than nvm
      python3 # Python 3 with pip
      uv # Fast Python package manager (Rust)

      # ============================================================================
      # DEVELOPMENT — CONVENIENCE (desktop only)
      # ============================================================================

      # just is now in modules/core/packages.nix — universal
      watchexec # File watcher — `watchexec -e py -- pytest` reruns on save
      entr # Lightweight file watcher — `ls *.py | entr pytest`. Simpler than watchexec
      mdcat # Markdown renderer (alternate) — different style than glow
      pastel # Color toolkit — convert, sample, analyze colors from CLI. Useful for theming

      # ============================================================================
      # VIRTUALIZATION & CONTAINERS (desktop/laptop only)
      # ============================================================================

      virt-manager # libvirt GUI — manage VMs (QEMU/KVM)
      virt-viewer # SPICE/VNC viewer — connect to VM displays (deduped)
      spice-gtk # SPICE client library — VM display support
      gnome-boxes # GNOME VM manager — simplified libvirt frontend
      swtpm # Software TPM — for VMs needing TPM (Windows 11, etc.)
      (OVMF.override {
        tpmSupport = true;
        secureBoot = true;
        msVarsTemplate = true;
        httpSupport = true;
        tlsSupport = true;
      }) # UEFI firmware for QEMU VMs — TPM, SecureBoot, HTTP/TLS enabled

      # ============================================================================
      # NETWORKING & VPN (desktop/laptop only)
      # ============================================================================

      wireguard-ui # WireGuard GUI manager
      wireguard-tools # wg, wg-quick — WireGuard CLI
      openconnect # Cisco AnyConnect-compatible VPN client
      dnsmasq # DNS/DHCP server — local DNS, VM networking, ad-blocking

      # ============================================================================
      # HTTP & NETWORK DIAGNOSTICS (advanced — desktop only)
      # ============================================================================

      xh # Friendly HTTP client — `xh POST api.example.com/json key=value`
      httpie # Classic friendly HTTP client — more plugins/eco than xh but slower
      # doggo is now in modules/core/packages.nix — universal
      mtr # traceroute + ping combined, real-time — network diagnostics
      gping # Ping with live graph — `gping 8.8.8.8 1.1.1.1` side by side
      socat # Network swiss army knife — port forwards, unix sockets, relays
      bandwhich # TUI showing per-process network bandwidth — who's eating network

      # ============================================================================
      # PROCESS & SYSTEM MONITORING (advanced TUIs — desktop only)
      # ============================================================================

      btop # Beautiful htop replacement — GPU monitoring, mouse, themes
      procs # Better ps — colorful, multi-column, easy filtering
      bottom # Rust system monitor — graphs, widgets, customizable TUI. Alt to btop
      glances # Python system monitor — web UI mode, extensive plugin system

      # ============================================================================
      # CONTAINER & IMAGE TOOLS (desktop only)
      # ============================================================================

      lazydocker # TUI for docker — containers, logs, volumes, images
      dive # Docker image layer explorer — wasted space, efficiency score
      trivy # Container/IaC vulnerability scanner — images, fs, K8s manifests
      grype # Container vuln scanning — pairs with syft for SBOM
      syft # SBOM generation — software bill of materials from images/dirs

      # ============================================================================
      # SECURITY (WEB APP + CLOUD — desktop only)
      # ============================================================================

      burpsuite # Web proxy — interception, scanning, replay (primary sec tool)
      remmina # RDP/VNC/SPICE/SSH client — tabbed sessions, credential manager
      nmap # Network scanner — port discovery, service detection, NSE scripts
      nuclei # Template-based web scanner — pairs with httpx for recon→scan
      subfinder # Passive subdomain enumeration — recon pipeline with httpx
      ffuf # Content/param fuzzing — CLI fuzzer for scripting and automation
      naabu # Fast port scanner — cleaner output than nmap, good for recon
      dalfox # XSS scanner — CLI, pipeable, good for automation pipelines
      wafw00f # WAF detection — identify WAFs before running other tools
      hashcat # GPU hash cracking — offline password recovery
      gobuster # Directory/vhost brute-forcing — alternative to ffuf, different modes
      amass # Attack surface mapping — subdomain enum, DNS, cert parsing
      sqlmap # SQL injection automation — classic, still useful for quick checks
      nikto # Web server scanner — legacy but catches low-hanging fruit
      masscan # Fast port scanner — 10K+ ports/sec. Pairs with nmap for deep scan

      # ============================================================================
      # WAYLAND / SWAY (WINDOW MANAGER — desktop only)
      # ============================================================================

      swaybg # Wayland wallpaper utility
      swayidle # Idle management — lock/screen-off on inactivity
      swaylock # Screen locker for Wayland
      kanshi # Wayland output auto-config — display profiles on hotplug
      sway-contrib.grimshot # Screenshots for Sway (grim + slurp wrapper)

      # ============================================================================
      # GRAPHICS & DISPLAY (desktop/laptop only)
      # ============================================================================

      mesa # OpenGL/Vulkan Mesa drivers — open-source GPU stack
      mesa-demos # OpenGL test utilities — glxinfo, glxgears
      libva # Video Acceleration API — hardware video decode/encode
      libva-utils # vainfo — check VA-API support
      vulkan-tools # vulkaninfo, vkcube — Vulkan diagnostics
      vulkan-validation-layers # Vulkan debug validation — GPU driver/correctness checks
      virglrenderer # VirtIO GPU renderer — 3D accel for QEMU VMs

      # ============================================================================
      # BROWSERS (desktop only)
      # ============================================================================

      (chromium.override {
        enableWideVine = true;
      }) # Chromium — daily driver, dev tools (Widevine DRM enabled)
      vivaldi # Vivaldi — power-user browser, tabs/panels
      zathura # PDF viewer — lightweight, keyboard-driven, Wayland-native

      # ============================================================================
      # COMMUNICATION (desktop only)
      # ============================================================================

      discord # Discord — communities, dev servers
      signal-desktop # Signal — E2E private messaging
      slack # Slack — work comms (Bayer)
      telegram-desktop # Telegram — personal/messaging
      zoom-us # Zoom — work video calls
      weechat # IRC client — terminal, scriptable, extensible
      element-desktop # Matrix client — Element desktop

      # ============================================================================
      # GUI APPLICATIONS — PRODUCTIVITY (desktop only)
      # ============================================================================

      obsidian # Knowledge base — personal vault, Hermes docs, daily notes
      libreoffice # Office suite — docs, spreadsheets, presentations
      drawio # Diagramming — architecture, flowcharts, network diagrams
      inkscape # Vector graphics editor — SVG, logos, diagrams

      # ============================================================================
      # GUI APPLICATIONS — MEDIA & 3D (desktop only)
      # ============================================================================

      freecad # 3D CAD — parametric mechanical design
      makemkv # DVD/Blu-ray ripper — decrypt and remux discs
      handbrake # Video transcoder — compress/convert video files
      imagemagick # Image manipulation — convert, resize, batch ops
      yt-dlp # Video/audio downloader — YouTube and 1000+ sites
      chafa # Terminal image viewer — `chafa image.png` shows images in terminal
      viu # Rust terminal image viewer — good for PNG/GIF in terminal

      # ============================================================================
      # GUI APPLICATIONS — UTILITIES (desktop only)
      # ============================================================================

      transmission_4-qt # BitTorrent client — Transmission 4.x Qt UI
      parsec-bin # Remote desktop — low-latency game streaming
      moonlight-qt # Sunshine/Moonlight client — self-hosted remote desktop
      unstable.looking-glass-client
      # Looking Glass — VM framebuffer passthrough (near-native display)
      catt # Chromecast CLI — cast media to Chromecast devices
      via # VIA keyboard config — QMK firmware visual editor
      rclone # Cloud storage sync — Google Drive, S3, Backblaze, etc.
      rsync # File sync — local/remote incremental transfer
      btrfs-progs # Btrfs filesystem utilities — subvolumes, snapshots, scrub
      btrbk # Btrfs snapshot automation — btrbk tool for managed snapshots
      timeshift # System restore — RSYNC/BTRFS snapshots for rollback

      # ============================================================================
      # SYNCTHING (FILE SYNC — desktop only)
      # ============================================================================

      syncthing # Decentralized file sync — peer-to-peer, no cloud
      syncthingtray # Syncthing tray icon — status, open WebUI

      # ============================================================================
      # BLUETOOTH (desktop/laptop only)
      # ============================================================================

      blueman # Bluetooth manager — GUI for BlueZ

      # ============================================================================
      # SPELL CHECKING (desktop only)
      # ============================================================================

      (aspellWithDicts (
        dicts: with dicts; [
          en # English dictionary
          en-computers # English computer/tech terms
          en-science # English scientific terms
        ]
      ))

      # ============================================================================
      # APPIMAGE / APPFORMATS / NFS (desktop only)
      # ============================================================================

      appimage-run # Run AppImage bundles — pre-built portable Linux apps
      nfs-utils # NFS client/server — network filesystem mounts

    ];
  };
}
