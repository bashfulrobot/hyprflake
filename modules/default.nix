{ inputs, ... }:

{
  # Import all hyprflake modules
  # This creates a complete Hyprland desktop environment

  imports = [
    # Configuration options (must be first for other modules to use)
    ./options.nix

    # Desktop components
    ./desktop/display-manager
    ./desktop/hyprland
    ./desktop/stylix
    ./desktop/waybar
    ./desktop/rofi

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
