# Technical Notes

Implementation details and internal workings of hyprflake components.

## Waybar Auto-Hide

The waybar-auto-hide utility provides automatic Waybar visibility management.

**Integration:** Enabled by default via `hyprflake.waybar-auto-hide.enable = true`

**Functionality:**

- Monitors workspace state through Hyprland IPC
- Automatically hides Waybar when workspace is empty
- Reveals Waybar when cursor approaches top screen edge

**Requirements:**

- Waybar IPC enabled (configured automatically in waybar module)
- Launched via Hyprland `exec-once` (handled by module)

**Source:** [bashfulrobot/nixpkg-waybar-auto-hide](https://github.com/bashfulrobot/nixpkg-waybar-auto-hide)

**Disable:**

```nix
hyprflake.waybar-auto-hide.enable = false;
```

## Hyprshell Window Switcher

The hyprshell integration provides native alt-tab window switching.

**Integration:** Always enabled automatically (no configuration needed)

**Functionality:**

- Alt-tab window switching using the `Alt` modifier key
- Filters windows by current monitor only
- Does not switch workspaces

**Features Disabled:**

- Launcher functionality disabled (using rofi instead)
- Overview mode disabled

**Requirements:**

- Uses `pkgs.hyprshell` from nixpkgs
- Automatically configured via Home Manager `services.hyprshell`
- Hyprland plugin built at runtime (version synced with nixpkgs Hyprland)

**Source:** [nixpkgs hyprshell package](https://search.nixos.org/packages?channel=unstable&query=hyprshell)

## Shortcuts Viewer

Dynamic keybinding discovery system.

**Features:**

- Query `hyprctl` for real-time keybindings and global shortcuts
- Multiple display modes: Rofi (GUI) or terminal (fzf)
- Sub-20ms query time
- Human-readable formatting with icons
- Fuzzy search via rofi or fzf
- No rebuild needed - reflects current runtime configuration

**Default Keybindings:**

- `Super+/` - Show keybindings
- `Super+Shift+/` (displays as `?`) - Show global shortcuts

**Configure display mode:**

```nix
hyprflake.shortcuts-viewer.defaultDisplay = "terminal";  # or "rofi" (default)
```

## XDG Autostart

Automatic execution of `.desktop` files via dex.

**Enabled by default:** `hyprflake.autostart.enable = true`

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

## Mouse Focus Behavior

Configure window focus behavior:

```nix
hyprflake.desktop.mouse = {
  followFocus = false;  # Click to focus (default)
};
```

- `followFocus = false` (default): Windows only gain focus when clicked
- `followFocus = true`: Focus-follows-mouse (windows gain focus on cursor enter)

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
