{ config, lib, pkgs, ... }:

with lib;

{
  options.dconf.hyprflake = {
    enable = mkEnableOption "Enable dconf with Hyprland theme settings";
  };

  config = mkIf config.dconf.hyprflake.enable {
    # Enable dconf settings management
    dconf.enable = true;

    # Apply theme settings via dconf when hyprflake is enabled
    dconf.settings = mkIf config.wayland.windowManager.hyprflake.enable {
      "org/gnome/desktop/interface" = {
        gtk-theme = config.wayland.windowManager.hyprflake.theme.gtkTheme or "Adwaita-dark";
        icon-theme = config.wayland.windowManager.hyprflake.theme.iconTheme or "Adwaita";
        cursor-theme = config.wayland.windowManager.hyprflake.theme.cursorTheme or "Adwaita";
        cursor-size = config.wayland.windowManager.hyprflake.theme.cursorSize or 24;
      };
    };
  };
}