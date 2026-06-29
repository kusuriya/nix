{ pkgs, ... }:
pkgs.writeShellScriptBin "sway-session" ''
  max_attempts=5
  attempt=0
  delay=1

  while [ "$attempt" -lt "$max_attempts" ]; do
    attempt=$((attempt + 1))
    ${pkgs.sway}/bin/sway
    exit_code=$?

    if [ "$attempt" -lt "$max_attempts" ]; then
      sleep "$delay"
      [ "$delay" -lt 30 ] && delay=$((delay * 2))
    fi
  done

  echo "sway: exited $max_attempts times (last exit code: $exit_code) — giving up"
  echo "sway: fix the config and log in again"
''
