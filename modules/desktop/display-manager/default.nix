{ config, lib, pkgs, ... }:

{
  # GDM Display Manager configuration for Hyprland
  # Provides graphical login with Wayland support

  services = {
    # GDM with Wayland
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };

      # Set Hyprland as default session
      defaultSession =
        if config.programs.hyprland.withUWSM or false
        then "hyprland-uwsm"
        else "hyprland";
    };

    # X server configuration for keymap
    xserver = {
      enable = true;

      # Configure keymap from hyprflake.desktop options
      xkb = {
        inherit (config.hyprflake.desktop.keyboard) layout variant;
      };

      # Exclude unnecessary X11 packages
      excludePackages = [ pkgs.xterm ];
    };
  };
}
