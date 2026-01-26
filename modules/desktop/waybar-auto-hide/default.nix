{ config, lib, pkgs, hyprflakeInputs, ... }:

let
  cfg = config.hyprflake.desktop.waybar;
  waybarAutoHidePkg = hyprflakeInputs.waybar-auto-hide.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Toggle script for waybar auto-hide
  # Switches between auto-hide mode and always-visible mode
  waybar-toggle-autohide = pkgs.writeShellApplication {
    name = "waybar-toggle-autohide";
    runtimeInputs = [
      pkgs.procps
      pkgs.psmisc
      pkgs.swayosd
      waybarAutoHidePkg
    ];
    text = ''
      if pgrep -f waybar-auto-hide > /dev/null; then
        # Auto-hide is running - kill it and force-show waybar
        pkill -f waybar-auto-hide
        # Send SIGUSR2 to waybar to ensure it's visible
        killall -SIGUSR2 waybar 2>/dev/null || true
        swayosd-client --custom-icon view-visible-symbolic \
          --custom-message "Waybar: Always Visible"
      else
        # Auto-hide not running - start it
        waybar-auto-hide &
        swayosd-client --custom-icon view-hidden-symbolic \
          --custom-message "Waybar: Auto-hide"
      fi
    '';
  };
in
{
  # Waybar auto-hide utility for Hyprland
  # Automatically hides Waybar when workspace is empty
  # Shows it again when cursor moves to top edge
  # Enabled by default - disable with hyprflake.desktop.waybar.autoHide = false;

  # Install packages at top level with conditional
  environment.systemPackages = lib.mkIf cfg.autoHide [
    waybarAutoHidePkg
    waybar-toggle-autohide
    pkgs.psmisc
  ];

  config = lib.mkIf cfg.autoHide {
    # Configure Hyprland to launch waybar-auto-hide on startup
    # Add a 2-second delay to ensure waybar IPC socket is ready
    # Also add keybinding to toggle auto-hide mode
    home-manager.sharedModules = [
      (_: {
        wayland.windowManager.hyprland.settings = {
          exec-once = [ "sleep 2 && ${lib.getExe waybarAutoHidePkg}" ];
          bind = [
            # Toggle waybar between auto-hide and always-visible modes
            "SUPER SHIFT, W, exec, ${lib.getExe waybar-toggle-autohide}"
          ];
        };
      })
    ];
  };
}
