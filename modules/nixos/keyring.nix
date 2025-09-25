{ config, lib, pkgs, ... }:

with lib;

{
  options.services.hyprflake-keyring = {
    enable = mkEnableOption "Enable GNOME keyring with auto-unlock";
  };

  config = mkIf config.services.hyprflake-keyring.enable {
    # GNOME Keyring (opinionated choice - always GTK/GNOME stack)
    services.gnome.gnome-keyring.enable = true;

    # PAM configuration for auto-unlock on all display managers
    security.pam.services = {
      login.enableGnomeKeyring = true;
      sddm.enableGnomeKeyring = true;
      gdm.enableGnomeKeyring = true;
      greetd.enableGnomeKeyring = true;
    };

    # Essential packages (opinionated - always include GUI)
    environment.systemPackages = with pkgs; [
      libsecret
      gnome.gnome-keyring
      gnome.seahorse  # Always include GUI manager
    ];

    # D-Bus services
    services.dbus.packages = with pkgs; [
      gnome.gnome-keyring
    ];

    # Session variables
    environment.sessionVariables = {
      GNOME_KEYRING_CONTROL = "/run/user/$UID/keyring";
      SSH_AUTH_SOCK = "/run/user/$UID/keyring/ssh";
      SECRETS_BACKEND = "libsecret";
    };

    # XDG autostart for session integration
    environment.etc."xdg/autostart/gnome-keyring-daemon.desktop".text = ''
      [Desktop Entry]
      Type=Application
      Name=GNOME Keyring Daemon
      Exec=${pkgs.gnome.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets,ssh
      NoDisplay=true
      X-GNOME-Autostart-Phase=Initialization
      X-GNOME-AutoRestart=true
      X-GNOME-Autostart-Notify=true
    '';
  };
}