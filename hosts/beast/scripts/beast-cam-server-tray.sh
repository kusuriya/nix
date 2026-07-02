#!/usr/bin/env bash
# beast-cam-server-tray.sh — Wrapper to run beast-cam-server-tray.py with nix-shell deps
# NixOS python3 doesn't automatically add system-package Python modules to sys.path.
# This wrapper uses nix-shell to set PYTHONPATH, GI_TYPELIB_PATH, and LD_LIBRARY_PATH.
set -euo pipefail

SCRIPT="/data/work/beast-cam-server-tray.py"

DEPS=(
    python3Packages.pygobject3
    libayatana-appindicator
    gtk3                          # Gtk-3.0 typelib — needed by gi.repository.Gtk
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
)

exec nix-shell -p "${DEPS[@]}" --run "python3 $SCRIPT"
