{ config, lib, pkgs, ... }:

{
  # Hypridle - Idle management daemon for Hyprland
  # Handles screen locking, display power management, and suspend on idle
  # Configurable timeouts via hyprflake.desktop.idle options

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
              lockTimeout = config.hyprflake.desktop.idle.lockTimeout;
              dpmsTimeout = config.hyprflake.desktop.idle.dpmsTimeout;
              suspendTimeout = config.hyprflake.desktop.idle.suspendTimeout;
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
}

