{ config, lib, pkgs, ... }:

{
  # Keyring services for password management
  # gnome-keyring for secrets, seahorse for GUI management

  services.gnome.gnome-keyring.enable = true;

  environment.systemPackages = with pkgs; [
    gnome-keyring
    seahorse  # GUI for managing keys/passwords
  ];

  # Enable PAM integration
  security.pam.services.login.enableGnomeKeyring = true;
}
