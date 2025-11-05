{ config, lib, pkgs, ... }:

let
  settings = import ../../../settings/default.nix;
in
{
  # Stylix system-wide theming
  # Uses hyprflake.* options for consumer configuration
  # Settings provide internal structural defaults

  stylix = {
    enable = true;

    # Base16 color scheme from hyprflake.colorScheme option
    base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.hyprflake.colorScheme}.yaml";

    # Wallpaper - uses hyprflake.wallpaper option (defaults from settings)
    image = pkgs.fetchurl {
      url = config.hyprflake.wallpaper.url;
      sha256 = config.hyprflake.wallpaper.sha256;
    };

    # Fonts
    fonts = {
      monospace = {
        package = pkgs.${settings.theme.fonts.monospace.package};
        name = settings.theme.fonts.monospace.name;
      };
      sansSerif = {
        package = pkgs.${settings.theme.fonts.sansSerif.package};
        name = settings.theme.fonts.sansSerif.name;
      };
      serif = {
        package = pkgs.${settings.theme.fonts.serif.package};
        name = settings.theme.fonts.serif.name;
      };
    };

    # Cursor theme
    cursor = {
      name = settings.theme.cursor.theme;
      size = settings.theme.cursor.size;
    };

    # Opacity settings for consistent UI
    opacity = {
      terminal = 0.9;
      desktop = 1.0;
      popups = 0.95;
    };
  };
}
