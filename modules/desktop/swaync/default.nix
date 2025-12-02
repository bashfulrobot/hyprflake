{ config, lib, pkgs, ... }:

let
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  # SwayNC - Simple notification daemon for Wayland
  # Minimal configuration with Stylix theming
  # Integrates with waybar (notification counter already configured in waybar module)

  home-manager.sharedModules = [
    (_: {
      services.swaync = {
        enable = true;
        package = pkgs.swaynotificationcenter;

        # Stylix-aware CSS styling
        style = stylix.mkStyle ./style.nix;

        # Minimal settings - just basic notifications
        settings = {
          # Position
          positionX = "right";
          positionY = "top";
          layer = "overlay";
          layer-shell = true;
          cssPriority = "user";

          # Control center dimensions
          control-center-width = 380;
          control-center-height = 600;
          control-center-margin-top = 8;
          control-center-margin-bottom = 8;
          control-center-margin-right = 8;
          control-center-margin-left = 8;

          # Notification settings
          notification-window-width = 400;
          notification-icon-size = 48;
          notification-body-image-height = 100;
          notification-body-image-width = 200;

          # Timeout settings (milliseconds)
          timeout = 5;
          timeout-low = 3;
          timeout-critical = 0; # Critical notifications don't auto-dismiss

          # Keyboard shortcuts
          keyboard-shortcuts = true;
          image-visibility = "when-available";
          transition-time = 200;

          # Widgets - title, DND, media controls, and notifications
          widgets = [
            "title"
            "dnd"
            "mpris"
            "notifications"
          ];

          widget-config = {
            title = {
              text = "Notifications";
              clear-all-button = true;
              button-text = "Clear All";
            };
            dnd = {
              text = "Do Not Disturb";
            };
            mpris = {
              image-size = 60;
              image-radius = 12;
            };
          };
        };
      };
    })
  ];
}
