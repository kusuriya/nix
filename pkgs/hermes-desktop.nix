# Hermes Desktop App for NixOS (framey)
#
# Builds the native Electron desktop app from the Hermes Agent source.
# The app connects to a remote Hermes backend via hermes dashboard.
#
# Setup:
#   1. On the backend machine (where your Hermes instance runs):
#        hermes dashboard --no-open --host 0.0.0.0 --port 9119
#      Set auth in ~/.hermes/.env:
#        HERMES_DASHBOARD_BASIC_AUTH_USERNAME=admin
#        HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=<password>
#        HERMES_DASHBOARD_BASIC_AUTH_SECRET=$(openssl rand -base64 32)
#
#   2. On framey, set the remote URL (replace with your backend IP):
#        HERMES_DESKTOP_REMOTE_URL=http://<backend-ip>:9119 hermes-desktop
#      Or edit defaultRemoteUrl below and rebuild.
#
# First run builds the app (downloads Electron ~114MB), subsequent runs
# use --skip-build for fast launch.
{
  lib,
  stdenv,
  nodejs,
  electron,
}:

let
  # Backend machine (this host — "hermes"). Reachable from framey via Tailscale.
  # Change if your backend moves to a different host or IP.
  defaultRemoteUrl = "http://100.81.114.90:9119";

in stdenv.mkDerivation {
  pname = "hermes-desktop";
  version = "0.17.0";

  src = /home/kusuriya/.hermes/hermes-agent;

  nativeBuildInputs = [
    nodejs
    electron
  ];

  # electron-builder needs network access during build to download Electron
  # and native dependencies. This is fine for `nix build` / `nixos-rebuild`.
  __noChroot = true;

  buildPhase = ''
    export HOME=$TMPDIR
    export npm_config_cache=$TMPDIR/.npm-cache
    export ELECTRON_CACHE=$TMPDIR/.cache/electron

    cd apps/desktop

    # Install dependencies
    npm install --prefer-offline

    # Build TypeScript + Vite renderer
    npm run build

    # Package with electron-builder into unpacked dir
    ./node_modules/.bin/electron-builder --linux dir --projectDir .
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/hermes-desktop $out/share/applications

    # Copy unpacked electron app (electron-builder outputs to release/<name>-linux-x64/)
    # or release/linux-unpacked/ depending on config
    if [ -d release/linux-unpacked ]; then
      cp -r release/linux-unpacked/* $out/share/hermes-desktop/
    else
      # electron-builder names the dir after the productName-version-arch
      app_dir=$(find release -maxdepth 1 -name "Hermes-*-linux-x64" -type d | head -1)
      if [ -z "$app_dir" ]; then
        echo "ERROR: Could not find unpacked app in release/" >&2
        ls -la release/ >&2
        exit 1
      fi
      cp -r "$app_dir"/* $out/share/hermes-desktop/
    fi

    # Wrapper script: sets defaults, then launches electron
    # User can override HERMES_DESKTOP_REMOTE_URL in the shell
    cat > $out/bin/hermes-desktop << 'WRAPPER'
    #!/bin/bash
    export HERMES_DESKTOP_REMOTE_URL="${HERMES_DESKTOP_REMOTE_URL:-http://100.81.114.90:9119}"
    export HERMES_DESKTOP_IGNORE_EXISTING=1
    exec "${electron}/bin/electron" "$out/share/hermes-desktop/resources/app" "$@"
    WRAPPER
    chmod +x $out/bin/hermes-desktop

    # Desktop entry for wofi/menus
    cat > $out/share/applications/hermes-desktop.desktop << 'EOF'
    [Desktop Entry]
    Name=Hermes Desktop
    Comment=Hermes Agent Desktop — connect to a remote Hermes instance
    Exec=$out/bin/hermes-desktop %U
    Icon=hermes
    Type=Application
    Categories=Network;Chat;TerminalEmulator;
    Keywords=hermes;ai;agent;chat;llm;
    StartupWMClass=Hermes
    EOF
  '';

  # Electron needs exec/mmap
  hardeningDisable = [ "fortify" ];

  meta = with lib; {
    description = "Hermes Agent native desktop app for Linux";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ "kusuriya" ];
    mainProgram = "hermes-desktop";
  };
}
