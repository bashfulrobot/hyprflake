# Hyprflake Architecture

## Overview

Hyprflake is a NixOS module library flake that provides a complete Hyprland desktop environment. Consumers import `nixosModules.default` and configure via `hyprflake.*` options.

## Module Tree

```
modules/
  default.nix             # Entry point — imports all modules, passes hyprflakeInputs
  desktop/
    autostart/            # XDG autostart support via dex
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

## Hyprland Lua Config Backend

`modules/desktop/hyprland/default.nix` sets `wayland.windowManager.hyprland.configType = "lua"`, so home-manager generates `~/.config/hypr/hyprland.lua` (not `hyprland.conf`). The hyprlang backend is no longer supported by this flake.

**Why:** hyprshell registers its alt-tab keybinds at runtime via `eval hl.bind(...)` over the Hyprland IPC socket. The legacy hyprlang config manager rejects `eval` commands with *"eval is only supported with the lua config manager"*. The lua backend is the only path that keeps hyprshell working.

**Implications for sibling modules:**

- Settings that map to Lua functions go in `settings.<fn>`:
  - `settings.bind = [ { _args = [ keyspec dispatcher opts? ]; } … ]` (use `lib.generators.mkLuaInline` for dispatcher expressions and opt-table fields like `{ repeating = true; locked = true; }`).
  - `settings.on = [ { _args = [ "hyprland.start" (mkLuaInline "function() ... end") ]; } ]` — the **only** way to express "exec-once". Use a list so `lib.mkAfter` / `lib.mkIf` from multiple modules compose cleanly.
  - `settings.monitor` / `settings.gesture` / `settings.animation` / `settings.curve` / `settings.window_rule` are top-level — they each render as `hl.<fn>(...)` per list element.
  - `settings.config = { general = {...}; decoration = {...}; ... }` collects everything that maps to a config key (the home-manager serializer normalizes `:` ↔ `.` and `-` ↔ `_` so stylix-injected keys like `["col.active_border"]` continue to work).
- Settings that **do not** map to a Lua function will produce invalid Lua. In particular: `settings.exec-once` renders as `hl.exec-once(...)` which parses as subtraction. Always use `settings.on` instead.
- Hyprlang-format bind strings (`"SUPER, slash, exec, command"`) inside `settings.bind` get passed verbatim as Lua keyspecs and fail — convert to `{ _args = [ ... ]; }` form.

## Hyprland conf.d (`~/.config/hypr/conf.d/*.lua`)

The hyprland module appends a Lua loader to `extraConfig` that globs `~/.config/hypr/conf.d/*.lua` (sorted, `pcall`-wrapped) and `dofile`s each. Downstream consumers can drop additional Hyprland snippets here as **Lua files** containing `hl.*` calls:

```nix
xdg.configFile."hypr/conf.d/my-binds.lua".text = ''
  hl.bind("SUPER + W", hl.dsp.exec_cmd("my-launcher"))
  hl.window_rule({ name = "float-foo", match = { class = "foo" }, float = true })
'';
```

`.conf` files in `conf.d/` are **silently ignored** by the Lua loader — they belonged to the old hyprlang `source = …` glob and need to be ported.
