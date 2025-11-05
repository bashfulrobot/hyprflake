{ inputs, ... }:

{
  # Import all hyprflake modules
  # This creates a complete Hyprland desktop environment

  imports = [
    # Desktop components
    ./desktop/hyprland
    ./desktop/stylix

    # System components
    ./system/audio
    ./system/fonts
    ./system/graphics
    ./system/keyring
    ./system/xdg
  ];

  # Pass inputs through for Hyprland package
  _module.args = { inherit inputs; };
}
