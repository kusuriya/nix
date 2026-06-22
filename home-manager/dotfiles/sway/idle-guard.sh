#!/bin/sh
# idle-guard.sh — skip idle actions when external monitors are connected
# Usage: idle-guard.sh <command...>
#
# Checks if more than 1 sway output is enabled (external monitors connected).
# If so, the command is skipped (exit 0) — no lock, screen off, or suspend.
# Otherwise, the command is executed normally.

output_count=$(swaymsg -t get_outputs 2>/dev/null | grep -c '"enabled": true')

if [ "$output_count" -gt 1 ]; then
    exit 0
fi

exec "$@"