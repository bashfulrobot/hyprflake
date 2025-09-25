{ config, lib, pkgs, ... }:

with lib;

{
  options.services.hyprflake-display = {
    enable = mkEnableOption "Enable greetd + ReGreet display manager";

    autoLogin = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Username to auto-login (optional)";
    };
  };

  config = mkIf config.services.hyprflake-display.enable {
    # greetd with ReGreet (opinionated choice - lightweight, GTK-based)
    services.greetd = {
      enable = true;
      settings = {
        default_session = mkIf (config.services.hyprflake-display.autoLogin == null) {
          command = "${pkgs.greetd.regreet}/bin/regreet";
          user = "greeter";
        };

        # Auto-login session if specified
        initial_session = mkIf (config.services.hyprflake-display.autoLogin != null) {
          command = "Hyprland";
          user = config.services.hyprflake-display.autoLogin;
        };
      };
    };

    # ReGreet package for the greeter
    environment.systemPackages = with pkgs; [
      greetd.regreet
    ];

    # GTK theme configuration for ReGreet
    environment.etc."greetd/regreet.toml".text = ''
      [background]
      path = ""
      fit = "Cover"

      [GTK]
      application_prefer_dark_theme = true
      theme_name = "Adwaita-dark"
      icon_theme_name = "Adwaita"
      font_name = "Cantarell 11"

      [commands]
      reboot = ["systemctl", "reboot"]
      poweroff = ["systemctl", "poweroff"]
    '';
  };
}