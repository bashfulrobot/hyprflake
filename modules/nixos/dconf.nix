{ config, lib, pkgs, ... }:

with lib;

{
  options.programs.hyprflake-dconf = {
    enable = mkEnableOption "Enable dconf with theme settings";
  };

  config = mkIf config.programs.hyprflake-dconf.enable {
    # Enable dconf for GNOME applications
    programs.dconf.enable = true;

    # Apply theme settings via dconf when hyprflake is enabled
    programs.dconf.profiles.user.databases = mkIf config.programs.hyprflake.enable [
      {
        settings = {
          "org/gnome/desktop/interface" = {
            gtk-theme = config.programs.hyprflake.theme.gtkTheme;
            icon-theme = config.programs.hyprflake.theme.iconTheme;
            cursor-theme = config.programs.hyprflake.theme.cursorTheme;
            cursor-size = config.programs.hyprflake.theme.cursorSize;
          };
        };
      }
    ];
  };
}