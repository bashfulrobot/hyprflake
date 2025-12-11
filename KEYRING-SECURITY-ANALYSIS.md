# Hyprflake Keyring and Security Configuration Analysis

**Date:** 2025-12-11
**Status:** Critical Issues Identified - Keyring Functionality Broken
**Location:** `/home/dustin/dev/nix/hyprflake/`

---

## Executive Summary

The keyring implementation in hyprflake has **CRITICAL CONFIGURATION ISSUES** that break functionality:

1. **Missing GNOME_KEYRING_CONTROL environment variable** - Applications cannot communicate with keyring
2. **Invalid polkit-agent-helper-1 command** - Non-existent binary in exec-once
3. **No GPG agent configuration** - GPG operations lack graphical prompts
4. **Conflicting SSH_AUTH_SOCK documentation** - Comments reference wrong socket path

The architecture is sound (OpenSSH agent, PAM integration, security wrapper) but the implementation has integration gaps.

---

## Module Architecture

### Active Modules (from `/home/dustin/dev/nix/hyprflake/modules/default.nix`)

```
modules/
├── desktop/hyprland ← ACTIVE Hyprland configuration
├── system/keyring ← Keyring, SSH agent, polkit configuration
└── system/programs/hyprland.nix ← NOT IMPORTED (orphaned file)
```

**Important:** `system/programs/hyprland.nix` exists but is **NOT imported** in `default.nix`. It's an orphaned file that can be safely ignored or removed.

---

## Critical Issues

### Issue 1: Missing GNOME_KEYRING_CONTROL Environment Variable ⚠️

**Location:** `/home/dustin/dev/nix/hyprflake/modules/desktop/hyprland/default.nix`

**Current Configuration:**
```nix
# Line 162-165
# Keyring & SSH
# Using OpenSSH ssh-agent (gcr-ssh-agent has protocol limitations)
SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.sock";
SSH_ASKPASS = lib.mkForce "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass";
```

**Problem:** Missing `GNOME_KEYRING_CONTROL` environment variable.

**Expected Configuration:**
```nix
# Keyring & SSH
SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.sock";
SSH_ASKPASS = lib.mkForce "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass";
GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";  # ← MISSING!
```

**Impact:**
- Applications cannot find gnome-keyring-daemon socket
- Browser password storage breaks
- Secret storage API (libsecret) doesn't work
- Signal and other apps cannot store credentials in keyring

**Root Cause:** The environment variable was in the obsolete `system/programs/hyprland.nix` (line 121) but that file is not imported.

---

### Issue 2: Invalid exec-once Command Reference ⚠️

**Location:** `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix:105`

```nix
wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
  "polkit-agent-helper-1"  # ❌ This binary doesn't exist!
  "ssh-add-keys"
];
```

**Problem:** `polkit-agent-helper-1` is not a valid command or binary path.

**Evidence:** The polkit agent is already properly configured as a systemd service:
```nix
# Lines 33-45 in same file
systemd.user.services.hyprpolkitagent = {
  description = "Hyprpolkit authentication agent";
  wantedBy = [ "graphical-session.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
  };
};
```

**Impact:**
- Hyprland logs error message on startup about missing command
- However, polkit agent DOES start via systemd service, so functionality works
- Confusing for debugging

**Fix:** Remove the invalid exec-once line. The systemd service handles polkit agent startup.

---

### Issue 3: No GPG Agent Configuration ⚠️

**Location:** No GPG configuration exists anywhere

**Current Status:**
- `pinentry-all` package is installed (line 70 in keyring module, line 110 in hyprland module)
- No `programs.gnupg.agent` configuration
- No GPG-related environment variables
- No gpg-agent systemd service

**Impact:**
- GPG key operations have no graphical password prompts
- Git commit signing won't work properly
- GPG key management is manual and cumbersome

**Expected Configuration:**
```nix
programs.gnupg.agent = {
  enable = true;
  enableSSHSupport = false;  # We use separate ssh-agent
  pinentryPackage = pkgs.pinentry-gnome3;  # or pinentry-gtk2
};

environment.variables = {
  GPG_TTY = "$(tty)";
};
```

---

### Issue 4: Misleading Documentation in SSH Agent Comments

