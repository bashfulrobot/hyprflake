{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake.plymouth;
in
{
  options.hyprflake.plymouth = {
    enable = lib.mkEnableOption "Plymouth boot splash screen with Hyprland wallpaper";
  };

  config = lib.mkIf cfg.enable {
    # Enable Plymouth boot splash with Circle HUD theme
    boot.plymouth = {
      enable = true;
      theme = "circle_hud";
      themePackages = [
        (pkgs.adi1090x-plymouth-themes.override {
          selected_themes = [ "circle_hud" ];
        })
      ];
    };

    # TODO: Custom font (needs proper .ttf path)
    # boot.plymouth.font = "/path/to/font.ttf";

    # TODO: Custom logo (48x48 PNG icon, not wallpaper)
    # boot.plymouth.logo = /path/to/logo.png;

    # TODO: High-DPI support
    # boot.plymouth.extraConfig = ''
    #   DeviceScale=2
    # '';

    # Silent boot configuration
    boot.loader.timeout = lib.mkDefault 5;

    # Enable systemd in initrd for Plymouth
    # Required for proper disk encryption prompts
    boot.initrd.systemd.enable = true;

    # Silent boot configuration for clean Plymouth experience
    boot.kernelParams = [
      "quiet"
      "splash"
      "vt.global_cursor_default=0"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
    ];

    # Hide console messages during boot
    boot.consoleLogLevel = 0;
    boot.initrd.verbose = false;
  };
}
