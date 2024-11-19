{ config, lib, pkgs, ... }:
{
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;
    style = ''
      * {
        font-family: "JetBrains Mono Nerd Font";
        font-size: 13px;
        min-height: 0;
      }

      window#waybar {
        background: @base;
        color: @text;
        border-radius: 0px;
      }

      tooltip {
        background: @surface0;
        border: 1px solid @pink;
      }

      #workspaces button {
        padding: 0 5px;
        color: @text;
      }

      #workspaces button.active {
        color: @pink;
      }

      #workspaces button.urgent {
        color: @red;
      }

      #clock,
      #battery,
      #cpu,
      #memory,
      #disk,
      #temperature,
      #network,
      #pulseaudio,
      #wireplumber,
      #power-profiles-daemon
      #tray,
      #mode,
      #idle_inhibitor {
        padding: 0 10px;
        color: @text;
        border-radius: 8px;
        margin: 5px 0px;
      }
    '';
    settings = [{
      layer = "top";
      position = "top";
      height = 30;
      spacing = 4;
      modules-left = [
        "privacy"
        "hyprland/workspaces"
        "hyprland/window"
      ];
      modules-center = [
        "clock"
      ];
      modules-right = [
        "wireplumber"
        "power-profiles-daemon"
	"network"
        "battery"
        "tray"
      ];
      "hyprland/workspaces" = {
        format = "{icon}";
        on-click = "activate";
        format-icons = {
          "1" = "";
          "2" = "";
          "3" = "";
          "4" = "";
          "5" = "";
          urgent = "";
          active = "";
          default = "";
        };
        sort-by-number = true;
      };
      clock = {
        format = " {:%H:%M}";
        format-alt = " {:%Y-%m-%d}";
        tooltip-format = "<big>{:%Y %B}</big>\n<tt>{calendar}</tt>";
      };
      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon} {capacity}%";
        format-charging = "󰂄 {capacity}%";
        format-plugged = "󱘖 {capacity}%";
        format-icons = ["󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹"];
      };
      network = {
        format-wifi = "󰤨 {essid}";
        format-ethernet = "󰈀 {ipaddr}";
        format-linked = "󰈀 {ifname} (No IP)";
        format-disconnected = "󰤭 Disconnected";
        tooltip-format = "{ifname} via {gwaddr}";
      };
      wireplumber = {
        format = "{icon} {volume}%";
        format-muted = "󰝟";
        format-icons = ["󰕿" "󰖀" "󰕾"];
        on-click = "pavucontrol";
      };
      tray = {
        icon-size = 21;
        spacing = 10;
      };
      "idle_inhibitor" = {
        format = "{icon}";
        format-icons = {
          activated = "󰅶";    # Icon when idle inhibitor is active
          deactivated = "󰾪";  # Icon when idle inhibitor is inactive
        };
        tooltip = true;
        tooltip-format-activated = "Idle Inhibitor Active";
        tooltip-format-deactivated = "Idle Inhibitor Inactive";
      };
      "privacy" = {
        format = "{icon}";
        format-icons = {
          screenshare = "󰍹";
          audio-in = "󰍬";
          audio-out = "󰓃";
        };
        tooltip = true;
        tooltip-format = "{icon} {name}";
      };
    }];
  };

  # Required dependencies
  home.packages = with pkgs; [
    wireplumber
    waybar
    power-profiles-daemon
    pamixer # For volume control
    pavucontrol # GUI audio control
  ];
}
