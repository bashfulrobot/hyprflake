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
    ./desktop/voxtype
    ./desktop/wl-clip-persist

    # Status bar: retired in favor of dank/ but options preserved for consumers
    ./desktop/waybar
    ./desktop/waybar-auto-hide

    # Deprecated options-only stubs (swaync, swayosd, rofi, rofimoji, wlogout,
    # hyprshell, hyprlock, hypridle) — replaced by dank/, kept so consumer
    # configs keep evaluating
    ./desktop/deprecated-stubs.nix

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
