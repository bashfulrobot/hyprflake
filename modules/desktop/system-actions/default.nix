{ config, lib, ... }:

with lib;

let
  cfg = config.hyprflake.system-actions;
in
{
  options.hyprflake.system-actions = {
    enable = mkEnableOption "system action desktop entries (lock, reboot, shutdown)" // {
      default = true;
    };
  };

  config = mkIf cfg.enable {
    home-manager.sharedModules = [
      (_: {
        xdg.desktopEntries = {
          lock = {
            name = "Lock Screen";
            comment = "Lock the screen";
            exec = "loginctl lock-session";
            icon = "system-lock-screen";
            terminal = false;
            categories = [ "System" ];
          };

          reboot = {
            name = "Reboot";
            comment = "Restart the computer";
            exec = "systemctl reboot";
            icon = "system-reboot";
            terminal = false;
            categories = [ "System" ];
          };

          shutdown = {
            name = "Shutdown";
            comment = "Power off the computer";
            exec = "systemctl poweroff";
            icon = "system-shutdown";
            terminal = false;
            categories = [ "System" ];
          };
        };
      })
    ];
  };
}
