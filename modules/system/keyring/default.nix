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
  # Note: pinentry program is configured via gpg-agent.conf in home-manager
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false; # We use separate OpenSSH agent for full protocol support
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
    # Enable the systemd user service to run in the persistent user session
    # This prevents the daemon from being killed when the GDM login session ends
    # PAM will still handle unlocking the keyring with the login password
    gnome-keyring-daemon = {
      enable = true;
      wantedBy = [ "graphical-session-pre.target" ];
      partOf = [ "graphical-session-pre.target" ];
    };

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

  # Use gcr-ssh-agent for keyring integration (from nixcfg/GNOME desktop)
  # gcr-ssh-agent integrates with GNOME Keyring for persistent passphrase storage
  # Replaces deprecated gnome-keyring SSH agent (deprecated since version 1:46)
  # See: https://github.com/NixOS/nixpkgs/pull/379731
  services.gnome.gcr-ssh-agent.enable = true;

  # Environment variables for keyring and SSH agent integration
  # These tell applications where to find the keyring and SSH agent sockets
  environment.variables = {
    # Point SSH agent to gcr-ssh-agent socket
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
    # Use gcr4 for graphical SSH passphrase prompts
    SSH_ASKPASS = lib.mkForce "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass";
    SSH_ASKPASS_REQUIRE = "prefer";
    # Point applications to GNOME Keyring control socket
    GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";
    # Set Signal to use gnome-libsecret for password storage
    SIGNAL_PASSWORD_STORE = "gnome-libsecret";
  };

  # SSH key auto-loader script
  # This script automatically loads SSH keys into the keyring on startup
  environment.systemPackages = with pkgs; [
    # Core keyring packages
    gnome-keyring
    gcr_4 # Provides gcr4-ssh-askpass for graphical password prompts
    libsecret # Secret storage library for applications
    seahorse # GUI for managing keyring and GPG keys
    pinentry-all # GPG passphrase prompting (from nixcfg)
    (writeShellScriptBin "ssh-add-keys" ''
      #!/usr/bin/env bash
      # Auto-discover and load SSH keys into GNOME Keyring
      # Finds all id_* private key files in ~/.ssh/ (excludes .pub and known_hosts)

      # Check if SSH agent is running
      if [ -z "$SSH_AUTH_SOCK" ]; then
        echo "SSH agent not running, skipping key loading"
        exit 0
      fi

      # Auto-discover all id_* private keys (exclude .pub files)
      for key in "$HOME"/.ssh/id_* "$HOME"/.ssh/*_id_*; do
        # Skip if doesn't exist, is a .pub file, or is a known_hosts file
        if [[ -f "$key" && "$key" != *.pub && "$key" != *known_hosts* ]]; then
          echo "Adding SSH key: $key"
          ssh-add "$key" 2>/dev/null || echo "Failed to add $key (may already be loaded)"
        fi
      done
    '')
  ];

  # Home Manager configuration for keyring integration
  home-manager.sharedModules = [
    (_: {
      # GPG agent configuration (from nixcfg)
      # https://discourse.nixos.org/t/cant-get-gnupg-to-work-no-pinentry/15373/13?u=brnix
      home.file.".gnupg/gpg-agent.conf".text = ''
        pinentry-program /run/current-system/sw/bin/pinentry
      '';

      # SSH configuration (from nixcfg)
      programs.ssh = {
        enable = true;
        extraConfig = ''
          # Global Config
          Host *
            IgnoreUnknown UseKeychain
            AddKeysToAgent yes
            UseKeychain yes
            IdentitiesOnly yes
        '';
      };

      # Add keyring helpers to Hyprland exec-once
      # Note: polkit agent is started by systemd service (hyprpolkitagent.service), not exec-once
      # This only loads SSH keys automatically on Hyprland startup
      wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
        "ssh-add-keys"
      ];
    })
  ];
}
