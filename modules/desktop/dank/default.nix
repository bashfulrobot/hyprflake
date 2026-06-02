{ config, pkgs, hyprflakeInputs, ... }:

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

          # Prebuilt from nixpkgs — avoids the flake's from-source build of
          # the shell and Quickshell.
          package = pkgs.dms-shell;
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
                leftWidgets = [ "launcherButton" "workspaceSwitcher" "focusedWindow" ];
                centerWidgets = [ "music" "clock" ];
                rightWidgets = [ "systemTray" "clipboard" "cpuUsage" "memUsage" "notificationButton" "battery" "controlCenterButton" ];
              }
            ];
          };
        };
      })
    ];
  };
}
