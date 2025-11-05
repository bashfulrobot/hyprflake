{ pkgs, config, lib, ... }:

let
  stylix = import ../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  # Waybar status bar for Hyprland
  # Configured via home-manager sharedModules to apply to all users

  fonts.packages = [ pkgs.nerd-fonts.jetbrains-mono ];

  home-manager.sharedModules = [
    (_: {
      programs.waybar = {
        enable = true;
        systemd = {
          enable = true;
          target = "graphical-session.target";
        };
        package = pkgs.waybar;

        settings = [{
          layer = "top";
          position = "top";
          mode = "dock";
          exclusive = true;
          passthrough = false;
          gtk-layer-shell = true;
          ipc = true;
          fixed-center = true;
          margin-top = 0;
          margin-left = 0;
          margin-right = 0;
          margin-bottom = 0;

          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/submap" "custom/notification" "clock" ];
          modules-right = [ "group/system-info" "custom/power" ];

          "group/system-info" = {
            orientation = "inherit";
            drawer = {
              transition-duration = 500;
              children-class = "system-drawer";
              transition-left-to-right = false;
            };
            modules = [ "custom/system-gear" "idle_inhibitor" "bluetooth" "pulseaudio" ]
                      ++ (lib.optionals (builtins.pathExists /sys/class/power_supply) [ "battery" ])
                      ++ [ "tray" ];
          };

          "custom/system-gear" = {
            format = "⚙";
            interval = "once";
            tooltip = false;
          };

          "custom/notification" = {
            tooltip = false;
            format = "{icon}";
            format-icons = {
              notification = "<span foreground='red'><sup></sup></span>";
              none = "";
              dnd-notification = "<span foreground='red'><sup></sup></span>";
              dnd-none = "";
            };
            return-type = "json";
            exec-if = "which swaync-client";
            exec = "swaync-client -swb";
            on-click = "swaync-client -t -sw";
            on-click-right = "swaync-client -d -sw";
            escape = true;
          };

          "hyprland/submap" = {
            format = "{}";
            tooltip = false;
          };

          "hyprland/workspaces" = {
            all-outputs = true;
            active-only = false;
            on-click = "activate";
            show-special = false;
            format = "{icon} {windows}";
            format-window-separator = " ";
            window-rewrite-default = "";
            window-rewrite = {
              "1Password" = "󰌾";
              "Chromium" = "";
              "Code" = "󰨞";
              "VSCodium" = "󰨞";
              "kitty" = "";
              "nautilus" = "󰉋";
              "firefox" = "󰈹";
              "Spotify" = "";
              "Signal" = "󰍡";
              "discord" = "󰙯";
            };
          };

          "idle_inhibitor" = {
            format = "{icon}";
            format-icons = {
              activated = "󰥔";
              deactivated = "";
            };
          };

          "clock" = {
            format = "{:%H:%M}";
            format-alt = "{:%a %d %b %H:%M}";
            tooltip-format = "<tt>{calendar}</tt>";
            calendar = {
              mode = "month";
              mode-mon-col = 3;
              on-scroll = 1;
              on-click-right = "mode";
            };
          };

          "bluetooth" = {
            format = "{icon}";
            format-icons = {
              enabled = "󰂯";
              disabled = "󰂲";
            };
            format-connected = "󰂱";
            tooltip-format = "{controller_alias}";
            on-click = "blueman-manager &";
            on-click-right = "rfkill toggle bluetooth";
          };

          "pulseaudio" = {
            format = "{icon}";
            format-muted = "󰝟";
            format-icons = {
              headphone = "󰋋";
              headset = "󰋎";
              default = [ "󰕿" "󰖀" "󰕾" ];
            };
            scroll-step = 5;
            on-click = "pwvucontrol &";
            on-scroll-up = "pamixer -i 5";
            on-scroll-down = "pamixer -d 5";
            tooltip-format = "Volume: {volume}%";
            max-volume = 150;
          };

          "battery" = {
            states = {
              good = 95;
              warning = 30;
              critical = 20;
            };
            format = "{icon}";
            format-alt = "{icon} {capacity}%";
            format-charging = " {capacity}%";
            format-plugged = " {capacity}%";
            format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
            tooltip-format = "Battery: {capacity}%";
          };

          "tray" = {
            icon-size = 16;
            spacing = 16;
          };

          "custom/power" = {
            format = "";
            on-click = "wlogout -b 4";
            tooltip-format = "Power Options";
          };
        }];

        # Import styling from separate file (keeps GTK theming variables)
        # Uses Stylix helper for consistent pattern
        style = stylix.mkStyle ./style.nix;
      };
    })
  ];
}
