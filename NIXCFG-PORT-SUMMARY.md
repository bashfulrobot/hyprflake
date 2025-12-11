# nixcfg → hyprflake Configuration Port Summary

Date: 2025-12-11
Status: EXACT configuration ported at Nix code level

## Code-Level Comparison

### 1. SSH Configuration

**nixcfg** (`modules/sys/ssh/default.nix`):
```nix
home-manager.users."${user-settings.user.username}" = {
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
};
```

**hyprflake** (`modules/system/keyring/default.nix`):
```nix
home-manager.sharedModules = [
  (_: {
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
  })
];
```

**Status:** ✅ IDENTICAL (adapted to sharedModules pattern)

---

### 2. GPG Agent Configuration

**nixcfg** (`modules/desktops/gnome/default.nix`):
```nix
home-manager.users."${user-settings.user.username}" = {
  # https://discourse.nixos.org/t/cant-get-gnupg-to-work-no-pinentry/15373/13?u=brnix
  home.file.".gnupg/gpg-agent.conf".text = ''
    pinentry-program /run/current-system/sw/bin/pinentry
  '';
};
```

**hyprflake** (`modules/system/keyring/default.nix`):
```nix
home-manager.sharedModules = [
  (_: {
    # GPG agent configuration (from nixcfg)
    # https://discourse.nixos.org/t/cant-get-gnupg-to-work-no-pinentry/15373/13?u=brnix
    home.file.".gnupg/gpg-agent.conf".text = ''
      pinentry-program /run/current-system/sw/bin/pinentry
    '';
  })
];
```

**Status:** ✅ IDENTICAL (including comment/URL reference)

---

### 3. GPG Agent Service

**nixcfg** (implicit via GNOME desktop):
```nix
# Automatically enabled by desktopManager.gnome.enable = true
# No explicit programs.gnupg.agent configuration in nixcfg modules
```

**hyprflake** (`modules/system/keyring/default.nix`):
```nix
# GPG agent with graphical pinentry
# Note: pinentry program is configured via gpg-agent.conf in home-manager
programs.gnupg.agent = {
  enable = true;
  enableSSHSupport = false; # We use separate OpenSSH agent for full protocol support
};
```

**Status:** ✅ EQUIVALENT (explicit config needed without GNOME desktop)

---

### 4. Pinentry Package

**nixcfg** (`modules/desktops/gnome/default.nix`):
```nix
environment.systemPackages = with pkgs; [
  pinentry-all # gpg passphrase prompting
  # ... other packages
];
```

**hyprflake** (`modules/system/keyring/default.nix`):
```nix
environment.systemPackages = with pkgs; [
  pinentry-all # GPG passphrase prompting (from nixcfg)
  # ... other packages
];
```

**Status:** ✅ IDENTICAL

---

### 5. PAM Keyring Integration

**nixcfg** (implicit via GNOME desktop):
```nix
# Automatically configured by desktopManager.gnome.enable = true
# No explicit PAM configuration in nixcfg modules
```

**hyprflake** (`modules/system/keyring/default.nix`):
```nix
# Enable PAM keyring for automatic unlock on login
security.pam.services = {
  gdm.enableGnomeKeyring = true;
  gdm-password.enableGnomeKeyring = true;
  login.enableGnomeKeyring = true;
};
```

**Status:** ✅ EQUIVALENT (explicit config needed without GNOME desktop)

---

## Files Modified in hyprflake

### 1. `modules/system/keyring/default.nix`

**Changes:**
- Removed `pinentryPackage = pkgs.pinentry-gnome3` from programs.gnupg.agent
- Changed `pinentry-gnome3` to `pinentry-all` in systemPackages
- Added home.file.".gnupg/gpg-agent.conf".text (EXACT from nixcfg)
- Added programs.ssh configuration (EXACT from nixcfg)

### 2. `modules/desktop/hyprland/default.nix`

**Changes:**
- Removed `GPG_TTY = "$(tty)";` (not in nixcfg)
- Kept GNOME_KEYRING_CONTROL and SSH_ASKPASS_REQUIRE (needed for Hyprland)

---

## What's Different (Hyprland vs GNOME)

These are REQUIRED differences because hyprflake uses Hyprland instead of GNOME:

### Environment Variables (hyprflake only)

```nix
# Required for Hyprland - GNOME desktop sets these automatically
SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/ssh-agent.sock";
SSH_ASKPASS = lib.mkForce "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass";
SSH_ASKPASS_REQUIRE = "prefer";
GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";
```

### OpenSSH Agent Service (hyprflake only)

```nix
# Required for Hyprland - GNOME desktop handles this automatically
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

### Polkit Agent (hyprflake only)

```nix
# Required for Hyprland - GNOME desktop includes polkit agent
systemd.user.services.hyprpolkitagent = {
  description = "Hyprpolkit authentication agent";
  wantedBy = [ "graphical-session.target" ];
  serviceConfig = {
    ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
    Restart = "on-failure";
  };
};
```

---

## Testing After Rebuild

### 1. Verify GPG Configuration File

```bash
cat ~/.gnupg/gpg-agent.conf
```

Expected output:
```
pinentry-program /run/current-system/sw/bin/pinentry
```

### 2. Verify SSH Configuration

```bash
cat ~/.ssh/config
```

Expected to include:
```
Host *
  IgnoreUnknown UseKeychain
  AddKeysToAgent yes
  UseKeychain yes
  IdentitiesOnly yes
```

### 3. Test Git Commit Signing

```bash
# Kill existing gpg-agent
gpgconf --kill gpg-agent

# Try signing a commit
git commit -S -m "test"
```

Expected: Graphical pinentry prompt appears (not gcr4-ssh-askpass error)

### 4. Verify Pinentry Package

```bash
which pinentry
readlink -f $(which pinentry)
```

Expected: Points to pinentry-all wrapper

---

## Summary

The SSH and GPG configuration from nixcfg has been ported EXACTLY to hyprflake:

✅ SSH configuration: `programs.ssh.extraConfig` - IDENTICAL code
✅ GPG agent file: `home.file.".gnupg/gpg-agent.conf".text` - IDENTICAL code
✅ Pinentry package: `pinentry-all` - IDENTICAL package
✅ PAM integration: Explicitly configured (was automatic in GNOME)
✅ No extra environment variables (GPG_TTY removed)

The only differences are infrastructure required for Hyprland that GNOME provides automatically (ssh-agent service, polkit agent, environment variables).

**Next step:** Rebuild system and test GPG signing.