**Location:** `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix:48-50`

```nix
# Use OpenSSH ssh-agent instead of gcr-ssh-agent
# gcr-ssh-agent has limited protocol support and doesn't work with git signing or some SSH operations
# OpenSSH ssh-agent works fully and can still store passphrases in gnome-keyring via libsecret
```

**Problem:** The last line is misleading. OpenSSH ssh-agent does NOT natively store passphrases in gnome-keyring.

**Reality:**
- OpenSSH ssh-agent caches passphrases in memory only
- SSH_ASKPASS (gcr4-ssh-askpass) can PROMPT for passphrases with a GUI
- But passphrases are NOT persistently stored in keyring between reboots
- True keyring storage would require gcr-ssh-agent (which has limitations) or custom integration

**Impact:** Users may expect SSH passphrases to be saved in keyring, but they aren't.

---

## Current Configuration Inventory

### 1. PAM Configuration ✅ CORRECT

**Location:** `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix:10-14`

```nix
security.pam.services = {
  gdm.enableGnomeKeyring = true;
  gdm-password.enableGnomeKeyring = true;
  login.enableGnomeKeyring = true;
};
```

**Status:** Properly configured
- PAM starts gnome-keyring-daemon on GDM login
- Daemon runs with `secrets` and `pkcs11` components
- Keyring automatically unlocked with login password

---

### 2. Security Wrapper ✅ CORRECT

**Location:** `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix:18-23`

```nix
security.wrappers.gnome-keyring-daemon = {
  owner = "root";
  group = "root";
  capabilities = "cap_ipc_lock=ep";
  source = "${pkgs.gnome-keyring}/bin/gnome-keyring-daemon";
};
```

**Status:** Properly configured
- Grants IPC_LOCK capability for memory locking
- Prevents passwords from being swapped to disk
- Security hardening correctly implemented

---

### 3. Systemd User Services ✅ CORRECT

**Location:** `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix:26-60`

#### 3a. gnome-keyring-daemon Service (Disabled)
```nix
gnome-keyring-daemon.enable = false;
```

**Status:** Correctly disabled (PAM starts it instead)

#### 3b. hyprpolkitagent Service
```nix
hyprpolkitagent = {
  description = "Hyprpolkit authentication agent";
  wantedBy = [ "graphical-session.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
    Restart = "on-failure";
  };
};
```

**Status:** Properly configured
- Starts with graphical session
- Enables polkit authentication dialogs
- Auto-restarts on failure

#### 3c. ssh-agent Service
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

**Status:** Properly configured
- Creates socket at `/run/user/$UID/ssh-agent.sock`
- Uses OpenSSH agent (not gcr-ssh-agent) for full protocol support
- Properly set as systemd user service

---

### 4. Environment Variables (Active Module)

**Location:** `/home/dustin/dev/nix/hyprflake/modules/desktop/hyprland/default.nix:131-179`

**Currently Set:**
```nix
SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.sock";  # ✅ Correct
SSH_ASKPASS = lib.mkForce "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass";  # ✅ Correct
SIGNAL_PASSWORD_STORE = "gnome-libsecret";  # ✅ Correct (in keyring module line 64)
```

**Missing:**
```nix
GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";  # ❌ NOT SET
SSH_ASKPASS_REQUIRE = "prefer";  # ⚠️ Optional but recommended
GPG_TTY = "$(tty)";  # ❌ NOT SET (GPG not configured)
```

---

### 5. SSH Key Auto-Loader Script ✅ CORRECT

**Location:** `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix:71-96`

```nix
(writeShellScriptBin "ssh-add-keys" ''
  # Auto-load SSH keys into SSH agent
  SSH_KEYS=(
    "$HOME/.ssh/id_rsa"
    "$HOME/.ssh/id_ed25519"
    "$HOME/.ssh/id_ecdsa"
  )

  if [ -z "$SSH_AUTH_SOCK" ]; then
    echo "SSH agent not running, skipping key loading"
    exit 0
  fi

  for key in "${SSH_KEYS[@]}"; do
    if [ -f "$key" ]; then
      echo "Adding SSH key: $key"
      ssh-add "$key" 2>/dev/null || echo "Failed to add $key"
    fi
  done
'')
```

