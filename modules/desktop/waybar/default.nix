{ pkgs, config, lib, ... }:

let
  cfg = config.hyprflake.desktop.waybar;
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };

  # Baseline window-rewrite map for common applications. Merged with the
  # user-supplied `rewrites` option at config time (user values win on key
  # collisions), so consumers can extend without restating defaults.
  defaultWorkspaceRewrites = {
    "class<[Ff]irefox>" = "";
    "class<librewolf>" = "";
    "class<zen>" = "";
    "class<[Cc]hromium>" = "";
    "class<[Gg]oogle-chrome>" = "";
    "class<Brave-browser>" = "";
    "class<kitty>" = "";
    "class<Alacritty>" = "";
    "class<foot>" = "";
    "class<org.wezfurlong.wezterm>" = "";
    "class<com.mitchellh.ghostty>" = "";
    "class<[Cc]ode>" = "󰨞";
    "class<VSCodium>" = "󰨞";
    "class<jetbrains-.*>" = "";
    "class<[Dd]iscord>" = "󰙯";
    "class<Slack>" = "󰒱";
    "class<[Ss]potify>" = "";
    "class<thunderbird>" = "";
    "class<obsidian>" = "";
    "class<org.telegram.desktop>" = "";
    "class<Signal>" = "󰭹";
    "class<pavucontrol>" = "";
    "class<pwvucontrol>" = "";
    "class<blueman-manager>" = "󰂯";
    "class<org.gnome.Nautilus>" = "";
    "class<thunar>" = "";
    "class<org.kde.dolphin>" = "";
    "class<1Password>" = "󰌾";
    "class<Claude>" = "󰚩";
    "class<Todoist>" = "";
    "class<[Cc]ursor>" = "";
    "title<.*[Yy]ou[Tt]ube.*>" = "";
    "title<.*[Gg]it[Hh]ub.*>" = "";
  };

  effectiveWorkspaceRewrites =
    (lib.optionalAttrs cfg.workspaceAppIcons.includeDefaultRewrites defaultWorkspaceRewrites)
    // cfg.workspaceAppIcons.rewrites;
