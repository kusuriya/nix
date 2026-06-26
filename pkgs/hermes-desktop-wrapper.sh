#!/bin/bash
# Hermes Desktop wrapper — remote URL may be overridden at launch time
export HERMES_DESKTOP_REMOTE_URL="${HERMES_DESKTOP_REMOTE_URL:-@remote_url@}"
export HERMES_DESKTOP_IGNORE_EXISTING=1
exec @electron_bin@ @app_dir@ "$@"
