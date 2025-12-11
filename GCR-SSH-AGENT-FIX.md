# gcr-ssh-agent Fix for SSH Signing

Date: 2025-12-11
Issue: Git commit signing with SSH keys failing - gcr4-ssh-askpass error

## Root Cause

hyprflake was using **OpenSSH ssh-agent** instead of **gcr-ssh-agent**:

- OpenSSH ssh-agent: Does NOT integrate with GNOME Keyring for passphrase storage
- gcr-ssh-agent: Integrates with keyring, stores passphrases persistently

This caused SSH keys to never be loaded because gcr4-ssh-askpass couldn't be invoked properly.

## Solution

Switched to `services.gnome.gcr-ssh-agent.enable = true` (same as nixcfg/GNOME desktop).

### Changes Made

**File:** `modules/system/keyring/default.nix`

**Before:**
```nix
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
```

**After:**
```nix
# Use gcr-ssh-agent for keyring integration (from nixcfg/GNOME desktop)
# gcr-ssh-agent integrates with GNOME Keyring for persistent passphrase storage
# Replaces deprecated gnome-keyring SSH agent (deprecated since version 1:46)
# See: https://github.com/NixOS/nixpkgs/pull/379731
services.gnome.gcr-ssh-agent.enable = true;
```

**File:** `modules/desktop/hyprland/default.nix`

**Before:**
```nix
SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.sock";
```

**After:**
```nix
SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
```

## How It Works Now

1. **Login:** PAM unlocks GNOME Keyring with your login password
2. **gcr-ssh-agent starts:** Systemd user service (via `services.gnome.gcr-ssh-agent`)
3. **First SSH operation:** gcr4-ssh-askpass prompts for key passphrase (graphical dialog)
4. **Passphrase stored:** Saved in GNOME Keyring permanently
5. **Subsequent operations:** Keys automatically available from keyring

## Benefits

✅ SSH key passphrases stored persistently in keyring
✅ Graphical password prompts (gcr4-ssh-askpass)
✅ Same behavior as nixcfg/GNOME desktop
✅ Git commit signing with SSH keys works
✅ ssh-add automatically loads keys from keyring

## Testing After Rebuild

### 1. Verify gcr-ssh-agent is running

```bash
systemctl --user status gcr-ssh-agent
```

Expected: `active (running)`

### 2. Check SSH_AUTH_SOCK

```bash
echo $SSH_AUTH_SOCK
```

Expected: `/run/user/1000/gcr/ssh`

### 3. Test SSH key loading

```bash
ssh-add ~/.ssh/id_ed25519
```

Expected: Graphical password prompt appears (gcr4-ssh-askpass dialog)
After entering passphrase: Key loaded and passphrase saved to keyring

### 4. Test git commit signing

```bash
git commit -S -m "test SSH signing"
```

Expected: Works without prompting (key already in agent from step 3)

### 5. Verify passphrase persistence

Reboot, then:

```bash
ssh-add -l
```

Expected: Key automatically loaded from keyring (no prompt needed)

## References

- [NixOS PR #379731 - gcr-ssh-agent](https://github.com/NixOS/nixpkgs/pull/379731)
- [GNOME Keyring SSH deprecation](https://discourse.gnome.org/t/gdm-gnome-keyring-and-gcr-ssh-agent-service/23498)
- [Arch Linux GNOME/Keyring Wiki](https://wiki.archlinux.org/title/GNOME/Keyring)

## Comparison with nixcfg

**nixcfg** (GNOME desktop):
- `desktopManager.gnome.enable = true` automatically enables gcr-ssh-agent
- SSH passphrases stored in keyring
- No explicit configuration needed

**hyprflake** (Hyprland):
- Explicit `services.gnome.gcr-ssh-agent.enable = true`
- Same functionality as GNOME
- Requires manual configuration of environment variables

## Next Build

After rebuilding:
1. Log out and log back in
2. SSH keys will be prompted for passphrase (graphical dialog)
3. Passphrases saved to keyring permanently
4. Git signing and SSH operations work seamlessly
