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

        # Four main actions: logout, shutdown, suspend, reboot
        layout = [
          {
            label = "logout";
            action = "loginctl terminate-user $USER";
            text = "Logout";
            keybind = "e";
          }
          {
            label = "shutdown";
            action = "systemctl poweroff";
            text = "Shutdown";
            keybind = "s";
          }
          {
            label = "suspend";
            action = "systemctl suspend";
            text = "Suspend";
            keybind = "u";
          }
          {
            label = "reboot";
            action = "systemctl reboot";
            text = "Reboot";
            keybind = "r";
          }
        ];
      };
    })
  ];
}
