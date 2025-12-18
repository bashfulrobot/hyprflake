{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake.plymouth;

  # Extract Catppuccin variant from colorScheme (e.g., "catppuccin-mocha" -> "mocha")
  isCatppuccin = lib.hasPrefix "catppuccin-" config.hyprflake.colorScheme;
  catppuccinVariant = lib.removePrefix "catppuccin-" config.hyprflake.colorScheme;
in
{
  options.hyprflake.plymouth = {
    enable = lib.mkEnableOption "Plymouth boot splash screen with Hyprland wallpaper";
  };

  config = lib.mkIf cfg.enable {
    # Enable Plymouth boot splash with theme matching hyprflake.colorScheme
    boot.plymouth = {
      enable = true;

      # Use Catppuccin Plymouth theme if colorScheme is catppuccin-*
      # Otherwise fall back to Circle HUD
      theme = if isCatppuccin then "catppuccin-${catppuccinVariant}" else "circle_hud";

      themePackages = if isCatppuccin then [
        (pkgs.catppuccin-plymouth.override { variant = catppuccinVariant; })
      ] else [
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
