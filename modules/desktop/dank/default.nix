{ config, lib, pkgs, hyprflakeInputs, ... }:

let
  cfg = config.hyprflake.desktop.dank;
  idle = config.hyprflake.desktop.idle;
in
{
  # DankMaterialShell desktop shell. Replaces the waybar stack (bar,
  # launcher, notifications, OSD, power menu) plus the lock screen and idle
  # daemon. Themed by the Stylix dank-material-shell target (enabled in
  # modules/desktop/stylix). Autostarts via its systemd user service.

  options.hyprflake.desktop.dank.enable =
    lib.mkEnableOption "DankMaterialShell desktop shell" // { default = true; };

  # Idle ladder, consumed below to configure DMS idle. Lives here because
  # the dank module now owns idle (hypridle was retired). Same option
  # surface consumers used before so nothing downstream breaks.
  options.hyprflake.desktop.idle = {
    lockTimeout = lib.mkOption {
      type = lib.types.int;
      default = 300;
      example = 600;
      description = "Seconds before locking the session. 0 disables.";
    };
    dpmsTimeout = lib.mkOption {
      type = lib.types.int;
      default = 360;
      example = 0;
      description = ''
        Seconds before turning displays off (DPMS). 0 disables.
        DMS drives this through the compositor's monitor power-off
        (acMonitorTimeout / batteryMonitorTimeout). Defaults to 360
        (6 minutes); set 0 to keep the screen on.
      '';
    };
    suspendTimeout = lib.mkOption {
      type = lib.types.int;
      default = 600;
      example = 0;
      description = "Seconds before suspend. 0 disables.";
    };
  };

  config = lib.mkIf cfg.enable {
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

          # Idle ladder. Mirror AC and battery to the hyprflake.desktop.idle
          # values. Seconds; 0 disables a given listener.
          settings = {
            acLockTimeout = idle.lockTimeout;
            batteryLockTimeout = idle.lockTimeout;
            acMonitorTimeout = idle.dpmsTimeout;
            batteryMonitorTimeout = idle.dpmsTimeout;
            acSuspendTimeout = idle.suspendTimeout;
            batterySuspendTimeout = idle.suspendTimeout;
            lockBeforeSuspend = true;
            loginctlLockIntegration = true;
          };
        };
      })
    ];
  };
}
