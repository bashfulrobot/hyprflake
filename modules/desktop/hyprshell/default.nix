{ config, lib, pkgs, ... }:

# Hyprshell - Window Switcher (Alt-Tab)
# Provides alt-tab functionality for Hyprland
# Uses hyprshell from nixpkgs (compatible with nixpkgs Hyprland)
# Note: Launcher functionality disabled by default
# Alt-tab is always enabled

let
  cfg = config.hyprflake.desktop.hyprshell;
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  options.hyprflake.desktop.hyprshell.enable = lib.mkEnableOption "HyprShell desktop shell" // { default = true; };

  config = lib.mkIf cfg.enable {
    # Home Manager Hyprshell configuration
    # Using services.hyprshell built into Home Manager
    home-manager.sharedModules = [
      (_: {
        services.hyprshell = {
          enable = true;
          package = pkgs.hyprshell;

          # Disable the home-manager systemd user service. It binds to
          # graphical-session.target, which activates before Hyprland's
          # exec-once runs `dbus-update-activation-environment`. Hyprshell
          # then starts without HYPRLAND_INSTANCE_SIGNATURE in its
          # environment, fails to locate the Hyprland IPC socket, gives up
          # after ~25s, and falls back to default keybinds (breaking the
          # configured alt-tab and printing "Could not get socket path!").
          # Starting hyprshell from Hyprland exec-once below guarantees the
          # env is fully populated before the daemon launches.
          systemd.enable = false;

          # Settings are passed as JSON value (not type-safe like flake version)
          settings = {
            windows = {
              # Alt-tab switcher configuration
              switch = {
                modifier = "alt"; # Use Alt key for alt-tab
                filter_by = [ "current_monitor" ]; # Only show windows on current monitor
                switch_workspaces = false; # Don't switch workspaces
              };

              # Overview disabled by omission (optional field)
              # If we wanted to enable it, we'd configure overview.launcher, overview.key, etc.
            };
          };

          # Custom CSS styling using Stylix colors
          # Matches Hyprland active/inactive window border colors
          style = stylix.mkStyle ./style.nix;
        };

        # mkAfter ensures this runs after the hyprland module's
        # dbus-update-activation-environment exec-once entry so the env is
        # propagated to the process.
        wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
          "${pkgs.hyprshell}/bin/hyprshell run"
        ];
      })
    ];
  };
}
