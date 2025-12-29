{ config, lib, pkgs, hyprflakeInputs, ... }:

let
  cfg = config.hyprflake.desktop.waybar;
  waybarAutoHidePkg = hyprflakeInputs.waybar-auto-hide.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # Waybar auto-hide utility for Hyprland
  # Automatically hides Waybar when workspace is empty
  # Shows it again when cursor moves to top edge
  # Enabled by default - disable with hyprflake.desktop.waybar.autoHide = false;

  config = lib.mkIf cfg.autoHide {
    # Install waybar-auto-hide and required dependencies
    # psmisc provides killall, which waybar-auto-hide uses to send signals to waybar
    environment.systemPackages = [
      waybarAutoHidePkg
      pkgs.psmisc
    ];

    # Configure Hyprland to launch waybar-auto-hide on startup
    # Add a 2-second delay to ensure waybar IPC socket is ready
    home-manager.sharedModules = [
      (_: {
        wayland.windowManager.hyprland.settings = {
          exec-once = [ "sleep 2 && ${lib.getExe waybarAutoHidePkg}" ];
        };
      })
    ];
  };
}
