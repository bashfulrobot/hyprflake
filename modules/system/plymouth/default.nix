{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake.plymouth;
in
{
  options.hyprflake.plymouth = {
    enable = lib.mkEnableOption "Plymouth boot splash screen with Hyprland wallpaper";
  };

  config = lib.mkIf cfg.enable {
    # Enable Plymouth with bgrt theme
    # bgrt supports firmware logos and encryption prompts
    boot.plymouth = {
      enable = true;
      theme = lib.mkForce "bgrt";

      # Use the same wallpaper as Hyprland
      # This creates a seamless boot-to-desktop experience
      logo = config.hyprflake.wallpaper;

      # Plymouth configuration with Stylix colors
      extraConfig = ''
        DeviceScale=2
      '';
    };

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
