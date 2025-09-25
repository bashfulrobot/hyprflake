{ config, lib, pkgs, ... }:

with lib;

{
  options.services.hyprflake-keyring-hm = {
    enable = mkEnableOption "Enable GNOME keyring user session";
  };

  config = mkIf config.services.hyprflake-keyring-hm.enable {
    # GNOME Keyring user session (opinionated - always with SSH)
    services.gnome-keyring = {
      enable = true;
      components = [ "secrets" "ssh" ];
    };

    # Essential packages (always include GUI)
    home.packages = with pkgs; [
      libsecret
      gnome.seahorse
    ];

    # Session variables
    home.sessionVariables = {
      SECRETS_BACKEND = "libsecret";
      SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
    };

    # XDG desktop entry for GUI manager
    xdg.desktopEntries.seahorse = {
      name = "Passwords and Keys";
      comment = "Manage stored passwords and encryption keys";
      icon = "seahorse";
      exec = "${pkgs.gnome.seahorse}/bin/seahorse";
      categories = [ "System" "Security" ];
      mimeType = [ "application/pgp-keys" "application/x-ssh-key" ];
    };
  };
}