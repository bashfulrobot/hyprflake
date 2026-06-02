{ hyprflakeInputs, ... }:

{
  # Import all hyprflake modules
  # This creates a complete Hyprland desktop environment

  imports = [
    # Stylix module system (provides stylix.* options)
    hyprflakeInputs.stylix.nixosModules.stylix

    # Desktop components
    ./desktop/autostart
    ./desktop/dank
    ./desktop/display-manager
    ./desktop/gtk
    ./desktop/hyprland
    ./desktop/kitty
    ./desktop/shortcuts-viewer
    ./desktop/stylix
    ./desktop/system-actions
    ./desktop/themes
    ./desktop/update-checks
    ./desktop/voxtype
    ./desktop/wl-clip-persist

    # System components
    ./system/hyprctl-compat
    ./system/keyring
    ./system/plymouth
    ./system/power
    ./system/user
  ];

  # Pass hyprflake inputs to all submodules
  _module.args = { inherit hyprflakeInputs; };
}
