{ config, lib, pkgs, ... }:

# Rofimoji - Emoji Picker for Rofi
# Uses Stylix color integration to match existing rofi theme
# Provides a grid-based emoji selector with custom theming

let
  cfg = config.hyprflake.desktop.rofimoji;
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  options.hyprflake.desktop.rofimoji.enable = lib.mkEnableOption "Rofimoji emoji picker" // { default = true; };

  config = lib.mkIf cfg.enable {
    # Install rofimoji system-wide
    environment.systemPackages = with pkgs; [
      rofimoji
    ];

    # Home Manager rofimoji configuration
    home-manager.sharedModules = [
      (_: {
        # Install Stylix-themed rofimoji configuration
        xdg.configFile = {
          # Custom Stylix-integrated theme matching main rofi launcher
          "rofimoji/theme.rasi".text = stylix.mkStyle ./theme.nix;

          # Rofimoji configuration
          "rofimoji.rc".text = ''
            # Rofimoji Configuration
            # Themed to match Stylix colors and main rofi launcher

            # Use custom rofi theme
            selector-args = -theme ~/.config/rofimoji/theme.rasi

            # Prompt text
            prompt = 😀

            # Hide descriptions for cleaner grid layout
            hidden-descriptions = true

            # Action: type the selected character
            action = copy

            # Maximum recent items to show
            max-recent = 10

            # Files to load (emoji, math symbols, etc.)
            files = [emojis, math]

            # Skin tone preference (neutral by default)
            skin-tone = neutral
          '';
        };
      })
    ];
  };
}
