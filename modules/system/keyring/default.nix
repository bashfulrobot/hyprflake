{ config, lib, pkgs, ... }:

{
  # GNOME Keyring integration for Hyprland
  # Provides secure credential storage, SSH key management, and browser password integration
  # Based on nixcfg production configuration

  # Enable PAM keyring for automatic unlock on login
  # This unlocks the keyring automatically when you log in with GDM
  security.pam.services = {
    gdm.enableGnomeKeyring = true;
    gdm-password.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };

  # Security wrapper for gnome-keyring-daemon with proper capabilities
  # This allows the keyring to lock memory pages (prevents password swapping to disk)
  security.wrappers.gnome-keyring-daemon = {
    owner = "root";
    group = "root";
    capabilities = "cap_ipc_lock=ep";
    source = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon";
  };

  # Disable the default NixOS keyring service to prevent conflicts
  # We'll start our own services with specific components
  systemd.user.services.gnome-keyring-daemon.enable = false;

  # GNOME Keyring SSH component - works with PAM-unlocked keyring
  # PAM handles secrets component unlock, this adds SSH functionality
  systemd.user.services.gnome-keyring-ssh = {
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
  systemd.user.services.gnome-keyring-secrets = {
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

  # Set Signal to use gnome-libsecret for password storage
  # This ensures Signal (and other apps) use the keyring
  environment.variables.SIGNAL_PASSWORD_STORE = "gnome-libsecret";

  # SSH key auto-loader script
  # This script automatically loads SSH keys into the keyring on startup
  environment.systemPackages = with pkgs; [
    gnome-keyring
    (writeShellScriptBin "ssh-add-keys" ''
      #!/usr/bin/env bash
      # Auto-load SSH keys into GNOME Keyring
      # Looks for keys in ~/.ssh/ and adds them to the keyring

      # Common SSH key patterns
      SSH_KEYS=(
        "$HOME/.ssh/id_rsa"
        "$HOME/.ssh/id_ed25519"
        "$HOME/.ssh/id_ecdsa"
      )

      # Check if SSH agent is running
      if [ -z "$SSH_AUTH_SOCK" ]; then
        echo "SSH agent not running, skipping key loading"
        exit 0
      fi

      # Add each key that exists
      for key in "''${SSH_KEYS[@]}"; do
        if [ -f "$key" ]; then
          echo "Adding SSH key: $key"
          ssh-add "$key" 2>/dev/null || echo "Failed to add $key (may already be loaded)"
        fi
      done
    '')
  ];

  # Home Manager configuration for keyring integration
  home-manager.sharedModules = [
    (_: {
      # Add ssh-add-keys to Hyprland exec-once
      # This ensures SSH keys are loaded when Hyprland starts
      wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
        "ssh-add-keys"
      ];
    })
  ];
}
