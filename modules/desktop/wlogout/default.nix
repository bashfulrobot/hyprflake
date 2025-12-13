{ config, lib, pkgs, ... }:

let
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  # Wlogout - Wayland logout menu
  # Simple logout/shutdown/reboot/suspend menu with Stylix theming
  # Triggered from waybar power button or Super+Escape keybinding

  home-manager.sharedModules = [
    (_: {
      programs.wlogout = {
        enable = true;

        # Stylix-aware CSS styling
        style = stylix.mkStyle ./style.nix;

        # Four main actions with compact proportional sizing
        # height/width are 0.0-1.0 proportions of screen space
        layout = [
          {
            label = "logout";
            action = "loginctl terminate-user $USER";
            text = "Logout";
            keybind = "e";
            height = 0.15;
            width = 0.15;
          }
          {
            label = "shutdown";
            action = "systemctl poweroff";
            text = "Shutdown";
            keybind = "s";
            height = 0.15;
            width = 0.15;
          }
          {
            label = "suspend";
            action = "systemctl suspend";
            text = "Suspend";
            keybind = "u";
            height = 0.15;
            width = 0.15;
          }
          {
            label = "reboot";
            action = "systemctl reboot";
            text = "Reboot";
            keybind = "r";
            height = 0.15;
            width = 0.15;
          }
        ];
      };
    })
  ];
}
