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
    snappy-switcher/      # Traditional MRU Alt+Tab window switcher (opt-in).
                          # Owns ALT+Tab when enabled; DMS-first exception.
    stylix/               # Stylix theming integration.
                          # Defines all hyprflake.style options; enables the
                          # stylix.targets.dank-material-shell target.
    system-actions/       # Desktop entries for lock/reboot/shutdown
    themes/               # Additional theme assets
    update-checks/        # systemd user timer: flag DMS / Hyprland /
                          # dms-emoji-launcher / Voxtype updates on the workstation
    voxtype/              # Push-to-talk voice-to-text
    wl-clip-persist/      # Clipboard persistence
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

The retired waybar-stack modules (waybar, waybar-auto-hide, swaync, swayosd,
rofi, rofimoji, wlogout, hyprshell, hyprlock, hypridle) and their no-op
deprecation stubs have been removed; consumers must drop any
`hyprflake.desktop.<retired>` options they still set.

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
- The retired waybar-stack modules and their deprecation stubs have been
  removed; their options no longer exist.

### DMS-first principle (standing)

DMS is the shell, so hyprflake is **DMS-first**: for any desktop-shell feature —
bar widgets, launcher, notifications, OSD, power menu, lock, idle, media /
volume / brightness control, color picker, night mode, emoji picker, bluetooth
agent, and so on — prefer DMS's built-in capability over adding a standalone
tool. Bar layout and shell appearance are configured declaratively through
`programs.dank-material-shell.settings` (see `docs/styling.md`).

This was conditional during the migration (while `main` still shipped waybar);
it is now the **standing default** — `main` is the DMS setup and the waybar
stack is preserved only on the `waybar-archive` branch.

When adding a feature, the order is: (1) does DMS already do it? wire its IPC /
a bar widget / a setting; (2) does DMS do it but it isn't wired? wire it;
(3) only if DMS genuinely lacks it (or coverage is unverified) add a standalone
tool, and record why. Reasons to keep a standalone tool decay as DMS evolves —
revisit them on DMS bumps.

**Current standing exceptions (DMS does not cover these well yet):**

- `shortcuts-viewer` — DMS's cheatsheet parses hyprlang `*.conf` `bind=` text;
  this flake is Lua, so the parser sees none of our binds. The custom viewer
  renders live `hyprctl binds -j` instead (format-agnostic). See the
  shortcuts-viewer note below.
- `pwvucontrol` — full per-app PipeWire mixer (DMS audio is basic volume).
- `impala` — WiFi TUI fallback (DMS control center handles normal network use).
- `snappy-switcher` — traditional MRU Alt+Tab switcher (opt-in, default off).
  DMS's `SUPER+Tab` `toggleOverview` is a spatial exposé, not a most-recently-used
  switcher, and DMS ships no alt-tab switcher. snappy-switcher is a standalone
  Wayland layer-shell overlay that talks to Hyprland IPC directly, so it neither
  depends on nor conflicts with DMS. When `desktop.snappySwitcher.enable` is set,
  the hyprland module drops its native `cycle_next` ALT+Tab fallback so snappy is
  the sole owner of those keys (`modules/desktop/snappy-switcher`).

(Already absorbed by DMS and dropped: playerctl, hyprpicker, hyprsunset,
blueman, plus the whole waybar stack — waybar, swaync, swayosd, rofi, rofimoji,
wlogout, hyprshell, hyprlock, hypridle.)

### DMS IPC dispatch (Hyprland keybinds)

Keybinds in `modules/desktop/hyprland/default.nix` dispatch to DMS over its CLI
(`dms ipc <target> <fn>`; the `call` keyword is auto-inserted by the dms wrapper,
so omitting it is fine). DMS owns these, so hyprflake ships no standalone tool
for them:

- launcher (`spotlight`), notifications, power menu (`powermenu`), clipboard,
  control center / network+bluetooth (`control-center`), lock (`lock lock`)
- volume + mic (`audio increment|decrement|mute|micmute`), brightness
  (`brightness increment|decrement N ""`)
- **media keys** (`mpris playPause|next|previous`) — replaces the old playerctl
  wrapper scripts
- **screen color picker** (`color-picker toggle`, SUPER+SHIFT+C) — replaces
  hyprpicker; copies the hex to the clipboard
