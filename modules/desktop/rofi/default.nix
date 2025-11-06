{ config, lib, pkgs, ... }:

# Rofi Application Launcher
# Stylix provides automatic theming for rofi
# Configured via home-manager for proper per-user theming

let
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  # Home Manager Rofi configuration
  home-manager.sharedModules = [
    (_: {
      programs.rofi = {
        enable = true;
        package = pkgs.rofi-wayland;  # Wayland-native rofi

        # Terminal to launch from rofi
        terminal = "${lib.getExe pkgs.kitty}";

        # Additional plugins
        plugins = with pkgs; [
          rofi-emoji-wayland  # Emoji picker
        ];

        # Extra config (Stylix handles theme)
        extraConfig = {
          # Display settings
          modi = "drun,run,window";
          show-icons = true;
          icon-theme = stylix.cursor.name;

          # Behavior
          drun-display-format = "{name}";
          disable-history = false;
          hide-scrollbar = true;
          sidebar-mode = false;

          # Window positioning
          location = 0;  # Center
          anchor = 0;

          # Font from Stylix
          font = "${stylix.fonts.sans} ${toString stylix.fonts.applications}";
        };
      };
    })
  ];
}
