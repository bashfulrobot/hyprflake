{ hyprflakeInputs, ... }:

{
  # Import all hyprflake modules
  # This creates a complete Hyprland desktop environment

  imports = [
    # Stylix module system (provides stylix.* options)
    hyprflakeInputs.stylix.nixosModules.stylix

    # DankGreeter NixOS module (provides programs.dank-material-shell.greeter.*).
    # Imported here, where hyprflakeInputs is a direct argument; importing it
    # from a submodule that receives hyprflakeInputs via _module.args recurses
    # (imports are resolved before config, but _module.args needs config). Its
    # config is gated by `.greeter.enable`, which the display-manager module
    # turns on unconditionally (the login manager is core, not optional).
    hyprflakeInputs.dank-material-shell.nixosModules.greeter

    # Desktop components
    ./desktop/autostart
    ./desktop/dank
    ./desktop/display-manager
    ./desktop/gtk
    ./desktop/hyprland
    ./desktop/kitty
    ./desktop/shortcuts-viewer
    ./desktop/snappy-switcher
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
