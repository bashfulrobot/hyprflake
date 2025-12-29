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
          # Windows section - required for switch functionality
          windows = {
            enable = true;

            # Alt-tab switcher configuration
            switch = {
              enable = true;
              modifier = "alt"; # Use Alt key for alt-tab
              filter_by = [ "current_monitor" ]; # Only show windows on current monitor
              switch_workspaces = false; # Don't switch workspaces
            };

            # Overview disabled (launcher-like functionality)
            # Launcher is nested under overview, so we disable the entire overview
            overview = {
              enable = false;
            };
          };
        };

        # Custom CSS styling using Stylix colors
        # Matches Hyprland active/inactive window border colors
        style = stylix.mkStyle ./style.nix;
      };
    })
  ];
}
