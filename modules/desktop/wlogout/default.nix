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
            min-width: 150px;
            min-height: 150px;
            max-width: 150px;
            max-height: 150px;
            color: #${base05};
            background-color: #${base01};
            border-style: solid;
            border-width: 2px;
            border-color: #${base03};
            border-radius: 12px;
            background-repeat: no-repeat;
            background-position: center;
            background-size: 25%;
            margin: 20px;
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

          #logout {
            background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/logout.png"));
          }

          #suspend {
            background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/suspend.png"));
          }

          #shutdown {
            background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/shutdown.png"));
          }

          #reboot {
            background-image: image(url("${pkgs.wlogout}/share/wlogout/icons/reboot.png"));
          }
        '';

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
