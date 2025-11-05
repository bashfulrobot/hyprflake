{ config, lib, pkgs, ... }:

{
  # Comprehensive GNOME Keyring configuration
  # Handles password storage, SSH keys, and secrets management
  # Critical for SSH authentication and application passwords

  # Enable GNOME Keyring service
  services.gnome.gnome-keyring.enable = true;

  # Systemd user services for keyring components
  systemd.user.services = {
    # GNOME Keyring SSH component - provides SSH agent functionality
    gnome-keyring-ssh = {
      description = "GNOME Keyring SSH component";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=ssh";
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStopSec = 10;
      };
    };

    # GNOME Keyring Secrets component - handles password storage and unlock
    gnome-keyring-secrets = {
      description = "GNOME Keyring Secrets component";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "forking";
        ExecStart = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon --start --components=secrets";
        Restart = "on-failure";
        RestartSec = 2;
        TimeoutStopSec = 10;
      };
    };

    # Hyprpolkitagent - Modern polkit authentication agent for Hyprland
    hyprpolkitagent = {
      description = "Hyprpolkitagent - Polkit authentication agent";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };

  # Disable the default NixOS keyring service to prevent conflicts
  systemd.user.services.gnome-keyring-daemon.enable = false;

  # PAM integration for automatic keyring unlock on login
  security.pam.services = {
    gdm.enableGnomeKeyring = true;
    gdm-password.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };

  # Security wrapper for gnome-keyring-daemon with proper capabilities
  security.wrappers.gnome-keyring-daemon = {
    owner = "root";
    group = "root";
    capabilities = "cap_ipc_lock=ep";
    source = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon";
  };

  # Essential keyring packages
  environment.systemPackages = with pkgs; [
    gnome-keyring
    seahorse  # GUI for managing keys/passwords
    gcr_4     # Modern GCR for keyring password prompts
    libsecret
  ];
}
