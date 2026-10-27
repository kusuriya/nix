{ pkgs, ... }:
let
  clipboard = pkgs.writeShellScriptBin "sway-clipboard" ''
    set -eu
    umask 077
    dir="''${XDG_RUNTIME_DIR:?}/sway-clipboard"
    mkdir -p "$dir"
    hist() { ${pkgs.cliphist}/bin/cliphist -db-path "$dir/db" -max-items 100 "$@"; }
    case "''${1:-pick}" in
      store)
        # Sensitive hints are best effort; unmarked credentials can be recorded.
        if [ -f "$dir/paused" ] || [ "''${CLIPBOARD_STATE:-}" = sensitive ] || ${pkgs.procps}/bin/pgrep -u "$UID" -x swaylock >/dev/null; then
          ${pkgs.coreutils}/bin/cat >/dev/null
          exit 0
        fi
        hist store
        ;;
      pick|delete)
        action="''${1:-pick}"
        selection=$(hist list | ${pkgs.fuzzel}/bin/fuzzel --dmenu --only-match --no-run-if-empty --with-nth=2 --prompt "Clipboard ($action): ") || exit 0
        [ -n "$selection" ] || exit 0
        if [ "$action" = delete ]; then
          printf '%s\n' "$selection" | hist delete
        else
          printf '%s\n' "$selection" | hist decode | ${pkgs.wl-clipboard}/bin/wl-copy
        fi
        ;;
      pause)
        if [ -f "$dir/paused" ]; then
          rm "$dir/paused"
          ${pkgs.libnotify}/bin/notify-send 'Clipboard history resumed'
        else
          touch "$dir/paused"
          ${pkgs.libnotify}/bin/notify-send 'Clipboard history paused' 'New copies will not be saved.'
        fi
        ;;
      clear)
        hist wipe
        ${pkgs.wl-clipboard}/bin/wl-copy --clear
        ;;
      status|waybar)
        if ! ${pkgs.systemd}/bin/systemctl --user is-active --quiet sway-clipboard.service; then
          state=off
        elif [ -f "$dir/paused" ]; then
          state=paused
        else
          state=recording
        fi
        if [ "$1" = waybar ]; then
          printf '{"text":"Clip: %s","class":"%s","tooltip":"Clipboard history: %s. Left: history; right: pause/resume; middle: delete entry."}\n' "$state" "$state" "$state"
        else
          printf '%s\n' "$state"
        fi
        ;;
      *) exit 2 ;;
    esac
  '';
in
{
  environment.systemPackages = [ clipboard pkgs.cliphist ];
  systemd.user.services.sway-clipboard = {
    description = "Session-only clipboard history";
    wantedBy = [ "sway-session.target" ];
    partOf = [ "sway-session.target" ];
    after = [ "graphical-session-pre.target" ];
    unitConfig.ConditionEnvironment = "WAYLAND_DISPLAY";
    serviceConfig = {
      ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${clipboard}/bin/sway-clipboard store";
      Restart = "on-failure";
      RestartSec = 3;
      RuntimeDirectory = "sway-clipboard";
      RuntimeDirectoryMode = "0700";
      UMask = "0077";
    };
  };
}
