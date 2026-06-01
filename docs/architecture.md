# Hyprflake Architecture

## Overview

Hyprflake is a NixOS module library flake that provides a complete Hyprland desktop environment. Consumers import `nixosModules.default` and configure via `hyprflake.*` options.

## Module Tree

```
modules/
  default.nix             # Entry point — imports all modules, passes hyprflakeInputs
  desktop/
    autostart/            # XDG autostart support via dex
    dank/                 # DankMaterialShell desktop shell (bar, launcher,
                          # notifications, OSD, power menu, lock, idle).
                          # hyprflake's core shell; always enabled, no toggle.
    display-manager/      # GDM display manager + xkb keyboard config
    gtk/                  # GTK icon theme configuration
    hyprland/             # Core Hyprland config, keybinds, env vars, window rules.
                          # Also defines hyprflake.desktop.keyboard + terminal options.
                          # Keybinds dispatch to `dms ipc` (launcher,
                          # notifications, power, lock, volume, brightness).
    kitty/                # Terminal emulator
    shortcuts-viewer/     # Keybinding cheat sheet (Stylix-themed HTML page
                          # rendered from `hyprctl binds`, opened in browser)
    stylix/               # Stylix theming integration.
                          # Defines all hyprflake.style options; enables the
                          # stylix.targets.dank-material-shell target.
    system-actions/       # Desktop entries for lock/reboot/shutdown
    themes/               # Additional theme assets
    voxtype/              # Push-to-talk voice-to-text
    wl-clip-persist/      # Clipboard persistence

    # Status bar retired in favor of dank/, but their option surface is still
    # consumed (workspaceAppIcons.*, autoHide), so they remain real modules.
    waybar/ waybar-auto-hide/

    # Deprecated options-only stubs (swaync, swayosd, rofi, rofimoji, wlogout,
    # hyprshell, hyprlock, hypridle) collapsed into one file. Replaced by dank/;
    # each emits a no-op warning. Remove once consumers drop the options.
    deprecated-stubs.nix
  system/
    keyring/              # GNOME Keyring + gcr-ssh-agent
    plymouth/             # Boot splash screen
    power/                # Power management aggregator
                          # Defines all hyprflake.system.power options
      idle.nix            # Idle policy: hyprflake.desktop.idle.* (lock/dpms/suspend)
      profiles-daemon.nix # power-profiles-daemon backend
      tlp.nix             # TLP backend
      thermal.nix         # thermald
      sleep.nix           # Suspend/hibernate config
      logind.nix          # Logind event handling
    user/                 # User profile photo (AccountsService)
```

## Options Flow

Options are **co-located** — each module defines its own options alongside its
config. The declaration's *location* is decoupled from its *namespace*: idle is
power-management policy, so it is declared with the power module even though its
consumer-facing namespace stays under `desktop`:

```nix
# modules/system/power/idle.nix — declares the policy
{ lib, ... }:
{
  options.hyprflake.desktop.idle = { ... };  # lock/dpms/suspend timeouts
}

# modules/desktop/dank/default.nix — consumes it
{ config, pkgs, hyprflakeInputs, ... }:
let idle = config.hyprflake.desktop.idle;
in {
  config = { ... };  # wires DMS idle settings from the values above
}
```

The NixOS module system merges options globally after all imports. A consumer sets:

```nix
hyprflake.desktop.idle.lockTimeout = 600;
```

## Enable Toggle Pattern

Optional feature modules expose an `enable` option (e.g. `desktop.voxtype.enable`,
default `false`). The **core shell (dank) has no toggle** — it is always present.
A toggle would only be warranted if hyprflake supported multiple shells.

The retired waybar-stack modules keep `enable` options as no-op deprecation stubs
(`modules/desktop/deprecated-stubs.nix`, plus `waybar`/`waybar-auto-hide` which
retain consumed option surface) so consumer configs that still set them keep
evaluating; each emits a build warning.

Cross-module dependencies to be aware of:

- **dank / hyprland**: Hyprland keybinds dispatch to `dms ipc` (launcher,
  notifications, power menu, lock, clipboard, volume, brightness). The dank shell
  provides the `dms` binary; both modules are core and always enabled.
- **kitty**: Hyprland's `$term` variable defaults to `kitty` (override via
  `hyprflake.desktop.terminal`).

## Desktop shell (DankMaterialShell)

The desktop shell is [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
(DMS), a Quickshell/QML shell that provides the status bar, app launcher,
notifications, on-screen display, power menu, lock screen, and idle daemon in
one process. It replaces the previous waybar stack (waybar, swaync, swayosd,
rofi, rofimoji, wlogout, hyprshell) plus hyprlock and hypridle.

- `modules/desktop/dank/default.nix` imports DMS's `homeModules.dank-material-shell`,
  runs `pkgs.dms-shell` + `pkgs.quickshell` (prebuilt from nixpkgs), autostarts
  via its systemd user service (`dms.service`), and configures the idle ladder
  from `hyprflake.desktop.idle.*`.
- The retired modules remain as options-only deprecation stubs so consumer
  configs keep evaluating; each emits a no-op `warning`.

## Stylix Integration

Hyprflake uses [Stylix](https://github.com/danth/stylix) for system-wide theming:

1. Consumer sets `hyprflake.style.*` options (color scheme, fonts, cursor, opacity)
2. `modules/desktop/stylix/default.nix` maps these to `stylix.*` config
3. All other modules inherit colors/fonts/cursor from Stylix automatically
4. Stylix is imported as a NixOS module via `hyprflakeInputs.stylix.nixosModules.stylix`
5. The `stylix.targets.dank-material-shell` target feeds base16 colors, fonts,
   opacity, and the wallpaper path into DMS. DMS's own wallpaper-driven matugen
   is disabled (`enableDynamicTheming = false`) so Stylix stays the single
   source of truth. The wallpaper is owned by DMS (hyprpaper was retired).

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

**Why:** Lua is Hyprland's modern config backend (0.55+); hyprlang is the legacy path. The lua backend is also what `system/hyprctl-compat` assumes — under it, `hyprctl dispatch <legacy args>` is rewritten as a Lua eval, so the flake standardizes on lua throughout.

(Historically lua was adopted because hyprshell needed runtime `eval hl.bind(...)`, which the hyprlang config manager rejects. hyprshell has since been retired in the DankMaterialShell migration, but lua remains the standard for the reason above.)

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
