# Hermes Desktop App for NixOS (framey)
#
# Builds the native Electron desktop app from the Hermes Agent source.
# The app connects to a remote Hermes backend via hermes dashboard.
#
# Setup:
#   1. On the backend machine (where your Hermes instance runs):
#        hermes dashboard --no-open --host 0.0.0.0 --port 9119
#      Set auth in ~/.hermes/.env:
#        HERMES_DASHBOARD_BASIC_AUTH_USERNAME=***#        HERMES_DASHBOARD_BASIC_AUTH_PASSWORD=***#        HERMES_DASHBOARD_BASIC_AUTH_SECRET=*** rand -base64 32)
#
#   2. On framey, set the remote URL (replace with your backend IP):
#        HERMES_DESKTOP_REMOTE_URL=http://<backend-ip>:9119 hermes-desktop
#      Or edit defaultRemoteUrl below and rebuild.
#
# First build downloads Electron (~114MB) and packages the app.
{
  lib,
  stdenv,
  pkgs,
  nodejs,
  electron,
}:

let
  # Backend machine (this host — "hermes"). Reachable from framey via Tailscale.
  defaultRemoteUrl = "http://100.81.114.90:9119";

  # Template wrapper — placeholders are replaced in installPhase's substitute step
  wrapperTemplate = ./hermes-desktop-wrapper.sh;

in stdenv.mkDerivation {
  pname = "hermes-desktop";
  version = "0.17.0";

  src = /home/kusuriya/.hermes/hermes-agent;

  nativeBuildInputs = [
    nodejs
    electron
  ];

  # The src is an absolute path to ~/.hermes — pure eval rejects this.
  # Marking the derivation impure allows it to reference the host filesystem.
  __impure = true;
  __noChroot = true;

  buildPhase = ''
    export HOME=$TMPDIR
    export npm_config_cache=$TMPDIR/.npm-cache
    export ELECTRON_CACHE=$TMPDIR/.cache/electron

    cd apps/desktop

    npm install --prefer-offline
    npm run build
    ./node_modules/.bin/electron-builder --linux dir --projectDir .
  '';

  installPhase = ''
    mkdir -p $out/bin $out/share/hermes-desktop $out/share/applications

    if [ -d release/linux-unpacked ]; then
      cp -r release/linux-unpacked/* $out/share/hermes-desktop/
    else
      app_dir_name=$(find release -maxdepth 1 -name "Hermes-*-linux-x64" -type d | head -1)
      if [ -z "$app_dir_name" ]; then
        echo "ERROR: Could not find unpacked app in release/" >&2
        exit 1
      fi
      cp -r "$app_dir_name"/* $out/share/hermes-desktop/
    fi

    app_dir="$out/share/hermes-desktop/resources/app"

    # Install wrapper with placeholders substituted
    substitute ${wrapperTemplate} $out/bin/hermes-desktop \
      --substvar electron_bin "${electron}/bin/electron" \
      --substvar app_dir "$app_dir" \
      --substvar remote_url "${defaultRemoteUrl}"

    # Desktop entry for wofi/menus
    cat > $out/share/applications/hermes-desktop.desktop << EOF
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

  hardeningDisable = [ "fortify" ];

  meta = with lib; {
    description = "Hermes Agent native desktop app for Linux";
    license = licenses.mit;
    platforms = platforms.linux;
    maintainers = [ "kusuriya" ];
    mainProgram = "hermes-desktop";
  };
}
