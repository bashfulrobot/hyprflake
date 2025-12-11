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

  # GPG agent with graphical pinentry
  # Enables GPG operations (signing, encryption) with GUI password prompts
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false; # We use separate OpenSSH agent for full protocol support
    pinentryPackage = pkgs.pinentry-gnome3; # Graphical password prompts for GPG operations
  };

  # Security wrapper for gnome-keyring-daemon with proper capabilities
  # This allows the keyring to lock memory pages (prevents password swapping to disk)
  security.wrappers.gnome-keyring-daemon = {
    owner = "root";
    group = "root";
    capabilities = "cap_ipc_lock=ep";
    source = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon";
  };

  # Systemd user services for GNOME Keyring
  systemd.user.services = {
    # Disable the default NixOS keyring service to prevent conflicts
    # PAM will start gnome-keyring-daemon with secrets/pkcs11 components
    gnome-keyring-daemon.enable = false;

    # Polkit authentication agent - required for password prompts and credential dialogs
    # Without this, SSH passphrase prompts cannot display properly
    hyprpolkitagent = {
      description = "Hyprpolkit authentication agent";
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

  # Use OpenSSH ssh-agent instead of gcr-ssh-agent
  # gcr-ssh-agent has limited protocol support and doesn't work with git signing or some SSH operations
  # OpenSSH ssh-agent provides full protocol support and caches passphrases in memory
  # Note: SSH passphrases are NOT persistently stored in keyring (use gcr-ssh-agent for that, with protocol limitations)
  systemd.user.services.ssh-agent = {
    description = "OpenSSH Agent";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "simple";
      Environment = "SSH_AUTH_SOCK=%t/ssh-agent.sock";
      ExecStart = "${pkgs.openssh}/bin/ssh-agent -D -a %t/ssh-agent.sock";
      Restart = "on-failure";
    };
  };

  # Set Signal to use gnome-libsecret for password storage
  # This ensures Signal (and other apps) use the keyring
  environment.variables.SIGNAL_PASSWORD_STORE = "gnome-libsecret";

  # SSH key auto-loader script
  # This script automatically loads SSH keys into the keyring on startup
  environment.systemPackages = with pkgs; [
    # Core keyring packages
    gnome-keyring
    gcr_4 # Provides gcr4-ssh-askpass for graphical password prompts
    libsecret # Secret storage library for applications
    seahorse # GUI for managing keyring and GPG keys
    pinentry-gnome3 # Graphical pinentry for GPG (matches gpg-agent config)
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
      # Add keyring helpers to Hyprland exec-once
      # Note: polkit agent is started by systemd service (hyprpolkitagent.service), not exec-once
      # This only loads SSH keys automatically on Hyprland startup
      wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
        "ssh-add-keys"
      ];
    })
  ];
}
