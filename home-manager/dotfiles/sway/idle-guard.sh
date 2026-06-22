#!/bin/sh
# idle-guard.sh — skip lock/screen-off when docked (AC power + external monitors)
# Usage: idle-guard.sh <command...>
#
# Checks two conditions:
#   1. On AC power (any /sys/class/power_supply/AC*/online = 1)
#   2. External monitors connected (more than 1 enabled sway output)
#
# If both are true, the command is skipped (exit 0).
# Otherwise, the command is executed normally.

# Check if on AC power
on_ac=false
for ac in /sys/class/power_supply/AC*/online; do
    if [ "$(cat "$ac" 2>/dev/null)" = "1" ]; then
        on_ac=true
        break
    fi
done

# Check if external monitors are connected (more than 1 enabled output)
external=false
output_count=$(swaymsg -t get_outputs 2>/dev/null | grep -c '"enabled": true')
if [ "$output_count" -gt 1 ]; then
    external=true
fi

# If docked (AC + external monitors), skip the command
if "$on_ac" && "$external"; then
    exit 0
fi

# Otherwise, execute the command
exec "$@"