{ config, lib, pkgs, ... }:

{
  # GTK and cursor theme configuration
  # Inherits theme settings from hyprflake.themes.* options
  # Follows Hyprland wiki recommendations for theme compatibility

  home-manager.sharedModules = [
    (_: {
      # Pointer cursor configuration
      # Pulls values from hyprflake.cursor options
      # Also configured in Stylix, but home.pointerCursor needed for compatibility
      home.pointerCursor = {
        gtk.enable = true;
        package = config.hyprflake.cursor.package;
        name = config.hyprflake.cursor.name;
        size = config.hyprflake.cursor.size;
      };

      # GTK configuration
      gtk = {
        enable = true;

        # GTK theme from hyprflake.themes.gtk options
        theme = {
          package = config.hyprflake.themes.gtk.package;
          name = config.hyprflake.themes.gtk.name;
        };

        # Icon theme from hyprflake.themes.icon options
        iconTheme = {
          package = config.hyprflake.themes.icon.package;
          name = config.hyprflake.themes.icon.name;
        };

        # Font configuration from Stylix
        # Uses sansSerif font for GTK applications
        font = {
          name = config.stylix.fonts.sansSerif.name;
          size = config.stylix.fonts.sizes.applications;
        };
      };
    })
  ];
}

