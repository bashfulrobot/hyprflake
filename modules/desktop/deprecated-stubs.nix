{ config, lib, ... }:

# Deprecated options-only stubs for the waybar stack retired in the
# DankMaterialShell migration. Their functionality now lives in the dank
# module (modules/desktop/dank); these declarations exist only so consumer
# configs that still set `hyprflake.desktop.<name>.enable` keep evaluating.
# Each enabled stub emits a build warning.
#
# These eight carry no option surface any consumer reads, so they are
# collapsed here instead of one directory each. waybar and waybar-auto-hide
# are NOT here: they preserve real options (workspaceAppIcons.*, autoHide)
# that nixerator still consumes, so they remain proper modules.
#
# Remove this whole file once consumers drop these options.

let
  # name -> reason the option is now a no-op.
  retired = {
    swaync = "notifications are now provided by DankMaterialShell";
    swayosd = "the on-screen display is now provided by DankMaterialShell";
    rofi = "the launcher and network menu are now provided by DankMaterialShell";
    rofimoji = "the emoji picker is now the DankMaterialShell emojiLauncher plugin (trigger \":e\", SUPER+.)";
    wlogout = "the power menu is now provided by DankMaterialShell";
    hyprshell = "the window switcher is now provided by DankMaterialShell";
    hyprlock = "the lock screen is now provided by DankMaterialShell";
    hypridle = "idle management is now provided by DankMaterialShell";
  };
in
{
  options.hyprflake.desktop = lib.mapAttrs
    (name: _: {
      enable = lib.mkEnableOption "the retired ${name} module (no-op stub)" // {
        default = true;
      };
    })
    retired;

  config.warnings = lib.flatten (lib.mapAttrsToList
    (name: reason:
      lib.optional config.hyprflake.desktop.${name}.enable
        "hyprflake.desktop.${name} is a no-op: ${reason} (modules/desktop/dank). Remove this option from your config.")
    retired);
}
