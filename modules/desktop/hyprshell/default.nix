{ config, lib, hyprflakeInputs, ... }:

# Hyprshell - Window Switcher (Alt-Tab)
# Provides alt-tab functionality for Hyprland
# Note: Launcher functionality disabled by default
# Alt-tab is always enabled

{
  # Home Manager Hyprshell configuration
  home-manager.sharedModules = [
    hyprflakeInputs.hyprshell.homeModules.default
    (_: {
      programs.hyprshell = {
        enable = true;

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
      };
    })
  ];
}
