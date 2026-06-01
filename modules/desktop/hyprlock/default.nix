{ config, lib, ... }:

{
  # DEPRECATED: the lock screen is now provided by DankMaterialShell
  # (modules/desktop/dank, via `dms ipc lock lock` and loginctl integration).
  # This module is an options-only stub kept so consumers that still set
  # hyprflake.desktop.hyprlock.* keep evaluating.
  options.hyprflake.desktop.hyprlock.enable = lib.mkEnableOption "Hyprlock screen locker" // { default = true; };

  config = lib.mkIf config.hyprflake.desktop.hyprlock.enable {
    warnings = [
      "hyprflake.desktop.hyprlock is a no-op: the lock screen is now provided by DankMaterialShell (modules/desktop/dank). Remove this option from your config."
    ];
  };
}
