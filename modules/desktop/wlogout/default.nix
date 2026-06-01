{ config, lib, ... }:

{
  # DEPRECATED: the power menu is now provided by DankMaterialShell
  # (modules/desktop/dank, via `dms ipc powermenu toggle`). This module is
  # an options-only stub kept so consumers that still set
  # hyprflake.desktop.wlogout.* keep evaluating.
  options.hyprflake.desktop.wlogout.enable = lib.mkEnableOption "Wlogout session logout menu" // { default = true; };

  config = lib.mkIf config.hyprflake.desktop.wlogout.enable {
    warnings = [
      "hyprflake.desktop.wlogout is a no-op: the power menu is now provided by DankMaterialShell (modules/desktop/dank). Remove this option from your config."
    ];
  };
}
