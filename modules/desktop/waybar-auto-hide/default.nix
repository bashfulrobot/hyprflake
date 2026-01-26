{ config, lib, pkgs, hyprflakeInputs, ... }:

let
  cfg = config.hyprflake.desktop.waybar;
  waybarAutoHidePkg = hyprflakeInputs.waybar-auto-hide.packages.${pkgs.stdenv.hostPlatform.system}.default;

  # Toggle script for waybar auto-hide
  # Switches between auto-hide mode and always-visible mode
  waybar-toggle-autohide = pkgs.writeShellScriptBin "waybar-toggle-autohide" ''
    export PATH="${lib.makeBinPath [ pkgs.procps pkgs.psmisc pkgs.swayosd ]}:$PATH"

    if pgrep -f waybar-auto_hide > /dev/null; then
      # Auto-hide is running - kill it and force-show waybar
      pkill -f waybar-auto_hide
      # Send SIGUSR2 to waybar to ensure it's visible
      killall -SIGUSR2 waybar 2>/dev/null || true
      swayosd-client --custom-icon view-visible-symbolic \
        --custom-message "Waybar: Always Visible"
    else
      # Auto-hide not running - start it
      ${lib.getExe waybarAutoHidePkg} &
      swayosd-client --custom-icon view-hidden-symbolic \
        --custom-message "Waybar: Auto-hide"
    fi
  '';
in
{
  # Waybar auto-hide utility for Hyprland
  # Automatically hides Waybar when workspace is empty
  # Shows it again when cursor moves to top edge
  # Enabled by default - disable with hyprflake.desktop.waybar.autoHide = false;

  config = {
    # Configure Hyprland with waybar-auto-hide toggle
    # autoHide option controls whether auto-hide starts on boot
    # Toggle keybinding is always available
    home-manager.sharedModules = [
      (_: {
        home.packages = [
          waybarAutoHidePkg
          waybar-toggle-autohide
          pkgs.psmisc
        ];

        wayland.windowManager.hyprland.settings = {
          # Only start waybar-auto-hide on boot if autoHide is enabled
          exec-once = lib.mkIf cfg.autoHide [ "sleep 2 && ${lib.getExe waybarAutoHidePkg}" ];
          bind = [
            # Toggle waybar between auto-hide and always-visible modes
            "SUPER SHIFT, W, exec, ${lib.getExe waybar-toggle-autohide}"
          ];
        };
      })
    ];
  };
}
