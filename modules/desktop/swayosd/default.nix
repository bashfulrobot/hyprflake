{ config, lib, ... }:

{
  # DEPRECATED: volume/brightness OSD is now provided by DankMaterialShell
  # (modules/desktop/dank). This module is an options-only stub kept so
  # consumers that still set hyprflake.desktop.swayosd.* keep evaluating.
  options.hyprflake.desktop.swayosd.enable = lib.mkEnableOption "SwayOSD on-screen display. Note: Hyprland volume/brightness keybindings depend on swayosd-client" // { default = true; };

  config = lib.mkIf config.hyprflake.desktop.swayosd.enable {
    warnings = [
      "hyprflake.desktop.swayosd is a no-op: the volume/brightness OSD is now provided by DankMaterialShell (modules/desktop/dank). Remove this option from your config."
    ];
  };
}
