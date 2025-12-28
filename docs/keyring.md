# GNOME Keyring Integration

Complete keyring setup for Hyprland with automatic unlock, SSH/GPG integration, and persistent passphrase storage.

## What You Get

This configuration provides:

### 🔓 Automatic Keyring Unlock

- **At login:** Keyring unlocks with your GDM password
- **At screen unlock:** Keyring unlocks with your hyprlock password

### 🔑 SSH Key Management

- **Auto-discovery:** All SSH keys matching `~/.ssh/id_*` or `~/.ssh/*_id_*` loaded automatically
- **Persistent passphrases:** SSH passphrases stored in keyring after first use
- **Cross-session:** Passphrases persist across reboots
- **No re-entry:** Never re-enter SSH passphrases after first unlock

### 🔐 GPG Key Management

- **GUI prompts:** Graphical password dialogs for GPG operations

### 🛡️ Application Integration

**Explicit Configuration Required:**

- **Signal:** `SIGNAL_PASSWORD_STORE = "gnome-libsecret"` environment variable
- **VS Code:** `--password-store=gnome-libsecret` command-line override

**Works Automatically (no config needed):**

- **Browsers:** Chrome, Firefox store passwords in keyring automatically
- **Any libsecret app:** Works with keyring via `GNOME_KEYRING_CONTROL`

### 🔒 Security

- **Memory locking:** Passwords never swapped to disk
- **PAM integration:** Keyring tied to login password
- **Encrypted storage:** All secrets encrypted at rest

## Common Tiling WM Pitfall

**Problem:** Keyring works on login but stays locked after screen unlock

**Root Cause:** Missing PAM integration for screen locker (hyprlock)

**Solution:** Must add `hyprlock.enableGnomeKeyring = true` to `security.pam.services`

- Desktop environments (GNOME, KDE) configure this automatically
- Tiling WM users configure GDM login (works) but forget screen locker (breaks)
- Symptoms only appear after first screen lock, not immediately
- Very confusing to debug without understanding PAM flow

## How It Works

### Startup Flow

```
Boot
  ↓
GDM Login with password
  ↓
PAM starts gnome-keyring-daemon and unlocks it with login password
  ↓
User session begins
  ↓
gcr-ssh-agent waits for keyring socket (prevents race condition)
  ↓
gcr-ssh-agent starts (provides SSH agent with keyring integration)
  ↓
hyprpolkitagent starts (provides password prompt UI)
  ↓
GPG agent starts (provides GPG operations with GUI prompts)
  ↓
Hyprland starts
  ↓
ssh-add-keys runs automatically
  ↓
All SSH keys discovered and loaded
  ↓
First SSH operation → passphrase prompt → stored in keyring
  ↓
Subsequent SSH operations → no prompt (passphrase from keyring)
```

### Screen Lock/Unlock Flow

```
Lock screen (Super+L or timeout)
  ↓
hyprlock activated
  ↓
Enter password
  ↓
PAM authenticates and unlocks keyring
  ↓
Keyring available (SSH keys, secrets, app passwords)
  ↓
Resume work seamlessly
```

## Required Components

### 1. PAM Integration

**Purpose:** Auto-unlock keyring with login/unlock password

```nix
security.pam.services = {
  gdm.enableGnomeKeyring = true;
  gdm-password.enableGnomeKeyring = true;
  login.enableGnomeKeyring = true;
  hyprlock.enableGnomeKeyring = true;  # Critical for screen unlock!
};
```

**How PAM works:**

- PAM starts `gnome-keyring-daemon` on login (not systemd!)
- Daemon runs with `secrets` and `pkcs11` components
- Keyring unlocked automatically with your password
- Daemon persists for entire user session
- **Must include hyprlock** for screen unlock to work

### 2. Security Wrapper

**Purpose:** Prevent password swapping to disk

```nix
security.wrappers.gnome-keyring-daemon = {
  owner = "root";
  group = "root";
  capabilities = "cap_ipc_lock=ep";
  source = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon";
};
```

**What this does:**
The `cap_ipc_lock` capability allows gnome-keyring-daemon to lock memory pages containing passwords, SSH passphrases, and secrets, preventing them from being swapped to disk. This is critical because:

