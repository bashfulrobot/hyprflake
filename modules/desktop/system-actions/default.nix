{ config, lib, ... }:

let
  cfg = config.hyprflake.desktop.systemActions;
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "hyprflake" "system-actions" "enable" ]
      [ "hyprflake" "desktop" "systemActions" "enable" ])
  ];

  options.hyprflake.desktop.systemActions = {
    enable = lib.mkEnableOption "system action desktop entries (lock, reboot, shutdown)" // {
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
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
