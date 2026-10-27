#!/usr/bin/env bash
# Reversible user-session trial; do not edit the target checkout to deploy it.
set -euo pipefail
root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
trial="${XDG_STATE_HOME:-$HOME/.local/state}/noctalia-trial"
# SSH shells do not inherit the graphical session's socket/display. Read only
# the required keys from its manager; never eval the full environment.
while IFS= read -r entry; do
  case "$entry" in
    SWAYSOCK=*|WAYLAND_DISPLAY=*|XDG_RUNTIME_DIR=*|DBUS_SESSION_BUS_ADDRESS=*) export "$entry" ;;
  esac
done < <(systemctl --user show-environment)
: "${SWAYSOCK:?No active Sway session}" "${WAYLAND_DISPLAY:?No Wayland display}"
units=(sway-waybar.service sway-network-applet.service sway-bluetooth-applet.service)
mkdir -p "$trial"
restore() {
  systemctl --user stop noctalia-clipboard-status-trial.service 2>/dev/null || true
  systemctl --user stop noctalia-trial.service 2>/dev/null || true
  if [[ -f "$trial/previous-units" ]]; then
    while IFS= read -r unit; do
      [[ -z "$unit" ]] || systemctl --user start "$unit"
    done < "$trial/previous-units"
  fi
  # Remove trial-only shortcuts by reloading the still-managed Sway config.
  swaymsg reload >/dev/null
}
if [[ ${1:-} == --stop ]]; then
  restore
  exit
fi
host=$(hostname)
case "$host" in
  beast|framey) ;;
  *) printf 'This trial is scoped to beast and framey.\n' >&2; exit 1 ;;
esac
if systemctl --user is-active --quiet noctalia.service || systemctl --user is-active --quiet noctalia-trial.service; then
  printf 'Noctalia is already running; stop that instance first.\n' >&2
  exit 1
fi
# A path flake retains this checkout's intentionally untracked existing lock;
# git+file would ignore it and resolve every input anew. Do not update it here.
nix build --no-write-lock-file \
  --option extra-substituters https://noctalia.cachix.org \
  --option extra-trusted-public-keys 'noctalia.cachix.org-1:pCOR47nnMEo5thcxNDtzWpOxNFQsBRglJzxWPp3dkU4=' \
  "path:$root#nixosConfigurations.$host.config.system.build.noctalia-trial" \
  --out-link "$trial/bundle"
bundle=$(readlink -f "$trial/bundle")
mkdir -p "$trial/config/noctalia" "$trial/state"
ln -sfn "$bundle/config.toml" "$trial/config/noctalia/config.toml"
export NOCTALIA_CONFIG_HOME="$trial/config"
export NOCTALIA_STATE_HOME="$trial/state"
: > "$trial/previous-units"
for unit in "${units[@]}"; do
  if systemctl --user is-active --quiet "$unit"; then
    printf '%s\n' "$unit" >> "$trial/previous-units"
  fi
done
trap restore ERR
systemctl --user stop "${units[@]}"
systemd-run --user --collect --unit=noctalia-trial \
  --property=PartOf=graphical-session.target --property=Restart=on-failure \
  --setenv="NOCTALIA_CONFIG_HOME=$NOCTALIA_CONFIG_HOME" \
  --setenv="NOCTALIA_STATE_HOME=$NOCTALIA_STATE_HOME" \
  --setenv="PATH=$bundle/tools:$PATH" "$bundle/bin/noctalia"
ready=false
for ((i=0; i<30; i++)); do
  if "$bundle/bin/noctalia" msg config-get bar.main.enabled >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 1
done
[[ "$ready" == true ]]
systemd-run --user --collect --unit=noctalia-clipboard-status-trial \
  --property=PartOf=graphical-session.target --property=Restart=on-failure \
  --setenv="NOCTALIA_CONFIG_HOME=$NOCTALIA_CONFIG_HOME" \
  --setenv="NOCTALIA_STATE_HOME=$NOCTALIA_STATE_HOME" "$bundle/clipboard-status"
swaymsg "bindsym Mod4+Ctrl+n exec $bundle/bin/noctalia msg panel-toggle control-center" >/dev/null
swaymsg "bindsym Mod4+Ctrl+a exec $bundle/bin/noctalia msg panel-toggle control-center audio" >/dev/null
"$bundle/bin/noctalia" msg panel-open control-center audio
printf '\nNoctalia trial running. Mod+Ctrl+N: control center; Mod+Ctrl+A: audio.\n'
printf 'Restore previous applets/bar: bash %q --stop\n' "$root/modules/desktop/sway/noctalia-trial.sh"
