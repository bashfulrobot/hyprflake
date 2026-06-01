{ config, lib, ... }:

{
  # DEPRECATED: idle/lock/DPMS are now handled by DankMaterialShell
  # (modules/desktop/dank), configured via hyprflake.desktop.idle.* (those
  # options now live in the dank module). This module is an options-only
  # stub kept so consumers that still set hyprflake.desktop.hypridle.enable
  # keep evaluating.
  options.hyprflake.desktop.hypridle.enable = lib.mkEnableOption "Hypridle idle management daemon" // { default = true; };

  config = lib.mkIf config.hyprflake.desktop.hypridle.enable {
    warnings = [
      "hyprflake.desktop.hypridle is a no-op: idle/lock/DPMS are now handled by DankMaterialShell (modules/desktop/dank), configured via hyprflake.desktop.idle.*."
    ];
  };
}
