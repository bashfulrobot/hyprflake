{ config, lib, ... }:

{
  # DEPRECATED: waybar (and its auto-hide) is replaced by DankMaterialShell
  # (modules/desktop/dank), which manages its own bar reveal. This module is
  # an options-only stub kept so consumers that still set
  # hyprflake.desktop.waybar.autoHide keep evaluating.
  options.hyprflake.desktop.waybar = {
    autoHide = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        DEPRECATED no-op. Waybar auto-hide does not apply under
        DankMaterialShell. Kept for consumer-config compatibility.
      '';
    };
  };

  config = lib.mkIf config.hyprflake.desktop.waybar.autoHide {
    warnings = [
      "hyprflake.desktop.waybar.autoHide is a no-op: the status bar is now provided by DankMaterialShell (modules/desktop/dank)."
    ];
  };
}