**Status:** Properly configured
- Gracefully handles missing agent
- Loads common SSH key types
- Good error handling

---

### 6. Installed Security Packages

**Location:** Multiple modules

**In keyring module (`system/keyring/default.nix:68-70`):**
- `gnome-keyring`
- `gcr_4` (provides gcr4-ssh-askpass)

**In Hyprland module (`desktop/hyprland/default.nix:107-110`):**
- `gcr_4` (duplicate)
- `libsecret`
- `seahorse`
- `pinentry-all`

**In system packages:**
- `hyprpolkitagent`
- `openssh` (includes ssh-agent)

**Status:** All necessary packages installed, some duplicates (not harmful, just redundant)

---

### 7. Polkit Configuration ✅ CORRECT

**Location:** `/home/dustin/dev/nix/hyprflake/modules/desktop/hyprland/default.nix:182`

```nix
security.polkit.enable = true;
```

**Status:** Properly enabled for privilege escalation

---

### 8. Hyprland exec-once Configuration

**Location:** Multiple locations

**In keyring module (`system/keyring/default.nix:100-108`):**
```nix
home-manager.sharedModules = [
  (_: {
    wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
      "polkit-agent-helper-1"  # ❌ Invalid command
      "ssh-add-keys"           # ✅ Correct
    ];
  })
];
```

**In Hyprland module (`desktop/hyprland/default.nix:300-307`):**
```nix
exec-once = [
  "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
  "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store"
  "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store"
  "blueman-applet"
  "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass"  # ✅ Correct
];
```

**Issue:** `polkit-agent-helper-1` doesn't exist and will fail on startup.

---

## Missing Configurations

### 1. GNOME_KEYRING_CONTROL Environment Variable ❌

**Impact:** HIGH - Applications cannot communicate with keyring daemon

**What's Missing:**
```nix
# In modules/desktop/hyprland/default.nix around line 165
GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";
```

---

### 2. GPG Agent Configuration ❌

**Impact:** MEDIUM - GPG operations lack proper integration

**What's Missing:**
```nix
# Should be in modules/system/keyring/default.nix
programs.gnupg.agent = {
  enable = true;
  enableSSHSupport = false;  # We use separate ssh-agent
  pinentryPackage = pkgs.pinentry-gnome3;
};

# And environment variable in desktop/hyprland
GPG_TTY = "$(tty)";
```

---

### 3. SSH_ASKPASS_REQUIRE ⚠️

**Impact:** LOW - Optional but improves UX

**What's Missing:**
```nix
# In modules/desktop/hyprland/default.nix
SSH_ASKPASS_REQUIRE = "prefer";  # Force graphical prompts when available
```

---

## Root Cause Analysis

### Why Keyring Is Broken

1. **Missing GNOME_KEYRING_CONTROL:**
   - Was set in obsolete `system/programs/hyprland.nix` (not imported)
   - Not migrated to active `desktop/hyprland/default.nix` module
   - Applications cannot find keyring socket

2. **Invalid exec-once Command:**
   - Copy-paste error or confusion about polkit agent binary name
   - Systemd service correctly configured, but exec-once references wrong command

3. **No GPG Integration:**
   - pinentry package installed but no agent configured
   - GPG operations fail or fall back to terminal prompts

4. **Documentation Confusion:**
   - Comments reference passphrase storage in keyring (not actually implemented)
   - Reference to obsolete socket paths in old module files

---

## Recommended Fixes (Priority Order)

### P0 - Critical Fixes (Required for Basic Functionality)

#### Fix 1: Add GNOME_KEYRING_CONTROL Environment Variable

**File:** `/home/dustin/dev/nix/hyprflake/modules/desktop/hyprland/default.nix`

**Change:** Around line 165, add the missing variable:

```nix
# Keyring & SSH
# Using OpenSSH ssh-agent (gcr-ssh-agent has protocol limitations)
SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.sock";
SSH_ASKPASS = lib.mkForce "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass";
GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";  # ← ADD THIS
```

**Impact:** Enables applications to communicate with gnome-keyring for secret storage.

---

#### Fix 2: Remove Invalid exec-once Command

