# GNOME Keyring, SSH, and GPG Integration for Hyprland

Complete guide to configuring automatic keyring unlock, SSH key management, and GPG integration on NixOS with Hyprland.

**Date:** 2025-12-11
**Status:** Production Configuration
**Tested On:** NixOS 26.05

---

## Table of Contents

- [Overview](#overview)
- [Required Nix Configuration](#required-nix-configuration)
- [How It Works](#how-it-works)
- [Configuration Details](#configuration-details)
- [File Locations](#file-locations)
- [Testing & Verification](#testing--verification)
- [Troubleshooting](#troubleshooting)

---

## Overview

This configuration provides:

✅ **Auto-unlock keyring on login** - GNOME Keyring unlocks with your login password
✅ **SSH key passphrase persistence** - Store SSH passphrases permanently in keyring
✅ **Graphical password prompts** - GUI dialogs for SSH and GPG passphrases
✅ **GPG signing integration** - Graphical pinentry for GPG operations
✅ **Git commit signing** - SSH-based signing works seamlessly
✅ **Browser password storage** - Applications can store secrets in keyring

### Architecture

```
Login (GDM)
    ↓
PAM Authentication
    ↓
GNOME Keyring Daemon (unlocked with login password)
    ↓
┌─────────────────────┬──────────────────────┐
│                     │                      │
gcr-ssh-agent     gpg-agent          Applications
│                     │                      │
SSH Keys          GPG Keys           Secrets Storage
(persistent)      (with pinentry)    (via libsecret)
```

---

## Required Nix Configuration

### 1. System-Level Configuration

**Location:** `modules/system/keyring/default.nix`

```nix
{ config, lib, pkgs, ... }:

{
  # PAM keyring integration - Auto-unlock on login
  # This is THE critical piece that unlocks keyring with your login password
  security.pam.services = {
    gdm.enableGnomeKeyring = true;
    gdm-password.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };

  # GPG agent - Enable for GPG operations
  # Note: pinentry program configured via home-manager gpg-agent.conf
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false; # We use gcr-ssh-agent for SSH
  };

  # Security wrapper - Allows keyring to lock memory (prevents password swapping to disk)
  security.wrappers.gnome-keyring-daemon = {
    owner = "root";
    group = "root";
    capabilities = "cap_ipc_lock=ep";
    source = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon";
  };

  # Disable default gnome-keyring systemd service (started by PAM instead)
  systemd.user.services.gnome-keyring-daemon.enable = false;

  # Polkit agent for privilege escalation dialogs
  systemd.user.services.hyprpolkitagent = {
    description = "Hyprpolkit authentication agent";
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
    };
  };

  # gcr-ssh-agent - THE KEY COMPONENT for SSH keyring integration
  # This replaces deprecated gnome-keyring SSH agent
  # Provides persistent SSH passphrase storage in GNOME Keyring
  services.gnome.gcr-ssh-agent.enable = true;

  # Environment variable for Signal (and other apps) to use keyring
  environment.variables.SIGNAL_PASSWORD_STORE = "gnome-libsecret";

  # Required packages
  environment.systemPackages = with pkgs; [
    # Core keyring packages
    gnome-keyring          # GNOME Keyring daemon
    gcr_4                  # Provides gcr4-ssh-askpass for SSH password prompts
    libsecret              # Secret storage library for applications
    seahorse               # GUI for managing keyring and GPG keys
    pinentry-all           # GPG passphrase prompting (supports multiple UI toolkits)

    # SSH key auto-loader helper script
    (writeShellScriptBin "ssh-add-keys" ''
      #!/usr/bin/env bash
      # Auto-load SSH keys into gcr-ssh-agent
      # Keys will prompt for passphrase and save to keyring

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

  # Home Manager configuration
  home-manager.sharedModules = [
    (_: {
      # GPG agent pinentry configuration
      # Points to /run/current-system/sw/bin/pinentry (pinentry-all wrapper)
      home.file.".gnupg/gpg-agent.conf".text = ''
        pinentry-program /run/current-system/sw/bin/pinentry
      '';

      # SSH client configuration
      # AddKeysToAgent: Automatically add keys when used
      # UseKeychain: macOS compatibility (ignored on Linux)
      # IdentitiesOnly: Only use explicitly specified keys
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

      # Auto-load SSH keys on Hyprland startup
      wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
        "ssh-add-keys"
      ];
    })
  ];
}
```

### 2. Desktop Environment Configuration

**Location:** `modules/desktop/hyprland/default.nix`

```nix
{
  # Environment variables for Hyprland session
  environment.sessionVariables = {
    # SSH configuration
    # CRITICAL: Must point to gcr-ssh-agent socket, NOT OpenSSH socket
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
    SSH_ASKPASS = lib.mkForce "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass";
    SSH_ASKPASS_REQUIRE = "prefer"; # Force graphical prompts when available

    # Keyring configuration
    # CRITICAL: Applications need this to find the keyring socket
    GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";
  };

  # Enable polkit for privilege escalation
  security.polkit.enable = true;
}
```

### 3. Module Import

**Location:** `modules/default.nix`

```nix
{
  imports = [
    # ... other modules ...
    ./system/keyring
    ./desktop/hyprland
    # ... other modules ...
  ];
}
```

---

## How It Works

### 1. Login Flow

```
User logs in via GDM
    ↓
PAM authentication stack executes
    ↓
pam_unix.so verifies password ✓
    ↓
pam_gnome_keyring.so (auth phase)
    Uses same password to unlock default keyring
    ↓
pam_gnome_keyring.so (session phase with auto_start)
    Ensures gnome-keyring-daemon is running
    ↓
GNOME Keyring daemon starts with --components=secrets
    Keyring is UNLOCKED (using login password)
    Registers on D-Bus as org.freedesktop.secrets
```

**Key Files:**
- `/etc/pam.d/login` - Contains `pam_gnome_keyring.so` modules
- `/etc/pam.d/gdm-password` - Inherits from login
- Security wrapper: `/run/wrappers/bin/gnome-keyring-daemon`

### 2. SSH Agent Flow

```
systemd starts gcr-ssh-agent.service
    ↓
Creates socket at $XDG_RUNTIME_DIR/gcr/ssh
    ↓
SSH_AUTH_SOCK environment variable points to this socket
    ↓
When SSH operation requires key:
    ↓
    ssh/git reads SSH_AUTH_SOCK
        ↓
        Connects to gcr-ssh-agent
            ↓
            If key not in agent → needs passphrase
                ↓
                gcr-ssh-agent invokes SSH_ASKPASS
                    ↓
                    gcr4-ssh-askpass shows graphical dialog
                        ↓
                        User enters passphrase
                            ↓
                            gcr-ssh-agent stores passphrase in GNOME Keyring
                                ↓
                                Key loaded and available for use
```

**Critical Components:**
- `services.gnome.gcr-ssh-agent.enable = true` - THE KEY enabler
- `SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh"` - Points to gcr-ssh-agent socket
- `SSH_ASKPASS` - Path to gcr4-ssh-askpass binary
- `SSH_ASKPASS_REQUIRE = "prefer"` - Forces GUI prompts over terminal

### 3. GPG Agent Flow

```
GPG operation requires key
    ↓
gpg-agent starts (socket activation)
    ↓
Reads ~/.gnupg/gpg-agent.conf
    ↓
Uses pinentry-program /run/current-system/sw/bin/pinentry
    ↓
pinentry-all wrapper selects appropriate UI:
    - pinentry-gnome3 (if GNOME/GTK available)
    - pinentry-gtk2 (fallback)
    - pinentry-curses (terminal fallback)
    ↓
Graphical dialog prompts for passphrase
    ↓
gpg-agent caches passphrase in memory (timeout configurable)
```

**Critical Components:**
- `programs.gnupg.agent.enable = true` - Enables gpg-agent
- `~/.gnupg/gpg-agent.conf` - Points to pinentry program
- `pinentry-all` package - Provides pinentry wrapper

### 4. Application Secret Storage

```
Application (browser, Signal, etc.) needs to store secret
    ↓
Uses libsecret API
    ↓
Calls D-Bus method on org.freedesktop.secrets
    ↓
gnome-keyring-daemon handles request
    ↓
If keyring unlocked (from login): stores immediately
If locked: prompts for password
    ↓
Secret encrypted with master key (derived from login password)
    ↓
Stored in ~/.local/share/keyrings/login.keyring
```

**Critical Components:**
- `GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring"` - Apps find keyring socket
- PAM unlocks keyring on login - No separate password needed
- `libsecret` package - Library for applications to use

---

## Configuration Details

### Why gcr-ssh-agent Instead of OpenSSH ssh-agent?

| Feature | OpenSSH ssh-agent | gcr-ssh-agent |
|---------|-------------------|---------------|
| SSH Protocol Support | Full | Full (as of gcr-4) |
| Keyring Integration | ❌ No | ✅ Yes |
| Persistent Passphrases | ❌ In-memory only | ✅ Stored in keyring |
| Graphical Prompts | ⚠️ Via SSH_ASKPASS | ✅ Native integration |
| Git Signing | ✅ Works | ✅ Works |
| Auto-load on Login | Manual | ✅ From keyring |

**Verdict:** gcr-ssh-agent is the modern replacement for gnome-keyring's deprecated SSH agent (deprecated since version 1:46).

**Reference:** [NixOS PR #379731](https://github.com/NixOS/nixpkgs/pull/379731)

### Why PAM Integration is Critical

Without PAM integration (`security.pam.services.*.enableGnomeKeyring`):
- Keyring daemon may start, but remains **locked**
- User must manually unlock keyring after login
- Defeats the purpose of automatic integration

With PAM integration:
- Keyring unlocked automatically with login password
- Zero additional passwords to remember
- Seamless experience like GNOME desktop

### Environment Variables Explained

#### SSH_AUTH_SOCK
**Value:** `$XDG_RUNTIME_DIR/gcr/ssh`
**Purpose:** Tells SSH clients where to find the SSH agent socket
**Critical:** MUST point to gcr-ssh-agent socket (`/run/user/1000/gcr/ssh`), NOT OpenSSH socket

#### SSH_ASKPASS
**Value:** `${pkgs.gcr_4}/libexec/gcr4-ssh-askpass`
**Purpose:** Program to invoke for graphical password prompts
**Note:** This program is NOT meant to be run directly (only called by ssh-add)

#### SSH_ASKPASS_REQUIRE
**Value:** `prefer`
**Purpose:** Forces graphical prompts when available (instead of terminal prompts)
**Options:** `never`, `prefer`, `force`

#### GNOME_KEYRING_CONTROL
**Value:** `$XDG_RUNTIME_DIR/keyring`
**Purpose:** Applications use this to find the keyring daemon socket
**Critical:** Without this, apps can't communicate with keyring for secret storage

#### SIGNAL_PASSWORD_STORE
**Value:** `gnome-libsecret`
**Purpose:** Tells Signal desktop app to use GNOME Keyring (via libsecret)
**Note:** Other apps may respect similar variables

---

## File Locations

### Runtime Files (Created Automatically)

| Path | Purpose |
|------|---------|
| `/run/user/1000/gcr/ssh` | gcr-ssh-agent socket |
| `/run/user/1000/keyring` | GNOME Keyring control socket |
| `/run/user/1000/keyring/control` | Keyring control interface |
| `/run/user/1000/keyring/pkcs11` | PKCS#11 socket |

### User Data Files

| Path | Purpose |
|------|---------|
| `~/.local/share/keyrings/login.keyring` | Default keyring (encrypted with login password) |
| `~/.local/share/keyrings/user.keystore` | User keystore |
| `~/.gnupg/gpg-agent.conf` | GPG agent pinentry configuration |
| `~/.ssh/config` | SSH client configuration |

### System Configuration Files

| Path | Purpose |
|------|---------|
| `/etc/pam.d/login` | PAM configuration with keyring modules |
| `/etc/pam.d/gdm-password` | GDM PAM configuration |
| `/etc/systemd/user/gcr-ssh-agent.service` | gcr-ssh-agent systemd service |
| `/etc/systemd/user/gpg-agent.service` | GPG agent systemd service |
| `/run/wrappers/bin/gnome-keyring-daemon` | Security wrapper with cap_ipc_lock |

---

## Testing & Verification

### 1. Verify PAM Configuration

```bash
cat /etc/pam.d/login | grep keyring
```

**Expected output:**
```
auth optional /nix/store/.../pam_gnome_keyring.so
password optional /nix/store/.../pam_gnome_keyring.so use_authtok
session optional /nix/store/.../pam_gnome_keyring.so auto_start
```

### 2. Verify GNOME Keyring Running

```bash
ps aux | grep gnome-keyring-daemon
```

**Expected output:**
```
/nix/store/.../gnome-keyring-daemon --start --foreground --components=secrets
```

### 3. Verify gcr-ssh-agent Running

```bash
systemctl --user status gcr-ssh-agent
```

**Expected output:**
```
● gcr-ssh-agent.service - GCR SSH Agent
   Active: active (running)
```

### 4. Verify Environment Variables

```bash
echo $SSH_AUTH_SOCK
echo $GNOME_KEYRING_CONTROL
echo $SSH_ASKPASS
```

**Expected output:**
```
/run/user/1000/gcr/ssh
/run/user/1000/keyring
/nix/store/.../gcr4-ssh-askpass
```

### 5. Verify Keyring Socket Exists

```bash
ls -la /run/user/1000/gcr/ssh
ls -la /run/user/1000/keyring/
```

**Expected output:**
```
srwxr-xr-x ... /run/user/1000/gcr/ssh
drwx------ ... /run/user/1000/keyring/
```

### 6. Test Keyring is Unlocked

```bash
secret-tool store --label="test" test value
secret-tool lookup test
secret-tool clear test
```

**Expected:** No password prompt (keyring already unlocked from login)

### 7. Test SSH Key Loading

```bash
# Should show no keys initially (or previously loaded keys)
ssh-add -l

# Add a key with passphrase
ssh-add ~/.ssh/id_ed25519
```

**Expected:**
1. Graphical password prompt appears (gcr4-ssh-askpass dialog)
2. After entering passphrase: "Identity added: ..."
3. Checkbox option: "Automatically unlock this key whenever I'm logged in"
4. If checked: Passphrase saved to keyring permanently

**Verify passphrase saved:**
```bash
# Reboot system, then log in
ssh-add -l
```

**Expected:** Key automatically loaded (no prompt), passphrase retrieved from keyring

### 8. Test Git Commit Signing (SSH)

```bash
# Configure git for SSH signing (if not already done)
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true

# Create a signed commit
git commit -S -m "test SSH signing"
```

**Expected:** Commit succeeds without errors (key already in agent)

### 9. Test GPG Signing

```bash
# Kill existing gpg-agent for fresh test
gpgconf --kill gpg-agent

# Sign a message
echo "test" | gpg --clearsign
```

**Expected:** Graphical pinentry prompt appears

### 10. Test Browser Password Storage

```bash
# Open browser (Firefox/Chrome)
# Visit a login page
# Enter credentials and save

# Verify stored in keyring
seahorse
```

**Expected:** Seahorse shows "Login" keyring unlocked with stored passwords

---

## Troubleshooting

### Keyring Not Unlocking on Login

**Symptom:** Applications prompt for keyring password after login

**Check PAM configuration:**
```bash
grep -r "pam_gnome_keyring" /etc/pam.d/
```

**Expected:** Should find entries in `login`, `gdm`, `gdm-password`

**Solution:** Verify `security.pam.services.*.enableGnomeKeyring = true` in config

### SSH Keys Not Loading Automatically

**Symptom:** `ssh-add -l` shows "The agent has no identities" after login

**Check gcr-ssh-agent:**
```bash
systemctl --user status gcr-ssh-agent
echo $SSH_AUTH_SOCK
```

**Expected:**
- Service active (running)
- SSH_AUTH_SOCK = `/run/user/1000/gcr/ssh`

**Solution:** Verify `services.gnome.gcr-ssh-agent.enable = true` in config

### gcr4-ssh-askpass Error: "not meant to be run directly"

**Symptom:** Error when trying to add SSH keys

**Cause:** ssh-add is trying to invoke gcr4-ssh-askpass but SSH_AUTH_SOCK points to wrong agent

**Check:**
```bash
echo $SSH_AUTH_SOCK
```

**Expected:** `/run/user/1000/gcr/ssh` (NOT `/run/user/1000/ssh-agent.sock`)

**Solution:**
1. Ensure using gcr-ssh-agent (not OpenSSH ssh-agent)
2. Verify SSH_AUTH_SOCK environment variable
3. Log out and log back in to refresh environment

### GPG Passphrase Prompts in Terminal

**Symptom:** GPG operations prompt in terminal instead of GUI

**Check gpg-agent.conf:**
```bash
cat ~/.gnupg/gpg-agent.conf
```

**Expected:** `pinentry-program /run/current-system/sw/bin/pinentry`

**Check pinentry available:**
```bash
which pinentry
/run/current-system/sw/bin/pinentry --version
```

**Solution:** Verify `home.file.".gnupg/gpg-agent.conf".text` in home-manager config

### Applications Can't Store Secrets

**Symptom:** Browser/Signal can't save passwords

**Check GNOME_KEYRING_CONTROL:**
```bash
echo $GNOME_KEYRING_CONTROL
```

**Expected:** `/run/user/1000/keyring`

**Check keyring daemon:**
```bash
ps aux | grep gnome-keyring-daemon
ls -la /run/user/1000/keyring/
```

**Solution:** Verify environment variable set in Hyprland config

### SSH Agent Socket Missing

**Symptom:** `SSH_AUTH_SOCK` not set or socket doesn't exist

**Check service:**
```bash
systemctl --user status gcr-ssh-agent
journalctl --user -u gcr-ssh-agent
```

**Solution:**
1. Restart service: `systemctl --user restart gcr-ssh-agent`
2. Check logs for errors
3. Verify `services.gnome.gcr-ssh-agent.enable = true`

---

## Summary: Minimal Required Configuration

For the absolute minimum to get keyring/SSH/GPG working:

```nix
{
  # 1. PAM integration (auto-unlock)
  security.pam.services = {
    gdm.enableGnomeKeyring = true;
    gdm-password.enableGnomeKeyring = true;
    login.enableGnomeKeyring = true;
  };

  # 2. gcr-ssh-agent (SSH keyring integration)
  services.gnome.gcr-ssh-agent.enable = true;

  # 3. GPG agent
  programs.gnupg.agent.enable = true;

  # 4. Environment variables
  environment.sessionVariables = {
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
    GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";
  };

  # 5. Required packages
  environment.systemPackages = with pkgs; [
    gnome-keyring
    gcr_4
    libsecret
    seahorse
    pinentry-all
  ];

  # 6. Home Manager GPG config
  home-manager.sharedModules = [{
    home.file.".gnupg/gpg-agent.conf".text = ''
      pinentry-program /run/current-system/sw/bin/pinentry
    '';
  }];
}
```

**That's it!** These are the essential pieces to replicate GNOME desktop's keyring functionality on Hyprland.

---

## References

- [NixOS PR #379731 - gcr-ssh-agent Implementation](https://github.com/NixOS/nixpkgs/pull/379731)
- [GNOME Keyring ArchWiki](https://wiki.archlinux.org/title/GNOME/Keyring)
- [GNOME Discourse - GDM and gcr-ssh-agent](https://discourse.gnome.org/t/gdm-gnome-keyring-and-gcr-ssh-agent-service/23498)
- [ssh-askpass Manual Page](https://man.openbsd.org/ssh-askpass.1)

---

**Last Updated:** 2025-12-11
**Tested On:** NixOS 26.05, Hyprland
