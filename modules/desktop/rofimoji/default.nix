{ config, lib, ... }:

{
  # DEPRECATED: dropped in the DankMaterialShell migration. DMS has no
  # emoji-picker equivalent; this module is an options-only stub kept so
  # consumers that still set hyprflake.desktop.rofimoji.* keep evaluating.
  options.hyprflake.desktop.rofimoji.enable = lib.mkEnableOption "Rofimoji emoji picker" // { default = true; };

  config = lib.mkIf config.hyprflake.desktop.rofimoji.enable {
    warnings = [
      "hyprflake.desktop.rofimoji is a no-op: the emoji picker was dropped in the DankMaterialShell migration. Remove this option from your config."
    ];
  };
}