**File:** `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix`

**Change:** Line 105, remove the invalid command:

```nix
wayland.windowManager.hyprland.settings.exec-once = lib.mkAfter [
  # "polkit-agent-helper-1"  # ← REMOVE THIS (systemd service handles it)
  "ssh-add-keys"
];
```

**Alternative:** If you want to keep it for documentation, update to:
```nix
# Note: polkit agent is started by systemd service (hyprpolkitagent.service)
# not via exec-once
"ssh-add-keys"
```

**Impact:** Removes error message on Hyprland startup.

---

### P1 - Important Enhancements

#### Fix 3: Add GPG Agent Configuration

**File:** `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix`

**Add after PAM configuration (around line 15):**

```nix
# GPG agent with graphical pinentry
programs.gnupg.agent = {
  enable = true;
  enableSSHSupport = false;  # We use separate OpenSSH agent
  pinentryPackage = pkgs.pinentry-gnome3;  # Graphical password prompts
};
```

**File:** `/home/dustin/dev/nix/hyprflake/modules/desktop/hyprland/default.nix`

**Add to environment.variables (around line 165):**

```nix
# GPG
GPG_TTY = "$(tty)";
```

**Impact:** Enables GPG operations with graphical password prompts.

---

#### Fix 4: Correct Misleading Documentation

**File:** `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix`

**Update comment on line 48-50:**

```nix
# Use OpenSSH ssh-agent instead of gcr-ssh-agent
# gcr-ssh-agent has limited protocol support and doesn't work with git signing or some SSH operations
# OpenSSH ssh-agent provides full protocol support and caches passphrases in memory
# Note: SSH passphrases are NOT persistently stored in keyring (use gcr-ssh-agent for that, with limitations)
```

**Alternative:** If you want persistent passphrase storage, document the trade-offs.

---

#### Fix 5: Consolidate Package Installations

**Issue:** `gcr_4` is installed in both keyring and hyprland modules.

**Recommendation:** Move all security/keyring packages to the keyring module:

**File:** `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix`

**Update environment.systemPackages (line 68-70):**

```nix
environment.systemPackages = with pkgs; [
  gnome-keyring
  gcr_4  # Provides gcr4-ssh-askpass for graphical password prompts
  libsecret  # ← ADD
  seahorse   # ← ADD
  pinentry-gnome3  # ← ADD (better than pinentry-all for GNOME/GTK)
  (writeShellScriptBin "ssh-add-keys" ''
    # ...
  '')
];
```

**File:** `/home/dustin/dev/nix/hyprflake/modules/desktop/hyprland/default.nix`

**Remove duplicate packages (lines 107-110):**

```nix
# Remove these - they're now in keyring module:
# gcr_4
# libsecret
# seahorse
# pinentry-all
```

**Impact:** Cleaner module boundaries, easier maintenance.

---

### P2 - Polish & Optional

#### Fix 6: Add SSH_ASKPASS_REQUIRE

**File:** `/home/dustin/dev/nix/hyprflake/modules/desktop/hyprland/default.nix`

**Add to environment.variables (around line 165):**

```nix
SSH_ASKPASS_REQUIRE = "prefer";  # Force graphical prompts when available
```

**Impact:** Improves SSH UX by preferring GUI prompts over terminal prompts.

---

#### Fix 7: Remove Obsolete File

**File:** `/home/dustin/dev/nix/hyprflake/modules/system/programs/hyprland.nix`

**Action:** This file is not imported in `default.nix`. It can be:
1. Deleted entirely (recommended)
2. Renamed to `hyprland.nix.obsolete` for reference
3. Documented in a comment explaining it's superseded by `desktop/hyprland`

**Impact:** Reduces confusion, prevents accidental usage.

---

## Testing Checklist

After applying fixes, verify:

### Environment Variables
- [ ] `echo $SSH_AUTH_SOCK` returns `/run/user/$UID/ssh-agent.sock`
- [ ] `echo $GNOME_KEYRING_CONTROL` returns `/run/user/$UID/keyring`
- [ ] `echo $SSH_ASKPASS` points to `gcr4-ssh-askpass`
- [ ] `echo $GPG_TTY` returns current TTY

