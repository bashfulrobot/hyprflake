# Hyprflake Architecture

## Overview

Hyprflake is a NixOS module library flake that provides a complete Hyprland desktop environment. Consumers import `nixosModules.default` and configure via `hyprflake.*` options.

## Module Tree

```
modules/
  default.nix             # Entry point — imports all modules, passes hyprflakeInputs
  desktop/
    autostart/            # XDG autostart support via dex
    autostart-d/          # Hyprland .d directory autostart pattern
    display-manager/      # GDM display manager + xkb keyboard config
    hyprland/             # Core Hyprland config, keybinds, env vars, window rules
                          # Also defines hyprflake.desktop.keyboard options
    hyprlock/             # Screen locker
    hypridle/             # Idle management (lock, DPMS, suspend timeouts)
                          # Defines hyprflake.desktop.idle + hypridle.enable options
    hyprshell/            # Desktop shell (app launcher panel)
    rofi/                 # Application launcher
    rofimoji/             # Emoji picker
    shortcuts-viewer/     # Keybinding cheat sheet overlay
    stylix/               # Stylix theming integration
                          # Defines all hyprflake.style options
    swaync/               # Notification daemon
    swayosd/              # On-screen display for volume/brightness
    system-actions/       # Desktop entries for lock/reboot/shutdown
    themes/               # Additional theme assets
    voxtype/              # Push-to-talk voice-to-text
    waybar/               # Status bar
    waybar-auto-hide/     # Auto-hide behavior for waybar
                          # Defines hyprflake.desktop.waybar.autoHide
    wl-clip-persist/      # Clipboard persistence
    wlogout/              # Logout menu
  home/
    gtk/                  # GTK icon theme configuration
    kitty/                # Terminal emulator
  system/
    keyring/              # GNOME Keyring + gcr-ssh-agent
    plymouth/             # Boot splash screen
    power/                # Power management aggregator
                          # Defines all hyprflake.system.power options
      profiles-daemon.nix # power-profiles-daemon backend
      tlp.nix             # TLP backend
      thermal.nix         # thermald
      sleep.nix           # Suspend/hibernate config
      logind.nix          # Logind event handling
    user/                 # User profile photo (AccountsService)
```

## Options Flow

Options are **co-located** — each module defines its own options alongside its config:

```nix
# modules/desktop/hypridle/default.nix
{ config, lib, pkgs, ... }:
let cfg = config.hyprflake.desktop.hypridle;
in {
  options.hyprflake.desktop.idle = { ... };        # timeout options
  options.hyprflake.desktop.hypridle.enable = ...;  # enable toggle
  config = lib.mkIf cfg.enable { ... };
}
```

The NixOS module system merges options globally after all imports. A consumer sets:

```nix
hyprflake.desktop.idle.lockTimeout = 600;
hyprflake.desktop.hypridle.enable = true;  # default
```

## Enable Toggle Pattern

All feature modules have an `enable` option defaulting to `true` for backward compatibility:

```nix
options.hyprflake.desktop.swaync.enable =
  lib.mkEnableOption "SwayNC notification daemon" // { default = true; };
config = lib.mkIf cfg.enable { ... };
```

Consumers disable components they don't want:

```nix
hyprflake.desktop.swaync.enable = false;   # use dunst instead
hyprflake.home.kitty.enable = false;       # use alacritty instead
```

Cross-module dependencies to be aware of when disabling:
- **swayosd**: Hyprland volume/brightness keybinds call `swayosd-client`
- **rofi**: Hyprland `$menu` variable uses `rofi`
- **kitty**: Hyprland `$term` variable uses `kitty`
- **swaync**: Hyprland `mainMod+N` calls `swaync-client`

## Stylix Integration

Hyprflake uses [Stylix](https://github.com/danth/stylix) for system-wide theming:

1. Consumer sets `hyprflake.style.*` options (color scheme, fonts, cursor, opacity)
2. `modules/desktop/stylix/default.nix` maps these to `stylix.*` config
3. All other modules inherit colors/fonts/cursor from Stylix automatically
4. Stylix is imported as a NixOS module via `hyprflakeInputs.stylix.nixosModules.stylix`

## Consumer Import Pattern

```nix
# In a consuming flake's NixOS configuration:
{
  imports = [ hyprflake.nixosModules.default ];

  hyprflake = {
    user.username = "dustin";
    style.colorScheme = "catppuccin-mocha";
    style.wallpaper = ./wallpaper.png;
    desktop.idle.lockTimeout = 600;
    system.power.profilesBackend = "power-profiles-daemon";
  };
}
```

## Home Manager Integration

Most desktop modules use `home-manager.sharedModules` to configure per-user settings. Inside these modules, NixOS config is accessed via `osConfig` (not `config`, which refers to HM config):

```nix
home-manager.sharedModules = [
  ({ osConfig, ... }: {
    # osConfig.hyprflake.*  -> NixOS options
    # config.*              -> Home Manager options
  })
];
```
