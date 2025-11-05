{ inputs, ... }:

{
  # Import all hyprflake modules
  # This creates a complete Hyprland desktop environment

  imports = [
    # Desktop components
    ./desktop/display-manager
    ./desktop/hyprland
    ./desktop/stylix
    ./desktop/waybar

    # System components
    ./system/audio
    ./system/cachix
    ./system/fonts
    ./system/graphics
    ./system/keyring
    ./system/xdg
  ];

  # Pass inputs through for Hyprland package
  _module.args = { inherit inputs; };
}
