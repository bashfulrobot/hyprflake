# Technical Notes

Implementation details and internal workings of hyprflake components.

## Desktop Shell (DankMaterialShell)

The status bar, app launcher, notifications, on-screen display, power menu,
lock screen, and idle daemon are all provided by DankMaterialShell (DMS), a
Quickshell/QML shell that runs as a single systemd user service (`dms.service`).
It is hyprflake's core shell and is always enabled.

**Functionality (replaces the old waybar stack):**

- Status bar with workspaces, tray, clock, media, and system widgets — bar
  layout is configured declaratively via `programs.dank-material-shell.settings`
  (`modules/desktop/dank/default.nix`); see `docs/styling.md`
- App launcher / spotlight, notifications, OSD, power menu — invoked from
  Hyprland keybinds that dispatch to `dms ipc <target>`
- Window **overview/exposé** via `dms ipc hypr toggleOverview` (a spatial grid,
  not an MRU switcher). Bound to `SUPER + Tab` — DMS's own default — which
  toggles it open/closed; navigate with the mouse or Left/Right and Esc to
  close. Classic **alt-tab** is left to native Hyprland: `ALT + Tab` /
  `ALT + SHIFT + Tab` cycle windows via `hl.dsp.window.cycle_next()`

**Theming:** Stylix's `dank-material-shell` target feeds DMS its colors, fonts,
opacity, and the wallpaper path; DMS's own matugen is disabled so Stylix stays
the single source of truth.

**Restart to apply settings:** DMS reads `settings.json` once at startup, so a
rebuild that changes the dank settings only takes effect after
`systemctl --user restart dms.service`.

## Shortcuts Viewer

Dynamic keybinding discovery system.

**Features:**

- Renders `hyprctl binds -j` into a Stylix-themed HTML cheat sheet on each open
  and launches it in the default browser
- Always current — reads the live runtime config, no rebuild needed
- Not replaced by DMS's built-in cheatsheet: that parses hyprlang `*.conf`
  `bind=` text, but this flake uses the Lua config backend, so the DMS parser
  would see none of our binds (see `docs/architecture.md`)

**Default Keybindings:**

- `Super+/` - Show keybindings
- `Super+Shift+/` (displays as `?`) - Show global shortcuts

**Configure display mode:**

```nix
# Only "browser" is implemented (themed HTML page). "rofi" and "terminal"
# are deprecated no-ops kept for option compatibility.
hyprflake.desktop.shortcutsViewer.defaultDisplay = "browser";
```

## Runtime hyprctl under the Lua config backend

This flake drives Hyprland with the **Lua config parser**
(`programs.hyprland.settings` emits `hl.*` snippets; `configType = "lua"` in
`modules/desktop/hyprland/default.nix`). Under that parser the classic
runtime control commands are **inert**, which silently breaks scripts written
for the legacy `*.conf` backend:

- `hyprctl keyword <name> <value>` → errors with
  `keyword can't work with non-legacy parsers. Use eval.` — it never applies.
- `hyprctl dispatch <name> <args>` (raw) → the arguments are mis-parsed as Lua
  (`hl.dispatch(<name> <args>)`) and throw a syntax error.

The working runtime API is `hyprctl eval '<lua>'`:

- **Config keywords** apply directly through their Lua function, e.g.
  `hyprctl eval 'hl.monitor({output="HDMI-A-1", mode="preferred", position="auto", scale=1})'`
  or `hyprctl eval 'hl.workspace_rule({workspace="10", monitor="HDMI-A-1", default=true})'`.
- **Dispatchers must be wrapped** in `hl.dispatch(...)` to actually fire:
  `hyprctl eval 'hl.dispatch(hl.dsp.focus({workspace=10}))'`. A bare
  `hl.dsp.<x>(...)` call only *builds* a dispatcher object and is a no-op at
  runtime (it is only meaningful as the handler argument to `hl.bind`).

Read-only queries (`hyprctl monitors -j`, `hyprctl workspaces -j`,
`hyprctl binds -j`) and `hyprctl reload` are unaffected and work normally.
`hyprctl eval` swallows return values (it prints `ok`); to inspect a value
while debugging, raise it: `hyprctl eval 'error(tostring(x))'`.

The `tv-workspace` helper (`modules/desktop/hyprland/default.nix`) is the
reference example of applying monitor/workspace changes this way at runtime.

## XDG Autostart

Automatic execution of `.desktop` files via dex. This is the fallback launcher
for non-UWSM sessions. Under UWSM, systemd's `xdg-desktop-autostart.target`
services `~/.config/autostart` once `graphical-session.target` activates, so the
dex hook is left off to avoid launching every entry twice.

**Default:** `hyprflake.desktop.autostart.enable` defaults to
`!config.programs.hyprland.withUWSM` — enabled only on non-UWSM hosts. See
`docs/uwsm-session.md` for how UWSM brings up the session targets.

**Directories:**

- `~/.config/autostart/`
- `/etc/xdg/autostart/`

**Supported directives:**

- `OnlyShowIn` / `NotShowIn` - Environment filtering
- `Hidden` - Disable without deleting
- `TryExec` - Conditional execution

**Manual execution:**

```bash
dex --autostart --environment Hyprland
```

## Module Dependencies

- All modules are optional with enable flags
- NixOS hyprland module enables core Hyprland functionality
- Other modules extend with specific features (caching, theming, etc.)
- Helper functions automatically include all necessary modules

## XDG Portals

Hyprflake configures XDG portals correctly for Hyprland:

- Portal backend selection handled automatically
- File picker, screen sharing, and other portal features work out of the box

## Audio

Audio is configured via PipeWire automatically when hyprflake is enabled.
