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
    ./desktop/autostart
    ./desktop/display-manager
    ./desktop/hyprland
    ./desktop/hyprshell
    ./desktop/hypridle
    ./desktop/hyprlock
    ./desktop/stylix
    ./desktop/themes
    ./desktop/waybar
    ./desktop/waybar-auto-hide
    ./desktop/rofi
    ./desktop/rofimoji
    ./desktop/swaync
    ./desktop/swayosd
    ./desktop/wlogout

    # Home components
    ./home/gtk
    ./home/kitty

    # System components
    ./system/user
    ./system/keyring
    ./system/plymouth
    ./system/power

    # System components (TODO: to be created)
    # ./system/audio
    # ./system/fonts
    # ./system/graphics
    # ./system/xdg
  ];

  # Pass hyprflake inputs to all submodules
  _module.args = { inherit hyprflakeInputs; };
}