in
{
  options.hyprflake.desktop.waybar = {
    enable = lib.mkEnableOption "Waybar status bar" // { default = true; };

    workspaceAppIcons = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        example = false;
        description = ''
          Render application icons within each Hyprland workspace indicator
          using Waybar's `window-rewrite` feature. Icons are Nerd Font glyphs
          matched against window class or title.
        '';
      };

      format = lib.mkOption {
        type = lib.types.str;
        default = "{name} {windows}";
        example = "{icon} {windows}";
        description = ''
          Format string for workspace buttons when app icons are enabled.
          Supports Waybar placeholders: `{id}`, `{name}`, `{icon}`, `{windows}`.
        '';
      };

      defaultIcon = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "";
        description = ''
          Fallback glyph rendered for windows that do not match any entry in
          `rewrites`. Set to an empty string to render nothing for unmatched
          windows.
        '';
      };

      includeDefaultRewrites = lib.mkOption {
        type = lib.types.bool;
        default = true;
        example = false;
        description = ''
          Whether to include hyprflake's baked-in `rewrites` baseline (Firefox,
          Chromium, Kitty, VS Code, Discord, Slack, etc.). Set to `false` to
          start from an empty map and define every rewrite yourself.
        '';
      };

      rewrites = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = lib.literalExpression ''
          {
            "class<firefox>" = "";
            "class<kitty>" = "";
            "title<.*github.*>" = "";
          }
        '';
        description = ''
          Extensions/overrides for the `window-rewrite` map. Keys use Waybar's
          matcher syntax, e.g. `class<regex>`, `title<regex>`, or both
          space-separated. Values are the glyph (typically Nerd Font) rendered
          for matching windows.

          When `includeDefaultRewrites = true` these entries are concatenated
          onto hyprflake's baseline via `//`, so colliding keys here override
          the baseline and non-colliding baseline entries still apply. Set a
          value to an empty string to suppress rendering for a matched window
          without dropping the entry.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Waybar status bar for Hyprland
    # Configured via home-manager sharedModules to apply to all users
    # Fonts are automatically configured by Stylix (stylix.targets.waybar.font = "monospace")

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
            height = 28;
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

            # Signal handlers for waybar-auto-hide
            on-sigusr1 = "hide";
            on-sigusr2 = "show";

            modules-left = [ "hyprland/workspaces" ];
            modules-center = [ "hyprland/submap" "clock" ];
            modules-right = (lib.optionals config.hyprflake.desktop.voxtype.enable [ "custom/voxtype" ])
              ++ (lib.optionals (builtins.pathExists /sys/class/power_supply) [ "idle_inhibitor#alert" "battery#alert" ])
              ++ [ "custom/recording" "custom/notification" "group/system-info" "custom/power" ];

            "group/system-info" = {
              orientation = "inherit";
              drawer = {
                transition-duration = 500;
                children-class = "system-drawer";
                transition-left-to-right = false;
              };
              modules = [ "custom/system-gear" ]
                ++ (lib.optionals (builtins.pathExists /sys/class/power_supply) [ "idle_inhibitor" ])
                ++ (lib.optionals (config.hyprflake.system.power.profilesBackend == "power-profiles-daemon") [ "power-profiles-daemon" ])
                ++ [ "network" "bluetooth" "pulseaudio" ]
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
                notification = "<span foreground='red'>󰂚</span>";
                none = "";
                dnd-notification = "<span foreground='red'>󰂛</span>";
                dnd-none = "<span foreground='red' font_size='6pt'>●</span>";
              };
              return-type = "json";
              exec-if = "which swaync-client";
              exec = "swaync-client -swb";
              on-click = "swaync-client -t -sw";
              on-click-right = "swaync-client -d -sw";
              escape = true;
            };

            "custom/voxtype" = {
              exec = "voxtype status --follow --format json";
              return-type = "json";
              format = "{icon}";
              format-icons = {
                idle = "";
                recording = "󰍬";
                transcribing = "󰓆";
                stopped = "";
              };
              tooltip = true;
              on-click = "systemctl --user restart voxtype";
            };

            "custom/recording" = {
              return-type = "json";
              interval = 2;
              exec = "pgrep -x wf-recorder > /dev/null && echo '{\"text\": \"⏺\", \"class\": \"recording\", \"tooltip\": \"Recording in progress\"}' || echo '{\"text\": \"\", \"class\": \"\"}'";
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
              format =
                if cfg.workspaceAppIcons.enable
                then cfg.workspaceAppIcons.format
                else "{icon}";
            } // lib.optionalAttrs cfg.workspaceAppIcons.enable {
              window-rewrite-default = cfg.workspaceAppIcons.defaultIcon;
              window-rewrite = effectiveWorkspaceRewrites;
            };

            "idle_inhibitor" = {
              format = "{icon}";
              format-icons = {
                activated = "󰥔";
                deactivated = "󰶐";
              };
              tooltip-format = "Idle Inhibitor: {status}";
            };

            "idle_inhibitor#alert" = {
              format = "{icon}";
              format-icons = {
                activated = "󰥔";
                deactivated = "";
              };
              tooltip-format = "Idle Inhibitor: {status}";
            };

            "power-profiles-daemon" = {
              format = "{icon}";
              format-icons = {
                default = "";
                performance = "󰓅";
                balanced = "󰾅";
                power-saver = "󰾆";
              };
              tooltip-format = "Power Profile: {profile}\nDriver: {driver}\n\nClick to cycle profiles";
              on-click = "powerprofilesctl set $(powerprofilesctl list | grep -v $(powerprofilesctl get) | head -n1)";
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

            "network" = {
              format-wifi = "{icon}";
              format-ethernet = "󰈀";
              format-disconnected = "󰤮";
              format-icons = [ "󰤯" "󰤟" "󰤢" "󰤥" "󰤨" ];
              tooltip-format-wifi = "{essid} ({signalStrength}%)\n⇣{bandwidthDownBytes} ⇡{bandwidthUpBytes}";
              tooltip-format-ethernet = "{ifname}: {ipaddr}\n⇣{bandwidthDownBytes} ⇡{bandwidthUpBytes}";
              tooltip-format-disconnected = "Disconnected";
              on-click = "rofi-network-manager &";
              interval = 5;
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
              on-click-right = "pamixer -t";
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
              tooltip-format = "{capacity}% • {power:.1f}W";
              interval = 10;
            };

            "battery#alert" = {
              states = {
                warning = 25;
                critical = 15;
              };
              format = "";
              format-warning = "{icon}";
              format-critical = "{icon}";
              format-icons = [ "󰂎" "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
              tooltip-format = "Battery Low: {capacity}%";
              interval = 10;
            };

            "tray" = {
              icon-size = 16;
              spacing = 16;
            };

            "custom/power" = {
              format = "⏻";
              on-click = "wlogout -b 3 -c 60 -r 60";
              tooltip-format = "Power Options";
            };
          }];

          # Import styling from separate file (keeps GTK theming variables)
          # Uses Stylix helper for consistent pattern
          style = stylix.mkStyle ./style.nix;
        };
      })
    ];
  };
}

