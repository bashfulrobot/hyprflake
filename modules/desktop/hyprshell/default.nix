{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake.hyprshell;
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  # Hyprshell - Rust-based window switcher and application launcher
  # Previously known as hyprswitch
  # Provides GTK4-based GUI for window management in Hyprland
  # Enabled by default - disable with hyprflake.hyprshell.enable = false;
  # Stylix integration provides automatic Catppuccin/base16 theming

  config = lib.mkIf cfg.enable {
    # Home Manager configuration for hyprshell
    home-manager.sharedModules = [
      (_: {
        # Enable hyprshell with window switching and overview
        services.hyprshell = {
          enable = true;

          # Apply Stylix-integrated CSS theming
          style = stylix.mkStyle ./style.nix;

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