- **night mode / color temperature** (`night`) — replaces hyprsunset; lives in
  the DMS control center with time/location automation

### Why shortcuts-viewer is NOT replaced by DMS's built-in cheatsheet

`modules/desktop/shortcuts-viewer` renders the live keybind table
(`hyprctl binds -j`) into a Stylix-themed HTML page (Super+/). It is kept because
DMS's native cheatsheet overlay is not human-readable for this flake's binds.
Verified live (2026-06, DMS 1.4) against running Hyprland + DMS:

- **DMS's built-in `hyprland` provider DOES surface our binds.** `dms keybinds
  show hyprland` returns nearly all of them with `source: "config"` — the older
  claim that it would "show zero binds" against a Lua config is false. But for
  `exec` binds it shows the raw dispatcher body as the description
  (e.g. `SUPER+RETURN → (hl.dsp.exec_cmd("/nix/store/…/ghostty"))`) instead of
  our `{ description = "Open terminal" }`. The overlay (`dms ipc call keybinds
  toggle hyprland`) renders that verbatim — unreadable for exec-heavy configs.
  (It does extract descriptions for some forms — `resize` binds and the Super+/
  bind showed clean text — so a future DMS that reads `{ description = }` from
  Lua exec binds could make the built-in overlay viable with no extra tooling.)
- **Custom JSON cheatsheets do not render in the overlay on this build.** DMS
  supports `~/.config/DankMaterialShell/cheatsheets/<provider>.json`
  (`{ title, provider, binds: { "<cat>": [ {key, desc} ] } }`). A generated
  `hyprflake.json` (clean descriptions, from the same `hyprctl binds -j`) is
  read correctly by the *terminal* `dms keybinds show hyprflake`, but
  `dms ipc call keybinds toggle hyprflake` ignored the custom provider and fell
  back to the live `hyprland` parser — so it gives no integrated overlay, only a
  terminal pager, which is not an improvement over the HTML page.

Net: the HTML viewer remains the most human-readable option. Revisit if a DMS
release either extracts `{ description = }` from Lua exec binds (built-in overlay
becomes viable) or renders custom JSON providers in the in-shell overlay (the
generate-JSON route becomes viable). This is a deliberate DMS-first exception.

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

**Why:** hyprlang is **deprecated** upstream. As of Hyprland 0.55 the config language moved to Lua; the old hyprlang format is supported for only 1–2 more releases and will then be dropped ([Hyprland: Lua-ification of configs](https://hypr.land/news/26_lua/)). Staying on Lua is the forward-compatible choice — adopting it now avoids a forced migration later. The lua backend is also what `system/hyprctl-compat` assumes (under it, `hyprctl dispatch <legacy args>` is rewritten as a Lua eval).

**Do not move back to hyprlang to satisfy a tool.** If something only reads hyprlang config (e.g. DMS's built-in keybinds cheatsheet, which parses `*.conf` `bind=` text — see the shortcuts-viewer note above), work around it on the Lua side rather than regressing the config format.

**The Lua backend requires DMS from the flake input, not nixpkgs.** Under a Lua config, Hyprland evaluates IPC socket dispatch requests *as Lua* — `dispatch workspace 3` becomes `return hl.dispatch(workspace 3)`, a syntax error. nixpkgs' `dms-shell` (1.4.6) sends those legacy strings, so clicking a workspace and selecting a window from the overview silently fail. DMS master (1.5-beta) fixed it: `HyprlandService.qml` emits `hl.dsp.*` Lua-form dispatch. So `modules/desktop/dank` pins `programs.dank-material-shell.package` to `hyprflakeInputs.dank-material-shell.packages.<system>.dms-shell` (the input tracks `master`, not `stable`). Quickshell stays on nixpkgs — the DMS flake no longer ships it. Revert both the input ref (`/master` → `/stable`) and the package (flake → `pkgs.dms-shell`) once the dual-path dispatch reaches a tagged DMS release. `hyprctl` itself is unaffected because `system/hyprctl-compat` already rewrites legacy `hyprctl dispatch <args>` as a Lua eval.

(Historically lua was first adopted because hyprshell needed runtime `eval hl.bind(...)`, which the hyprlang manager rejects. hyprshell has since been retired, but the deprecation above is now the standing reason.)

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
