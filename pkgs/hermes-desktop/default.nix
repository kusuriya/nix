# ~/nix/pkgs/hermes-desktop/default.nix
#
# Hermes Desktop wrapper — launches the Hermes desktop Electron app using
# nixpkgs' electron (NixOS rpath-patched) pointed at the curl-installed
# Hermes source.  The agent CLI comes from the curl install, not from Nix,
# so `hermes update` works in seconds.
#
# Prerequisites (run once before first use):
#   curl -fsSL https://hermes-agent.nousresearch.com/install.sh \
#     | bash -s -- --include-desktop
#
# This clones ~/.hermes/hermes-agent/, builds the desktop renderer, and
# installs the `hermes` CLI to ~/.local/bin/hermes.
{
  lib,
  stdenv,
  makeWrapper,
  electron,
  ...
}:

stdenv.mkDerivation {
  pname = "hermes-desktop";
  version = "0.17.0";

  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    # Wrap nixpkgs' Electron pointed at the curl-installed desktop source.
    # The electron process reads package.json → electron/main.cjs which
    # resolves dist/, build/native-deps/, etc. relative to its own location.
    makeWrapper ${lib.getExe electron} $out/bin/hermes-desktop \
      --add-flags "$HOME/.hermes/hermes-agent/apps/desktop" \
      --set HERMES_DESKTOP_HERMES "$HOME/.local/bin/hermes" \
      --set ELECTRON_IS_DEV 0 \
      --set XCURSOR_SIZE 24 \
      --run 'if [ ! -d "$HOME/.hermes/hermes-agent/apps/desktop/dist" ]; then
        echo "Hermes desktop source not found or not built."
        echo "Run: curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash -s -- --include-desktop"
        exit 1
      fi'

    runHook postInstall
  '';

  meta = with lib; {
    description = "Hermes Desktop — nixpkgs Electron wrapper for curl-installed Hermes";
    homepage = "https://github.com/NousResearch/hermes-agent";
    license = licenses.mit;
    platforms = platforms.linux;
    mainProgram = "hermes-desktop";
  };
}
