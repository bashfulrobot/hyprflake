{ config, lib, pkgs, hyprflakeInputs, ... }:

let
  idle = config.hyprflake.desktop.idle;
in
{
  # DankMaterialShell desktop shell. Replaces the waybar stack (bar,
  # launcher, notifications, OSD, power menu) plus the lock screen and idle
  # daemon. Themed by the Stylix dank-material-shell target (enabled in
  # modules/desktop/stylix). Autostarts via its systemd user service.
  #
  # The shell is a core part of hyprflake and is always enabled — there is no
  # toggle. A toggle would only be warranted if hyprflake supported multiple
  # shells. The idle ladder it consumes (hyprflake.desktop.idle.*) is declared
  # in modules/system/power/idle.nix.

  config = {
    # External-monitor brightness (DDC over I2C) needs the i2c-dev device.
    # Internal-panel brightness goes through logind and needs nothing extra.
    hardware.i2c.enable = true;

    home-manager.sharedModules = [
      hyprflakeInputs.dank-material-shell.homeModules.dank-material-shell
      (_: {
        programs.dank-material-shell = {
          enable = true;

          # Shell built from the dank-material-shell flake input (DMS master /
          # 1.5-beta), not nixpkgs. nixpkgs' dms-shell (1.4.6) ships the
          # pre-Lua dispatch QML: HyprlandService.qml sends legacy
          # `dispatch workspace N` strings, which Hyprland's Lua config
          # evaluates as Lua and rejects, so clicking a workspace and picking
          # a window from the overview both silently fail. Master's
          # HyprlandService.qml emits `hl.dsp.*` Lua-form dispatch and fixes
          # it. The dispatch string is built in this shell package, so only it
          # needs to move; revert to pkgs.dms-shell once the fix is in a
          # tagged release. Quickshell stays on nixpkgs — the DMS flake no
          # longer ships it and points back at nixpkgs' build.
          package = hyprflakeInputs.dank-material-shell.packages.${pkgs.system}.dms-shell;
          quickshell.package = pkgs.quickshell;

          # Autostart via the systemd user service (dms.service ->
          # `dms run --session`). Do NOT also exec-once from Hyprland.
          systemd.enable = true;

          # Stylix owns colors; turn off DMS's wallpaper-driven matugen so
          # the two color engines do not fight. Stylix's dank-material-shell
          # target (modules/desktop/stylix) pins currentThemeName="custom".
          enableDynamicTheming = false;

          # Emoji + unicode picker as a DMS launcher plugin (trigger ":e" in
          # spotlight). Replaces the dropped rofimoji with a DMS-native plugin
          # — pinned via the dms-emoji-launcher flake input, not installed at
          # runtime. SUPER+. opens spotlight pre-filled with the trigger.
          plugins.emojiLauncher = {
            enable = true;
            src = hyprflakeInputs.dms-emoji-launcher;
          };

          settings = {
            # Idle ladder. Mirror AC and battery to the hyprflake.desktop.idle
            # values. Seconds; 0 disables a given listener.
            acLockTimeout = idle.lockTimeout;
            batteryLockTimeout = idle.lockTimeout;
            acMonitorTimeout = idle.dpmsTimeout;
            batteryMonitorTimeout = idle.dpmsTimeout;
            acSuspendTimeout = idle.suspendTimeout;
            batterySuspendTimeout = idle.suspendTimeout;
            lockBeforeSuspend = true;
            loginctlLockIntegration = true;

            # Label each workspace pill in the bar with its Hyprland workspace
            # number (DMS default is icons/dots only).
            showWorkspaceIndex = true;

            # Bar layout. DMS reads barConfigs verbatim when present (its
            # migration only synthesises defaults when the key is absent —
            # SettingsStore.js), so we restate the default bar here and drop
            # the "weather" entry from the center section. Only the identity
            # and widget lists are pinned; every omitted styling field falls
            # back to its upstream `?? default` at the QML read site, so this
            # stays forward-compatible with DMS bar-styling changes.
            barConfigs = [
              {
                id = "default";
                name = "Main Bar";
                enabled = true;
                position = 0;
                screenPreferences = [ "all" ];
                showOnLastDisplay = true;

                # Clean, macOS-menu-bar look: drop the per-widget capsule
                # backgrounds. DMS draws a rounded BasePill behind every widget
                # by default; noBackground flips each pill's fill to transparent
                # and its radius to 0, so widgets render as plain text/icons.
                # The bar strip's own background (barConfig.transparency) is
                # independent and is left untouched.
                noBackground = true;

                # Nudge the panel text up a touch. Every bar widget sizes its
                # text via Theme.barTextSize(barThickness, fontScale, ...) =
                # round(12 * fontScale) at the default bar height, so 1.15
                # takes the ~12px default to 14px. Scales bar text only, not
                # popups/menus (those follow the global fontScale).
                fontScale = 1.15;

                # launcherButton (the app-launcher/menu button) dropped from
                # the leftmost position; left section starts at the workspaces.
                leftWidgets = [ "workspaceSwitcher" "focusedWindow" ];
                centerWidgets = [ "music" "clock" ];
                # Right cluster:
                # - battery: laptop-only. DMS has no separate power-profile
                #   widget — this widget IS the power-profile control (scroll to
                #   switch profiles, click for the battery/profile popout), so
                #   gating it on isLaptop drops both battery readout and the
                #   profile control on desktops. Its charge readout needs UPower,
                #   enabled alongside isLaptop in modules/system/power.
                # - idleInhibitor: click-toggle (coffee/motion icon) that blocks
                #   the idle/lock/DPMS ladder while active.
                # - privacyIndicator: macOS-style alert shown only while the mic,
                #   camera, or screen-share is active; invisible otherwise.
                # Both sit by the control-center button at the right end.
                rightWidgets =
                  [ "systemTray" "clipboard" "cpuUsage" "memUsage" "notificationButton" ]
                  ++ lib.optional config.hyprflake.system.isLaptop "battery"
                  ++ [ "idleInhibitor" "privacyIndicator" "controlCenterButton" ];
              }
            ];
          };
        };
      })

      # DankSearch (dsearch): the dank-native indexed file-search backend the
      # DMS launcher auto-detects. DMS runs `command -v dsearch` and, when
      # present, execs `dsearch search --json` for launcher file search
      # (quickshell/Services/DSearchService.qml); without it the launcher shows
      # "File search requires dsearch". Enabling the module puts `dsearch` on
      # PATH and runs `dsearch serve` as a user service, so no DMS setting
      # selects the backend, it is detected. Always-on, no hyprflake toggle,
      # like the DMS shell itself (DMS-first: prefer the dank-native search
      # server over a standalone indexer). Roll back with
      # `programs.dsearch.enable = lib.mkForce false` (launcher falls back to
      # its built-in path walk) or by dropping the danksearch input.
      hyprflakeInputs.danksearch.homeModules.default
      (_: {
        programs.dsearch = {
          enable = true;

          # Declarative config so dsearch does not write its own default
          # config.toml at first run (the home-manager module only writes the
          # file when `config != null`). index_path is left unset so it defaults
          # to XDG_CACHE_HOME/danksearch (writable state, never the Nix store);
          # only the user's home is indexed (system paths are out of scope).
          # `~` is expanded by dsearch at runtime, so this stays portable across
          # homes (impermanence, non-standard home dirs).
          config = {
            index_paths = [
              {
                path = "~";
                max_depth = 6;
                exclude_hidden = true;
                merge_default_exclude_dirs = true;
              }
            ];
            text_extensions = [
              ".txt"
              ".md"
              ".org"
              ".nix"
              ".go"
              ".py"
              ".js"
              ".ts"
              ".jsx"
              ".tsx"
              ".json"
              ".yaml"
              ".yml"
              ".toml"
              ".html"
              ".css"
              ".scss"
              ".rs"
              ".c"
              ".cpp"
              ".h"
              ".hpp"
              ".java"
              ".kt"
              ".rb"
              ".php"
              ".sh"
              ".fish"
              ".lua"
            ];
          };
        };
      })
    ];
  };
}
