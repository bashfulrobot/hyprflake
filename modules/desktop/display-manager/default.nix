{ config, lib, pkgs, ... }:

{
  # GDM Display Manager configuration for Hyprland
  # Provides graphical login with Wayland support

  services.xserver = {
    enable = true;

    # GDM with Wayland
    displayManager.gdm = {
      enable = true;
      wayland = true;
    };

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
