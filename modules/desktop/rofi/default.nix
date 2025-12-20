{ config, lib, pkgs, ... }:

# Rofi Application Launcher
# Uses adi1090x rofi type-3 style-1 theme with Stylix color integration
# Theme files are local to avoid external dependencies

let
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  # Home Manager Rofi configuration
  home-manager.sharedModules = [
    (_: {
      programs.rofi = {
        enable = true;
        package = pkgs.rofi;

        # Terminal to launch from rofi
        terminal = "${lib.getExe pkgs.kitty}";

        # Additional plugins
        plugins = with pkgs; [
          rofi-emoji # Emoji picker
        ];
      };

      # Install adi1090x rofi theme files with Stylix integration
      xdg.configFile = {
        # Type-3 style-1 theme file
        "rofi/launchers/type-3/style-1.rasi" = {
          source = ./type-3/style-1.rasi;
        };

        # Stylix-integrated colors
        "rofi/launchers/type-3/shared/colors.rasi".text = stylix.mkStyle ./type-3/shared/colors.nix;

        # Stylix-integrated fonts
        "rofi/launchers/type-3/shared/fonts.rasi".text = stylix.mkStyle ./type-3/shared/fonts.nix;
      };
    })
  ];
}
