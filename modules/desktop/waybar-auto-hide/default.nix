{ config, lib, pkgs, hyprflakeInputs, ... }:

let
  cfg = config.programs.waybar-auto-hide;
  waybarAutoHidePkg = hyprflakeInputs.waybar-auto-hide.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # Waybar auto-hide utility for Hyprland
  # Automatically hides Waybar when workspace is empty
  # Shows it again when cursor moves to top edge

  options.programs.waybar-auto-hide = {
    enable = lib.mkEnableOption "waybar-auto-hide utility for Hyprland";
  };

  config = lib.mkIf cfg.enable {
    # Install the waybar-auto-hide package
    environment.systemPackages = [ waybarAutoHidePkg ];

    # Configure Hyprland to launch waybar-auto-hide on startup
    home-manager.sharedModules = [
      (_: {
        wayland.windowManager.hyprland.settings = {
          exec-once = [ "${lib.getExe waybarAutoHidePkg}" ];
        };
      })
    ];
  };
}
