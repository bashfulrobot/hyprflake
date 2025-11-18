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
    ./desktop/stylix
    ./desktop/waybar
    ./desktop/rofi

    # Home components
    ./home/gtk
    ./home/kitty
    ./home/starship

    # System components
    ./system/user

    # System components (TODO: to be created)
    # ./system/audio
    # ./system/cachix
    # ./system/fonts
    # ./system/graphics
    # ./system/keyring
    # ./system/xdg
  ];

  # Pass hyprflake inputs to all submodules
  _module.args = { inherit hyprflakeInputs; };
}
