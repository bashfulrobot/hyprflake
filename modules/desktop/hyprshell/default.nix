{ config, lib, pkgs, ... }:

# Hyprshell - Window Switcher (Alt-Tab)
# Provides alt-tab functionality for Hyprland
# Uses hyprshell from nixpkgs (compatible with nixpkgs Hyprland)
# Note: Launcher functionality disabled by default
# Alt-tab is always enabled

let
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  # Home Manager Hyprshell configuration
  # Using services.hyprshell built into Home Manager
  home-manager.sharedModules = [
    (_: {
      services.hyprshell = {
        enable = true;
        package = pkgs.hyprshell;

        # Settings are passed as JSON value (not type-safe like flake version)
        settings = {
          windows = {
            # Alt-tab switcher configuration
            switch = {
              modifier = "alt"; # Use Alt key for alt-tab
              filter_by = [ "current_monitor" ]; # Only show windows on current monitor
              switch_workspaces = false; # Don't switch workspaces
            };

            # Overview disabled by omission (optional field)
            # If we wanted to enable it, we'd configure overview.launcher, overview.key, etc.
          };
        };

        # Custom CSS styling using Stylix colors
        # Matches Hyprland active/inactive window border colors
        style = stylix.mkStyle ./style.nix;
      };
    })
  ];
}
