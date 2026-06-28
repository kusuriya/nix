{ ... }: {
  xdg.mime = {
    enable = true;
    defaultApplications = {
      # Web — URL dispatcher (routes video to Chromium, other to Vivaldi)
      "x-scheme-handler/http" = "url-dispatcher.desktop";
      "x-scheme-handler/https" = "url-dispatcher.desktop";

      # Terminal
      "application/x-terminal-emulator" = "ghostty.desktop";

      # Images — imv (lightweight Wayland image viewer)
      "image/jpeg" = "imv.desktop";
      "image/png" = "imv.desktop";
      "image/webp" = "imv.desktop";
      "image/gif" = "imv.desktop";
      "image/svg+xml" = "imv.desktop";
      "image/bmp" = "imv.desktop";
      "image/tiff" = "imv.desktop";

      # Video / Audio — mpv
      "video/mp4" = "mpv.desktop";
      "video/webm" = "mpv.desktop";
      "video/x-matroska" = "mpv.desktop";
      "audio/mpeg" = "mpv.desktop";
      "audio/ogg" = "mpv.desktop";
      "audio/flac" = "mpv.desktop";

      # PDF — zathura (lightweight, keyboard-driven)
      "application/pdf" = "zathura.desktop";

      # Text — nvim
      "text/plain" = "nvim.desktop";
      "text/markdown" = "nvim.desktop";
    };
  };
}
