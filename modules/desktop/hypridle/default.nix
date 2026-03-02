{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake.desktop.hypridle;
in
{
  # Hypridle - Idle management daemon for Hyprland
  # Handles screen locking, display power management, and suspend on idle
  # Configurable timeouts via hyprflake.desktop.idle options

  options.hyprflake.desktop.hypridle.enable = lib.mkEnableOption "Hypridle idle management daemon" // { default = true; };

  options.hyprflake.desktop.idle = {
    lockTimeout = lib.mkOption {
      type = lib.types.int;
      default = 300;
      example = 600;
      description = ''
        Timeout in seconds before locking the screen.
        Default is 300 seconds (5 minutes).
        Set to 0 to disable automatic screen locking.
      '';
    };

    dpmsTimeout = lib.mkOption {
      type = lib.types.int;
      default = 360;
      example = 420;
      description = ''
        Timeout in seconds before turning off the display (DPMS).
        Default is 360 seconds (6 minutes).
        Set to 0 to disable automatic display power management.
        Should be greater than lockTimeout if both are enabled.
      '';
    };

    suspendTimeout = lib.mkOption {
      type = lib.types.int;
      default = 600;
      example = 0;
      description = ''
        Timeout in seconds before suspending the system.
        Default is 600 seconds (10 minutes).
        Set to 0 to disable automatic system suspend.
        Should be greater than dpmsTimeout if both are enabled.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.sharedModules = [
      (_: {
        services.hypridle = {
          enable = true;
          package = pkgs.hypridle;

          settings = {
            general = {
              # Respect applications that inhibit idle (e.g., video players)
              ignore_dbus_inhibit = false;

              # Lock screen command - only start hyprlock if not already running
              lock_cmd = "pidof hyprlock || hyprlock";

              # Unlock signal to hyprlock
              unlock_cmd = "pkill --signal SIGUSR1 hyprlock";

              # Lock session before sleep
              before_sleep_cmd = "loginctl lock-session";

              # Turn display back on after resume
              after_sleep_cmd = "hyprctl dispatch dpms on";
            };

            # Idle timeout listeners
            listener =
              let
                inherit (config.hyprflake.desktop.idle) lockTimeout dpmsTimeout suspendTimeout;
              in
              lib.filter (listener: listener.timeout > 0) [
                # Lock screen after configured timeout
                {
                  timeout = lockTimeout;
                  on-timeout = "loginctl lock-session";
                }

                # Turn off display after configured timeout
                {
                  timeout = dpmsTimeout;
                  on-timeout = "hyprctl dispatch dpms off";
                  on-resume = "hyprctl dispatch dpms on";
                }

                # Suspend system after configured timeout
                {
                  timeout = suspendTimeout;
                  on-timeout = "systemctl suspend";
                }
              ];
          };
        };
      })
    ];
  };
}
