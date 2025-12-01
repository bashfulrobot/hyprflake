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
        inherit (config.hyprflake.fonts.monospace) package name;
      };
      sansSerif = {
        inherit (config.hyprflake.fonts.sansSerif) package name;
      };
      serif = {
        inherit (config.hyprflake.fonts.serif) package name;
      };
      emoji = {
        inherit (config.hyprflake.fonts.emoji) package name;
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
      inherit (config.hyprflake.cursor) name size package;
    };

    # Opacity from hyprflake options
    opacity = {
      inherit (config.hyprflake.opacity) terminal desktop popups applications;
    };

    # Theme polarity from hyprflake options
    inherit (config.hyprflake) polarity;
  };
}