### Services
- [ ] `systemctl --user status ssh-agent` shows active (running)
- [ ] `systemctl --user status hyprpolkitagent` shows active (running)
- [ ] `ps aux | grep gnome-keyring-daemon` shows daemon running

### SSH Functionality
- [ ] `ssh-add -l` shows loaded SSH keys (or "no identities" if none added)
- [ ] SSH connection prompts for passphrase via GUI (gcr4-ssh-askpass)
- [ ] `ssh-add ~/.ssh/id_ed25519` works with graphical prompt

### Keyring Functionality
- [ ] `seahorse` opens and shows "Login" keyring unlocked
- [ ] Browser (Chrome/Firefox) can store passwords
- [ ] Signal can store credentials (check in Signal settings)
- [ ] `secret-tool search --all` returns results (if any secrets stored)

### GPG Functionality
- [ ] `gpg --list-keys` works
- [ ] `echo "test" | gpg --clearsign` prompts for passphrase via GUI
- [ ] Git commit signing works: `git commit -S -m "test"`

### Error Logs
- [ ] `journalctl --user -xe | grep -i keyring` shows no errors
- [ ] `journalctl --user -xe | grep -i polkit` shows no errors
- [ ] Hyprland log has no "polkit-agent-helper-1: command not found" errors

---

## Files Requiring Changes (Summary)

### P0 - Critical Fixes
1. `/home/dustin/dev/nix/hyprflake/modules/desktop/hyprland/default.nix`
   - Add `GNOME_KEYRING_CONTROL` environment variable (line ~165)

2. `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix`
   - Remove invalid `polkit-agent-helper-1` from exec-once (line 105)

### P1 - Important Enhancements
3. `/home/dustin/dev/nix/hyprflake/modules/system/keyring/default.nix`
   - Add `programs.gnupg.agent` configuration (after line 14)
   - Update misleading comment (line 48-50)
   - Consolidate packages (line 68-70)

4. `/home/dustin/dev/nix/hyprflake/modules/desktop/hyprland/default.nix`
   - Add `GPG_TTY` environment variable (line ~165)
   - Remove duplicate security packages (lines 107-110)

### P2 - Optional Polish
5. `/home/dustin/dev/nix/hyprflake/modules/desktop/hyprland/default.nix`
   - Add `SSH_ASKPASS_REQUIRE = "prefer"` (line ~165)

6. `/home/dustin/dev/nix/hyprflake/modules/system/programs/hyprland.nix`
   - Delete or rename as obsolete

---

## Architecture Notes

### Module Ownership

**Security/Keyring Responsibilities:**
- `modules/system/keyring/` - Owns all keyring, SSH agent, polkit, GPG configuration
- `modules/desktop/hyprland/` - Sets environment variables, provides desktop integration

**Design Principle:** Keyring module should be self-contained with all necessary configuration. Hyprland module should only set environment variables and provide UI integration (exec-once for scripts).

---

### Why OpenSSH Agent Instead of gcr-ssh-agent?

**Documented Reason (from code comments):**
> "gcr-ssh-agent has limited protocol support and doesn't work with git signing or some SSH operations"

**Trade-off:**
- **OpenSSH agent:** Full protocol support, but NO persistent passphrase storage in keyring
- **gcr-ssh-agent:** Keyring integration, but limited protocol support

**Current Choice:** Full functionality over convenience (user enters passphrase once per session).

---

## Conclusion

The hyprflake keyring configuration is **80% correct** but has **critical integration gaps**:

- ✅ Architecture is sound (PAM, security wrapper, systemd services)
- ✅ OpenSSH agent properly configured
- ✅ Polkit agent properly configured (systemd service)
- ❌ Missing GNOME_KEYRING_CONTROL env var (breaks secret storage)
- ❌ Invalid exec-once command (cosmetic error)
- ❌ No GPG agent configuration (missing feature)

**Estimated Fix Time:**
- P0 fixes: 15 minutes
- P1 fixes: 30 minutes
- P2 polish: 15 minutes
- Testing: 30 minutes
- **Total: ~1.5 hours**

**Expected Outcome:** Fully functional keyring with SSH agent, secret storage, polkit, and GPG integration.
