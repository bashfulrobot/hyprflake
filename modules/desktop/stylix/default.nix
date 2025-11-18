{ config, lib, pkgs, ... }:

{
  # Stylix system-wide theming
  # Uses hyprflake.* options for consumer configuration

  stylix = {
    enable = true;

    # Base16 color scheme from hyprflake.colorScheme option
    # Stylix auto-generates GTK theme from this color scheme
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.hyprflake.colorScheme}.yaml";

    # Wallpaper from hyprflake.wallpaper option
    image = config.hyprflake.wallpaper;

    # Fonts from hyprflake options
    fonts = {
      monospace = {
        package = config.hyprflake.fonts.monospace.package;
        name = config.hyprflake.fonts.monospace.name;
      };
      sansSerif = {
        package = config.hyprflake.fonts.sansSerif.package;
        name = config.hyprflake.fonts.sansSerif.name;
      };
      serif = {
        package = config.hyprflake.fonts.serif.package;
        name = config.hyprflake.fonts.serif.name;
      };
      emoji = {
        package = config.hyprflake.fonts.emoji.package;
        name = config.hyprflake.fonts.emoji.name;
      };

      # Font sizes (in points, 72 points = 1 inch)
      sizes = {
        terminal = 14;      # Terminals and text editors
        applications = 12;  # General applications
        desktop = 10;       # Window titles, status bars, panels
        popups = 10;        # Notifications and popups
      };
    };

    # Cursor theme from options
    cursor = {
      name = config.hyprflake.cursor.name;
      size = config.hyprflake.cursor.size;
      package = config.hyprflake.cursor.package;
    };

    # Opacity from hyprflake options
    opacity = {
      terminal = config.hyprflake.opacity.terminal;
      desktop = config.hyprflake.opacity.desktop;
      popups = config.hyprflake.opacity.popups;
      applications = config.hyprflake.opacity.applications;
    };

    # Theme polarity from hyprflake options
    polarity = config.hyprflake.polarity;
  };
}
