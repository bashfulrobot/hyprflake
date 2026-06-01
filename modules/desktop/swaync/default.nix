{ config, lib, ... }:

{
  # DEPRECATED: notifications are now provided by DankMaterialShell
  # (modules/desktop/dank). This module is an options-only stub kept so
  # consumers that still set hyprflake.desktop.swaync.* keep evaluating.
  options.hyprflake.desktop.swaync.enable = lib.mkEnableOption "SwayNC notification daemon. Note: Hyprland keybind (SUPER+N) calls swaync-client" // { default = true; };

  config = lib.mkIf config.hyprflake.desktop.swaync.enable {
    warnings = [
      "hyprflake.desktop.swaync is a no-op: notifications are now provided by DankMaterialShell (modules/desktop/dank). Remove this option from your config."
    ];
  };
}
