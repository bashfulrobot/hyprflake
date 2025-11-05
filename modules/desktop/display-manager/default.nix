{ config, lib, pkgs, ... }:

let
  settings = import ../../../settings/default.nix;
in
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

    # Configure keymap from settings
    xkb = {
      layout = settings.system.keyboard.layout;
      variant = settings.system.keyboard.variant;
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
