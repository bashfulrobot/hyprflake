{ config, lib, pkgs, ... }:

{
  # GDM Display Manager configuration for Hyprland
  # Provides graphical login with Wayland support

  # GDM with Wayland
  services.displayManager.gdm = {
    enable = true;
    wayland = true;
  };

  # X server configuration for keymap
  services.xserver = {
    enable = true;

    # Configure keymap from hyprflake options
    xkb = {
      layout = config.hyprflake.keyboard.layout;
      variant = config.hyprflake.keyboard.variant;
    };

    # Exclude unnecessary X11 packages
    excludePackages = [ pkgs.xterm ];
  };

  # Set Hyprland as default session
  services.displayManager.defaultSession =
    if config.programs.hyprland.withUWSM or false
    then "hyprland-uwsm"
    else "hyprland";
}
