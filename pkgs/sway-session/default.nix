{ pkgs, ... }:
pkgs.writeShellScriptBin "sway-session" ''
  while true; do
    ${pkgs.sway}/bin/sway
    sleep 1
  done
''
