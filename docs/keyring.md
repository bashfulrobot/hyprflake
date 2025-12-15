# GNOME Keyring Integration - Essential Config

## Purpose

Auto-unlock keyring at login, store SSH passphrases persistently, enable GPG operations with GUI prompts.

## Required Components

### 1. PAM Integration

**Why:** Unlocks keyring with login password via GDM

```nix
security.pam.services = {
  gdm.enableGnomeKeyring = true;
  gdm-password.enableGnomeKeyring = true;
  login.enableGnomeKeyring = true;
};
```

### 2. Systemd Service

**Why:** Runs daemon in persistent user session (not temporary GDM session)

```nix
systemd.user.services.gnome-keyring-daemon = {
  enable = true;
  wantedBy = [ "graphical-session-pre.target" ];
  partOf = [ "graphical-session-pre.target" ];
};
```

### 3. Security Wrapper

**Why:** Memory locking (prevents password swap to disk)

```nix
security.wrappers.gnome-keyring-daemon = {
  owner = "root";
  group = "root";
  capabilities = "cap_ipc_lock=ep";
  source = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon";
};
```

### 4. gcr-ssh-agent

**Why:** SSH agent with keyring integration for persistent passphrases

```nix
services.gnome.gcr-ssh-agent.enable = true;
```

Replaces deprecated gnome-keyring SSH agent. Stores SSH passphrases in keyring.

### 5. GPG Agent

**Why:** GPG operations with graphical password prompts

```nix
programs.gnupg.agent = {
  enable = true;
  enableSSHSupport = false;  # Using gcr-ssh-agent instead
};
```

### 6. Environment Variables

**Why:** Apps need to find keyring and SSH agent sockets

```nix
environment.variables = {
  SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
  SSH_ASKPASS = lib.mkForce "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass";
  SSH_ASKPASS_REQUIRE = "prefer";
  GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";
};
```

### 7. Packages

```nix
environment.systemPackages = with pkgs; [
  gnome-keyring    # Keyring daemon
  gcr_4            # SSH password prompts
  libsecret        # Secret storage library
  seahorse         # GUI management
  pinentry-all     # GPG password prompts
];
```

### 8. SSH Key Auto-Loader (Optional)

**Why:** Automatically discover and load all SSH keys on login

**Auto-discovery:** Finds all keys matching patterns:
- `~/.ssh/id_*` (e.g., `id_rsa`, `id_ed25519`, `id_ecdsa`)
- `~/.ssh/*_id_*` (e.g., `work_id_ed25519`, `personal_id_rsa`)
- Excludes `.pub` files and `known_hosts`

```nix
environment.systemPackages = with pkgs; [
  (writeShellScriptBin "ssh-add-keys" ''
    #!/usr/bin/env bash
    [ -z "$SSH_AUTH_SOCK" ] && exit 0

    # Auto-discover all id_* private keys
    for key in "$HOME"/.ssh/id_* "$HOME"/.ssh/*_id_*; do
      [[ -f "$key" && "$key" != *.pub && "$key" != *known_hosts* ]] && \
        ssh-add "$key" 2>/dev/null
    done
  '')
];
```

**Supported key names:**
- Standard: `id_rsa`, `id_ed25519`, `id_ecdsa`, `id_dsa`
- Custom prefix: `work_id_ed25519`, `github_id_rsa`, `deploy_id_ecdsa`
- Any `id_*` pattern in `~/.ssh/`

### 9. Home Manager Config

**Why:** GPG pinentry + SSH auto-add + key loading

```nix
home-manager.sharedModules = [
  (_: {
    # GPG pinentry
    home.file.".gnupg/gpg-agent.conf".text = ''
      pinentry-program /run/current-system/sw/bin/pinentry
    '';

    # SSH auto-add keys
    programs.ssh = {
      enable = true;
      extraConfig = ''
        Host *
          AddKeysToAgent yes
          IdentitiesOnly yes
      '';
    };

    # Run SSH key loader on startup
    wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
      "ssh-add-keys"
    ];
  })
];
```

## How It Works

### Flow

```
GDM Login → PAM unlocks keyring → systemd starts daemon (persistent)
→ gcr-ssh-agent started → Hyprland exec-once runs ssh-add-keys
→ Keys loaded, passphrases stored in keyring
```

### Key Changes from Default NixOS

1. **Enable systemd service** (default disables it, causes logout kill)
2. **gcr-ssh-agent** (not gnome-keyring's deprecated SSH agent)
3. **SSH_AUTH_SOCK** points to gcr socket (not OpenSSH)
4. **PAM integration** on gdm, gdm-password, AND login

## Verification

```bash
# Keyring unlocked
secret-tool lookup nonexistent key  # No password prompt = unlocked

# Daemon running in user session (not GDM session)
systemctl --user status gnome-keyring-daemon

# SSH agent working
echo $SSH_AUTH_SOCK  # Should be /run/user/1000/gcr/ssh
ssh-add -l

# Environment vars set
echo $GNOME_KEYRING_CONTROL  # Should be /run/user/1000/keyring
```

## Reference

See `modules/system/keyring/default.nix` for complete implementation.
