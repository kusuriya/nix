#!/usr/bin/env bash
# Keep the original rollback command working for already-running beast trials.
set -euo pipefail
root=$(git -C "$(dirname "$0")" rev-parse --show-toplevel)
exec bash "$root/modules/desktop/sway/noctalia-trial.sh" "$@"
