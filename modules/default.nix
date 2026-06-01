{ hyprflakeInputs, ... }:

{
  # Import all hyprflake modules
  # This creates a complete Hyprland desktop environment

  imports = [
    # Stylix module system (provides stylix.* options)
    hyprflakeInputs.stylix.nixosModules.stylix

    # Desktop components
    ./desktop/autostart
    ./desktop/calendar-notifier
    ./desktop/dank
    ./desktop/display-manager
    ./desktop/gtk
    ./desktop/hypridle
    ./desktop/hyprland
    ./desktop/hyprlock
    ./desktop/hyprshell
    ./desktop/kitty
    ./desktop/rofi
    ./desktop/rofimoji
    ./desktop/shortcuts-viewer
    ./desktop/stylix
    ./desktop/swaync
    ./desktop/swayosd
    ./desktop/system-actions
    ./desktop/themes
    ./desktop/voxtype
    ./desktop/waybar
    ./desktop/waybar-auto-hide
    ./desktop/wl-clip-persist
    ./desktop/wlogout

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
