{ pkgs, ... }:
pkgs.writeShellScriptBin "url-dispatcher" ''
  # URL Dispatcher — routes video links to Chromium, everything else to Vivaldi
  #
  # To add/remove a video site:
  #   Edit the SITES list below. Each entry is a grep -E pattern.
  #   Rebuild with `just switch`.
  #
  # Example patterns:
  #   youtube.com/watch    — specific YouTube video pages
  #   youtu.be             — YouTube short links
  #   twitch.tv            — Twitch streams
  #   vimeo.com            — Vimeo videos
  #   netflix.com          — Netflix
  #   nebula.tv            — Nebula

  SITES="youtube.com/watch|youtu.be|twitch.tv|vimeo.com|netflix.com|nebula.tv"

  url="$1"
  if echo "$url" | grep -qE "$SITES"; then
    exec chromium "$url"
  else
    exec vivaldi "$url"
  fi
''
