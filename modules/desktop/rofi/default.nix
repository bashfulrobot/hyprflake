{ config, lib, ... }:

{
  # DEPRECATED: the application launcher and rofi-network-manager are now
  # provided by DankMaterialShell (modules/desktop/dank, via
  # `dms ipc spotlight toggle` and `dms ipc control-center toggle`). This
  # module is an options-only stub kept so consumers that still set
  # hyprflake.desktop.rofi.* keep evaluating.
  options.hyprflake.desktop.rofi.enable =
    lib.mkEnableOption "Rofi application launcher. Note: Hyprland app launcher keybind depends on rofi"
    // {
      default = true;
    };

  config = lib.mkIf config.hyprflake.desktop.rofi.enable {
    warnings = [
      "hyprflake.desktop.rofi is a no-op: the launcher and network menu are now provided by DankMaterialShell (modules/desktop/dank). Remove this option from your config."
    ];
  };
}
