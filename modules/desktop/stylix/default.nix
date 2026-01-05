{ config, lib, pkgs, ... }:

{
  # Stylix system-wide theming
  # Uses hyprflake.* options for consumer configuration

  stylix = {
    enable = true;

    # Base16 color scheme from hyprflake.style.colorScheme option
    # Stylix auto-generates GTK theme from this color scheme
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.hyprflake.style.colorScheme}.yaml";

    # Wallpaper from hyprflake.style.wallpaper option
    # Direct assignment to ensure wallpaper is set (consumers can still override via stylix.image with mkForce)
    image = config.hyprflake.style.wallpaper;

    # Fonts from hyprflake.style options
    fonts = {
      monospace = {
        inherit (config.hyprflake.style.fonts.monospace) package name;
      };
      sansSerif = {
        inherit (config.hyprflake.style.fonts.sansSerif) package name;
      };
      serif = {
        inherit (config.hyprflake.style.fonts.serif) package name;
      };
      emoji = {
        inherit (config.hyprflake.style.fonts.emoji) package name;
      };

      # Font sizes (in points, 72 points = 1 inch)
      sizes = {
        terminal = 14; # Terminals and text editors
        applications = 12; # General applications
        desktop = 10; # Window titles, status bars, panels
        popups = 10; # Notifications and popups
      };
    };

    # Cursor theme from options
    cursor = {
      inherit (config.hyprflake.style.cursor) name size package;
    };

    # Opacity from hyprflake.style options
    opacity = {
      inherit (config.hyprflake.style.opacity) terminal desktop popups applications;
    };

    # Theme polarity from hyprflake.style options
    inherit (config.hyprflake.style) polarity;
  };
}
