{ config, lib, pkgs, ... }:

{
  # Theme packages installation
  # Ensures GTK, icon, and cursor themes are installed system-wide
  # Packages are defined in hyprflake.themes.* and hyprflake.cursor.* options

  environment.systemPackages = [
    # GTK theme from options
    config.hyprflake.themes.gtk.package

    # Icon theme from options
    config.hyprflake.themes.icon.package

    # Cursor theme from options
    config.hyprflake.cursor.package

    # Additional theme-related packages for compatibility
    pkgs.gtk-engine-murrine  # Required by many GTK themes
    pkgs.gnome-themes-extra  # Adwaita and other GNOME themes
  ];
}
