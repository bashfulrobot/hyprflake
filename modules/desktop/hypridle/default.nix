{ pkgs, ... }:

{
  # Hypridle - Idle management daemon for Hyprland
  # Handles screen locking, display power management, and suspend on idle
  # Minimal configuration based on nixcfg with sensible timeout defaults

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
          listener = [
            # Lock screen after 5 minutes of inactivity
            {
              timeout = 300;
              on-timeout = "loginctl lock-session";
            }

            # Turn off display after 6 minutes of inactivity
            {
              timeout = 360;
              on-timeout = "hyprctl dispatch dpms off";
              on-resume = "hyprctl dispatch dpms on";
            }

            # Suspend system after 10 minutes of inactivity
            {
              timeout = 600;
              on-timeout = "systemctl suspend";
            }
          ];
        };
      };
    })
  ];
}

