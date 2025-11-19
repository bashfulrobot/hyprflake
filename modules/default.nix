{ hyprflakeInputs, ... }:

{
  # Import all hyprflake modules
  # This creates a complete Hyprland desktop environment

  imports = [
    # Stylix module system (provides stylix.* options)
    hyprflakeInputs.stylix.nixosModules.stylix

    # Configuration options (must be first for other modules to use)
    ./options.nix

    # Desktop components
    ./desktop/display-manager
    ./desktop/hyprland
    ./desktop/hypridle
    ./desktop/hyprlock
    ./desktop/stylix
    ./desktop/themes
    ./desktop/waybar
    ./desktop/rofi
    ./desktop/swaync
    ./desktop/swayosd

    # Home components
    ./home/gtk
    ./home/kitty

    # System components
    ./system/user
    ./system/keyring

    # System components (TODO: to be created)
    # ./system/audio
    # ./system/cachix
    # ./system/fonts
    # ./system/graphics
    # ./system/xdg
  ];

  # Pass hyprflake inputs to all submodules
  _module.args = { inherit hyprflakeInputs; };
}