- Linux can swap any process memory to disk when RAM is low
- Swap is often unencrypted, even on encrypted systems
- Passwords written to swap could be recovered using forensic tools

**Why security.wrappers:**
The Nix store is read-only and cannot contain setcap binaries. NixOS uses `security.wrappers` to create a wrapper at `/run/wrappers/bin/gnome-keyring-daemon` with the necessary capability, while keeping the original binary in the read-only Nix store.

**Note:** This configuration may not be necessary on modern systems. Since Linux 2.6.9 (2007), memory can be locked up to `RLIMIT_MEMLOCK` without requiring `cap_ipc_lock`. Additionally, some distributions (Debian, Fedora) have moved away from using this capability due to conflicts with GLib 2.70+ security hardening. More research is needed to determine if this can be safely removed.

**Further reading:**

- [GNOME Keyring capability code](https://github.com/GNOME/gnome-keyring/blob/main/daemon/gkd-capability.c) - Implementation details
- [GNOME Keyring memory security](https://wiki.gnome.org/Projects/GnomeKeyring/Memory) - Why memory locking is used
- [Linux capabilities(7) man page](https://man7.org/linux/man-pages/man7/capabilities.7.html) - CAP_IPC_LOCK explained
- [mlock(2) man page](https://man7.org/linux/man-pages/man2/mlock.2.html) - Memory locking syscall
- [NixOS security.wrappers docs](https://mynixos.com/nixpkgs/option/security.wrappers) - How NixOS implements wrappers
- [NixOS security.wrappers implementation](https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/security/wrappers/default.nix) - Source code

### 3. gcr-ssh-agent

**Purpose:** SSH agent with keyring integration for persistent passphrases

```nix
services.gnome.gcr-ssh-agent.enable = true;
```

- Replaces deprecated gnome-keyring SSH agent (deprecated since 1:46)
- Stores SSH passphrases in GNOME Keyring automatically
- Passphrases persist across reboots (unlike OpenSSH ssh-agent)
- See: <https://github.com/NixOS/nixpkgs/pull/379731>

**Critical: Race condition prevention**

gcr-ssh-agent must wait for gnome-keyring-daemon to be ready:

```nix
systemd.user.services.gcr-ssh-agent = {
  serviceConfig = {
    ExecStartPre = pkgs.writeShellScript "wait-for-keyring" ''
      # Wait up to 10 seconds for keyring control socket
      for i in {1..20}; do
        if [ -S "$XDG_RUNTIME_DIR/keyring/control" ]; then
          sleep 0.5
          exit 0
        fi
        sleep 0.5
      done
      echo "Warning: keyring control socket not found after 10 seconds" >&2
      exit 0
    '';
  };
};
```

Without this wait script, gcr-ssh-agent may start before keyring is ready, causing SSH key loading to fail.

### 4. GPG Agent

**Purpose:** GPG operations with graphical password prompts

```nix
programs.gnupg.agent = {
  enable = true;
  enableSSHSupport = false;  # Using gcr-ssh-agent instead
};
```

Configured with pinentry for GUI password prompts:

```nix
home.file.".gnupg/gpg-agent.conf".text = ''
  pinentry-program /run/current-system/sw/bin/pinentry
'';
```

**GPG passphrase storage:**

- When prompted, check "Save in password manager" to store in keyring
- If not saved, passphrases are cached for the session only
- Cached passphrases cleared when gpg-agent restarts or session ends

### 5. Polkit Authentication Agent

**Purpose:** Display password prompts and credential dialogs

```nix
systemd.user.services.hyprpolkitagent = {
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
```

**Critical:** Without this, SSH and GPG passphrase prompts cannot display. Runs as systemd service (not Hyprland exec-once) for reliability.

### 6. Environment Variables

**Purpose:** Tell applications where to find keyring and agents

```nix
environment.variables = {
  SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
  SSH_ASKPASS = lib.mkForce "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass";
  GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";
  SIGNAL_PASSWORD_STORE = "gnome-libsecret";
};
```

- `SSH_AUTH_SOCK`: Points to gcr-ssh-agent socket (not OpenSSH)
- `SSH_ASKPASS`: GUI program for SSH passphrase prompts
- `GNOME_KEYRING_CONTROL`: Keyring daemon socket for libsecret apps
- `SIGNAL_PASSWORD_STORE`: Tells Signal to use keyring

**VS Code Integration:**

VS Code requires a command-line override to use GNOME Keyring:

```nix
environment.systemPackages = with pkgs; [
  (vscode.override {
    commandLineArgs = [
      "--password-store=gnome-libsecret"
    ];
  })
];
```

This configures VS Code to store credentials (GitHub, remote extensions, etc.) in GNOME Keyring.

### 7. Required Packages

```nix
environment.systemPackages = with pkgs; [
  gnome-keyring    # Keyring daemon
  gcr_4            # SSH password prompts
  libsecret        # Secret storage library for applications
  seahorse         # GUI for managing keyring and GPG keys
  pinentry-all     # GPG password prompts (graphical)
];
```

### 8. SSH Key Auto-Loader

**Purpose:** Automatically discover and load all SSH keys on login

```nix
environment.systemPackages = with pkgs; [
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
```

**Auto-discovery patterns:**

- Standard: `id_rsa`, `id_ed25519`, `id_ecdsa`, `id_dsa`
- Custom prefix: `work_id_ed25519`, `github_id_rsa`, `deploy_id_ecdsa`
- Any `id_*` pattern in `~/.ssh/`
- Excludes `.pub` files and `known_hosts`

**Triggered automatically** via Hyprland exec-once on startup.

### 9. Home Manager Integration

**Purpose:** SSH auto-add configuration and GPG pinentry setup

```nix
home-manager.sharedModules = [
  (_: {
    # GPG pinentry configuration
    home.file.".gnupg/gpg-agent.conf".text = ''
      pinentry-program /run/current-system/sw/bin/pinentry
    '';

    # SSH auto-add keys configuration
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

    # Run SSH key loader on Hyprland startup
    wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
      "ssh-add-keys"
    ];
  })
];
```

**SSH config explained:**

- `IgnoreUnknown UseKeychain`: Prevents errors on Linux (macOS-specific option)
- `AddKeysToAgent yes`: Automatically add keys when first used
- `UseKeychain yes`: Use keyring for passphrase storage
- `IdentitiesOnly yes`: Only use explicitly configured identities

## Verification

### After System Rebuild

```bash
# 1. Check keyring is unlocked
secret-tool lookup nonexistent key
# No password prompt = keyring is unlocked ✅

# 2. Verify PAM started gnome-keyring-daemon (not systemd)
ps aux | grep gnome-keyring-daemon
# Should show process running ✅

# 3. Check SSH agent socket
echo $SSH_AUTH_SOCK
# Should show: /run/user/1000/gcr/ssh ✅

# 4. Verify SSH keys are loaded
ssh-add -l
# Should list your SSH keys ✅

# 5. Check environment variables
echo $GNOME_KEYRING_CONTROL  # /run/user/1000/keyring
echo $SSH_ASKPASS            # /nix/store/.../gcr4-ssh-askpass
echo $SIGNAL_PASSWORD_STORE  # gnome-libsecret

# 6. Verify services running
systemctl --user status hyprpolkitagent  # active (running)
systemctl --user status gpg-agent        # active (running)
systemctl --user status gcr-ssh-agent    # active (running)
```

### Test SSH Passphrase Storage

```bash
# First time: Enter passphrase
ssh-add ~/.ssh/id_ed25519
# Passphrase prompt appears ✅

# Lock screen (Super+L), unlock, then check keys
ssh-add -l
# Keys still loaded, no passphrase prompt ✅

# Reboot system, login, check keys
ssh-add -l
# Keys loaded, no passphrase prompt ✅
# Passphrase was stored persistently!
```

### Test GPG Passphrase Prompts

```bash
# Test GPG signing
echo "test" | gpg --clearsign
# GUI passphrase prompt appears ✅
# Option to "Save in password manager" visible ✅

# Test git commit signing
git commit -S -m "test"
# GUI passphrase prompt or uses cached passphrase ✅
```

### Test Application Integration

```bash
# Test VS Code keyring integration
code --help
# Verify --password-store=gnome-libsecret in output ✅
# Login to GitHub in VS Code → credentials stored in keyring ✅

# Test Signal
# Open Signal → credentials persist across reboots ✅

# View all stored secrets in Seahorse GUI
seahorse
# See SSH keys, GPG keys, app passwords ✅
```

## Troubleshooting

### Keyring doesn't unlock after screen unlock

**Symptom:** Applications prompt for keyring password after unlocking screen

**Fix:** Ensure `security.pam.services.hyprlock.enableGnomeKeyring = true` is set

**Check:** `journalctl --user -xe | grep -i keyring` for PAM errors

---

### SSH keys not loading automatically

**Symptom:** `ssh-add -l` shows "The agent has no identities"

**Fix:**

1. Verify SSH agent socket: `echo $SSH_AUTH_SOCK` (should be `/run/user/1000/gcr/ssh`)
2. Check if ssh-add-keys ran: Look for "Adding SSH key" in terminal output
3. Ensure key files match pattern: `~/.ssh/id_*` or `~/.ssh/*_id_*`
4. Manually test: `ssh-add ~/.ssh/id_ed25519`

---

### SSH passphrase prompts every time

**Symptom:** SSH asks for passphrase on every connection

**Fix:**

1. Verify gcr-ssh-agent is running: `systemctl --user status gcr-ssh-agent`
2. Check keyring is unlocked: `secret-tool lookup nonexistent key`
3. Ensure `AddKeysToAgent yes` in `~/.ssh/config`
4. Check SSH agent: `echo $SSH_AUTH_SOCK` points to gcr, not OpenSSH

---

### Race condition: gcr-ssh-agent fails to start

**Symptom:** `systemctl --user status gcr-ssh-agent` shows failed or degraded

**Fix:**

1. Check if wait script is configured in gcr-ssh-agent service
2. Verify keyring socket exists: `ls -la /run/user/$UID/keyring/control`
3. Check logs: `journalctl --user -xe -u gcr-ssh-agent`
4. If socket missing, check gnome-keyring-daemon is running

---

### GPG passphrase prompts don't appear

**Symptom:** GPG operations fail silently or hang

**Fix:**

1. Verify GPG agent running: `systemctl --user status gpg-agent`
2. Check pinentry config: `cat ~/.gnupg/gpg-agent.conf`
3. Test pinentry manually: `/run/current-system/sw/bin/pinentry`
4. Ensure polkit agent running: `systemctl --user status hyprpolkitagent`

---

### Browser/app can't store passwords in keyring

**Symptom:** Chrome, Firefox, or other apps can't save passwords to keyring

**Fix:**

1. Verify `GNOME_KEYRING_CONTROL` is set: `echo $GNOME_KEYRING_CONTROL`
2. Check libsecret installed: `ls /run/current-system/sw/bin/secret-tool`
3. Test keyring access: `secret-tool store --label='test' test test` (enter value)
4. Retrieve test: `secret-tool lookup test test`
5. Open Seahorse GUI to see stored secrets

## Key Architecture Decisions

### 1. PAM starts gnome-keyring-daemon, NOT systemd

- Default NixOS disables systemd service for keyring
- PAM integration is the correct approach
- Daemon persists for entire user session
- Auto-unlocks with login/unlock password

### 2. gcr-ssh-agent instead of OpenSSH ssh-agent

- Integrates with GNOME Keyring for persistent passphrase storage
- Replaces deprecated gnome-keyring SSH agent (deprecated since 1:46)
- Stores passphrases securely in keyring between sessions
- No need to re-enter passphrases after reboot

### 3. hyprpolkitagent as systemd service, NOT exec-once

- Ensures polkit agent starts reliably with graphical session
- Auto-restarts on failure
- Not dependent on Hyprland startup order
- Critical for SSH/GPG passphrase prompts

### 4. Wait script for gcr-ssh-agent

- Prevents race condition where SSH agent starts before keyring ready
- Waits up to 10 seconds for keyring control socket
- Critical for reliable SSH key loading
- Without this, SSH keys may fail to load on startup

### 5. hyprlock PAM integration (Critical!)

- Without this, keyring stays locked after screen unlock
- **Most common issue in tiling window managers**
- Desktop environments set this up automatically
- Tiling WM users must configure it explicitly

## Reference

Complete implementation: `modules/system/keyring/default.nix`
