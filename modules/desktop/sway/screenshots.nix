{ pkgs, ... }:
let
  annotate = pkgs.writeShellScriptBin "sway-annotate" ''
    set -euo pipefail
    # Escape cancels selection without creating a file or opening the editor.
    geometry=$(${pkgs.slurp}/bin/slurp) || exit 0
    [ -n "$geometry" ] || exit 0
    mkdir -p "$HOME/Pictures/Screenshots"
    ${pkgs.grim}/bin/grim -g "$geometry" - | ${pkgs.satty}/bin/satty \
      --filename - \
      --copy-command '${pkgs.wl-clipboard}/bin/wl-copy' \
      --output-filename "$HOME/Pictures/Screenshots/annotated-%Y-%m-%d_%H-%M-%S.png" \
      --actions-on-enter save-to-clipboard \
      --actions-on-escape exit
  '';
in
{
  environment.systemPackages = [ annotate pkgs.satty ];
}
