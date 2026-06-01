{ config, lib, ... }:

{
  # DEPRECATED: the alt-tab window switcher was dropped in the
  # DankMaterialShell migration (DMS provides its own overview/switcher).
  # This module is an options-only stub kept so consumers that still set
  # hyprflake.desktop.hyprshell.* keep evaluating.
  options.hyprflake.desktop.hyprshell.enable = lib.mkEnableOption "HyprShell desktop shell" // { default = true; };

  config = lib.mkIf config.hyprflake.desktop.hyprshell.enable {
    warnings = [
      "hyprflake.desktop.hyprshell is a no-op: the alt-tab switcher was dropped in the DankMaterialShell migration. Remove this option from your config."
    ];
  };
}
