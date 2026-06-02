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
  not an MRU alt-tab). It is bound to `ALT + Tab`, which toggles the overview
  open/closed — DMS has no traditional most-recently-used alt-tab, so the
  overview stands in as the window switcher

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

## XDG Autostart

Automatic execution of `.desktop` files via dex.

**Enabled by default:** `hyprflake.desktop.autostart.enable = true`

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
