{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake.desktop.displayManager;
in
{
  options.hyprflake.desktop.displayManager.enable = lib.mkEnableOption "GDM display manager. Note: also propagates keyboard layout from hyprflake.desktop.keyboard" // { default = true; };

  config = lib.mkIf cfg.enable {
    # GDM Display Manager configuration for Hyprland
    # Provides graphical login with Wayland support

    services = {
      # GDM with Wayland (GNOME 50+ is Wayland-only; the wayland option was
      # removed upstream, so we no longer set it explicitly).
      displayManager = {
        gdm = {
          enable = true;
        };

        # Set Hyprland as default session
        defaultSession =
          if config.programs.hyprland.withUWSM or false
          then "hyprland-uwsm"
          else "hyprland";
      };

      # X server configuration for keymap
      xserver = {
        enable = true;

        # Configure keymap from hyprflake.desktop options
        xkb = {
          inherit (config.hyprflake.desktop.keyboard) layout variant;
        };

        # Exclude unnecessary X11 packages
        excludePackages = [ pkgs.xterm ];
      };
    };

    # GDM 50's greeter Exec=gnome-session, but nixpkgs only adds gnome-session
    # to the display-manager service PATH — not the gdm-greeter user's PATH.
    # Without this, the greeter exits with "Unable to run session" and the
    # login screen is blank. Drop once nixpkgs grows the systemPackages entry.
    environment.systemPackages = [ pkgs.gnome-session ];

    # GDM 50's greeter session is gnome-session, which calls gsm_session_fill
    # → find_valid_session_keyfile to locate gnome-login.session. That walks
    # XDG_DATA_DIRS. nixpkgs adds ${sessionData.desktops}/share to system-wide
    # XDG_DATA_DIRS but NOT gdm or gnome-session — so the greeter can find
    # hyprland.desktop (wayland-sessions/) but not gnome-login.session
    # (gnome-session/sessions/). Result: greeter logs "Failed to fill session"
    # on every retry and the login screen is blank.
    environment.sessionVariables.XDG_DATA_DIRS = [
      "${pkgs.gdm}/share"
      "${pkgs.gnome-session}/share"
    ];
  };
}
