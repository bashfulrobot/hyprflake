{ config, lib, pkgs, ... }:

let
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  # Wlogout - Wayland logout menu
  # Simple logout/shutdown/reboot/suspend menu with Stylix theming
  # Triggered from waybar power button or Super+Escape keybinding

  home-manager.sharedModules = [
    ({ pkgs, config, ... }: {
      programs.wlogout = {
        enable = true;

        # Stylix-aware CSS styling with proper icon paths
        style = with config.lib.stylix.colors; ''
          /* Wlogout styling with Stylix base16 color integration */

          * {
            background-image: none;
            box-shadow: none;
          }

          window {
            background-color: rgba(0, 0, 0, ${toString config.stylix.opacity.popups});
          }

          button {
            color: #${base05};
            background-color: #${base01};
            border-style: solid;
            border-width: 2px;
            border-color: #${base03};
            border-radius: 12px;
            background-repeat: no-repeat;
            background-position: center;
            background-size: 25%;
            font-family: "${config.stylix.fonts.sansSerif.name}";
            font-size: ${toString config.stylix.fonts.sizes.applications}px;
          }

          button:focus,
          button:active,
          button:hover {
            background-color: #${base0D};
            color: #${base00};
            background-size: 20%;
            border-color: #${base0D};
            outline-style: none;
          }

          label {
            color: #${base05};
            font-weight: bold;
          }

          #lock {
            background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/lock.png"));
          }

          #logout {
            background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
          }

          #suspend {
            background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
          }

          #hibernate {
            background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/hibernate.png"));
          }

          #shutdown {
            background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
          }

          #reboot {
            background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
          }
        '';

        # Six actions: lock, logout, suspend, hibernate, shutdown, reboot
        layout = [
          {
            label = "lock";
            action = "hyprlock";
            text = "Lock";
            keybind = "l";
          }
          {
            label = "logout";
            action = "loginctl terminate-user $USER";
            text = "Logout";
            keybind = "e";
          }
          {
            label = "suspend";
            action = "systemctl suspend";
            text = "Suspend";
            keybind = "u";
          }
          {
            label = "hibernate";
            action = "systemctl hibernate";
            text = "Hibernate";
            keybind = "h";
          }
          {
            label = "shutdown";
            action = "systemctl poweroff";
            text = "Shutdown";
            keybind = "s";
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
