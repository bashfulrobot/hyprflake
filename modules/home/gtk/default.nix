{ config, lib, pkgs, ... }:

{
  # GTK and cursor theme configuration
  # Uses Stylix values for theming to ensure consistency
  # Follows Hyprland wiki recommendations for theme compatibility

  home-manager.sharedModules = [
    (_: {
      # Pointer cursor configuration
      # Pulls values from Stylix cursor config for consistency
      home.pointerCursor = {
        gtk.enable = true;
        package = config.stylix.cursor.package;
        name = config.stylix.cursor.name;
        size = config.stylix.cursor.size;
      };

      # GTK configuration
      gtk = {
        enable = true;

        # Font configuration from Stylix
        # Uses sansSerif font for GTK applications
        font = {
          name = config.stylix.fonts.sansSerif.name;
          size = config.stylix.fonts.sizes.applications;
        };

        # GTK theme and icon theme are handled automatically by Stylix
        # via stylix.targets.gtk.enable (enabled by default)
        # This includes:
        # - gtk.theme (GTK theme from base16 scheme)
        # - gtk.iconTheme (if configured in Stylix)
      };
    })
  ];
}
