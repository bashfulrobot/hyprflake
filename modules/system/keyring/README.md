# GNOME Keyring Integration

## Overview

The keyring module provides comprehensive GNOME Keyring integration for Hyprland, enabling:
- Secure credential storage (passwords, tokens, secrets)
- SSH key management with automatic loading
- Browser password integration
- Application secret storage (Signal, etc.)
- Automatic unlock on login via GDM

## Architecture

This module integrates with multiple parts of hyprflake:

### System-Level (`modules/system/keyring.nix`)
- **PAM Integration**: Enables keyring unlock via GDM login (starts gnome-keyring-daemon with secrets/pkcs11)
- **Systemd Socket**: Enables gcr-ssh-agent.socket for SSH key management (gnome-keyring 46+)
- **Security Wrapper**: Provides memory locking capabilities for the keyring daemon
- **Helper Scripts**: `ssh-add-keys` for automatic SSH key loading

### Desktop Integration (`modules/desktop/hyprland/default.nix`)
- **Environment Variables**: Already configured
  - `SSH_AUTH_SOCK`: Points to `/run/user/$UID/gcr/ssh` (set by gcr-ssh-agent.socket)
  - `SSH_ASKPASS`: Uses gcr4-ssh-askpass for graphical password prompts
  - `SIGNAL_PASSWORD_STORE`: Uses gnome-libsecret
- **Packages**: gcr_4, gnome-keyring, libsecret, seahorse, pinentry-all included
- **Exec-Once**: ssh-add-keys auto-starts to load keys

## Components

### 1. PAM Configuration
```nix
security.pam.services = {
  gdm.enableGnomeKeyring = true;
  gdm-password.enableGnomeKeyring = true;
  login.enableGnomeKeyring = true;
};
```
**Purpose**: Automatically starts gnome-keyring-daemon and unlocks it when you log in with your password. PAM starts the daemon with `secrets` and `pkcs11` components.

### 2. SSH Agent (gcr-ssh-agent)

**IMPORTANT**: gnome-keyring 46+ uses `gcr-ssh-agent` instead of the old `--components=ssh` approach.

**gcr-ssh-agent.socket**
- Socket-activated systemd service
- Creates `/run/user/$UID/gcr/ssh` socket
- Automatically sets `SSH_AUTH_SOCK` environment variable via systemd
- Manages SSH key storage and agent functionality
- Keys persist across sessions when added to keyring
- Integrates with `ssh-add` command

**gcr-ssh-agent.service**
- Started automatically when the socket is accessed
- Provides the SSH agent implementation
- Uses gnome-keyring's secrets component for password storage

### 3. Security Wrapper
```nix
security.wrappers.gnome-keyring-daemon = {
  capabilities = "cap_ipc_lock=ep";
};
```
**Purpose**: Allows keyring to lock memory pages, preventing passwords from being swapped to disk (security hardening).

### 4. SSH Key Auto-Loader
The `ssh-add-keys` script automatically loads common SSH keys:
- `~/.ssh/id_rsa`
- `~/.ssh/id_ed25519`
- `~/.ssh/id_ecdsa`

**Usage**: Runs automatically on Hyprland startup via exec-once.

## Usage

### For Users

The keyring is fully automatic. When you:
1. Log in via GDM with your password
2. The keyring is automatically unlocked
3. SSH keys are automatically loaded
4. Applications can store/retrieve credentials

### Managing SSH Keys

**Add a key manually:**
```bash
ssh-add ~/.ssh/my_key
```

**List loaded keys:**
```bash
ssh-add -l
```

**Remove all keys:**
```bash
ssh-add -D
```

### Managing Credentials

**GUI Tool:**
```bash
seahorse
```
Seahorse provides a graphical interface to view and manage stored passwords and keys.

**Command Line:**
```bash
# List secrets
secret-tool search --all

# Store a secret
secret-tool store --label="My Password" service myapp username myuser

# Retrieve a secret
secret-tool lookup service myapp username myuser
```

## Integration with Applications

### Browsers
- **Chrome/Chromium**: Automatically uses keyring for password storage
- **Firefox**: Configure via `about:config` → `security.use_keyring = true`

### Signal Desktop
Environment variable `SIGNAL_PASSWORD_STORE=gnome-libsecret` is set, enabling keyring integration.

### Git Credentials
```bash
git config --global credential.helper gnome-keyring
```

### SSH
Works automatically via `SSH_AUTH_SOCK` environment variable.

## Troubleshooting

### Keyring Not Unlocking
1. Verify you're logging in via GDM (not auto-login)
2. Check systemd services:
   ```bash
   systemctl --user status gnome-keyring-ssh
   systemctl --user status gnome-keyring-secrets
   ```

### SSH Keys Not Loading
1. Check if `ssh-add-keys` ran:
   ```bash
   ssh-add -l
   ```
2. Manually run: `ssh-add-keys`
3. Verify keys exist in `~/.ssh/`

### Applications Not Using Keyring
1. Verify environment variables:
   ```bash
   echo $GNOME_KEYRING_CONTROL
   echo $SSH_AUTH_SOCK
   ```
2. Restart the application

## Security Considerations

- **Memory Protection**: Security wrapper prevents password swapping to disk
- **Session-Based**: Keyring locks when you log out
- **Encryption**: Keyring data is encrypted on disk
- **Auto-Lock**: Respects screen lock (via hyprlock integration)

## Comparison with nixcfg

This implementation is based on the production-tested nixcfg configuration with the following refinements:

**Improvements:**
- ✅ Cleaner separation (system module vs desktop integration)
- ✅ Better documentation
- ✅ Reusable across different desktop environments

**Maintained Features:**
- ✅ PAM integration
- ✅ Separate SSH/Secrets services
- ✅ Security wrapper with capabilities
- ✅ SSH key auto-loading
- ✅ Application integration (Signal, etc.)

## Dependencies

**Runtime:**
- gnome-keyring
- gcr_4 (GCR 4.x for modern password prompts)
- libsecret (secret storage library)
- seahorse (GUI management tool)
- pinentry-all (GPG passphrase prompting)

**Integration:**
- GDM display manager (for PAM unlock)
- Hyprland (for exec-once integration)

## Future Enhancements

- [ ] Optional auto-lock on idle (coordinate with hypridle)
- [ ] Configurable SSH key paths
- [ ] GPG key integration
- [ ] Biometric unlock support (fingerprint)
