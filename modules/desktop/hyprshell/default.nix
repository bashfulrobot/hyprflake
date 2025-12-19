{ config, lib, pkgs, hyprflakeInputs, ... }:

let
  cfg = config.hyprflake.hyprshell;
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  # Hyprshell - Rust-based window switcher and application launcher
  # Previously known as hyprswitch
  # Provides GTK4-based GUI for window management in Hyprland
  # Note: Requires version synchronization with hyprland (handled via flake follows)
  # Enabled by default - disable with hyprflake.hyprshell.enable = false;
  # Stylix integration provides automatic Catppuccin/base16 theming

  config = lib.mkIf cfg.enable {
    # Import hyprshell's home-manager module
    home-manager.sharedModules = [
      hyprflakeInputs.hyprshell.homeModules.hyprshell
      (_: {
        # Enable hyprshell with window switching and overview
        programs.hyprshell = {
          enable = true;

          # Apply Stylix-integrated CSS theming
          styleFile = stylix.mkStyle ./style.nix;

          settings = {
            # Enable window management features
            windows = {
              enable = true;

              # Window overview/switcher
              overview = {
                enable = true;

                # Integrated launcher
                launcher = {
                  # Show up to 100 items in launcher
                  max_items = 100;
                };
              };

              # Window switching with keyboard
              switch = {
                enable = true;
              };
            };
          };
        };
      })
    ];
  };
}
