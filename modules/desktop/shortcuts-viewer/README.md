# Shortcuts Viewer

Dynamic Hyprland keybinding and global shortcut viewer with rofi and terminal (fzf) support.

## Features

- **Dynamic queries**: Uses `hyprctl binds -j` and `hyprctl globalshortcuts -j` for real-time data
- **Fast**: Sub-20ms query time, imperceptible to users
- **Multiple displays**: Rofi (GUI) or terminal (fzf) with the same data
- **Human-readable**: Formatted with icons and proper spacing
- **Filtering**: Built-in fuzzy search via rofi/fzf
- **Always accurate**: No rebuild needed, reflects runtime state

## Usage

### Enable the Module

```nix
hyprflake.shortcuts-viewer = {
  enable = true;
  defaultDisplay = "rofi";  # or "terminal"
};
```

### Default Keybindings

- `Super + ?` - Show regular keybindings
- `Super + Shift + ?` - Show global shortcuts

### Command Line

The module provides several commands:

```bash
# Main command (uses defaultDisplay)
hypr-shortcuts binds         # Show keybindings
hypr-shortcuts global        # Show global shortcuts

# Explicit display choice
hypr-shortcuts binds rofi    # Keybindings in rofi
hypr-shortcuts binds terminal # Keybindings in terminal/fzf
hypr-shortcuts global rofi   # Global shortcuts in rofi
hypr-shortcuts global terminal # Global shortcuts in terminal/fzf

# Convenience commands
hypr-shortcuts-rofi          # Keybindings in rofi
hypr-shortcuts-rofi-global   # Global shortcuts in rofi
hypr-shortcuts-terminal      # Keybindings in terminal
hypr-shortcuts-terminal-global # Global shortcuts in terminal
```

### Custom Keybindings

Override the default keybindings:

```nix
hyprflake.shortcuts-viewer = {
  enable = true;
  defaultDisplay = "terminal";

  keybindings = {
    showBinds = "SUPER, F1, exec, hypr-shortcuts-terminal";
    showGlobal = "SUPER SHIFT, F1, exec, hypr-shortcuts-terminal-global";
  };
};
```

## Implementation Details

### Data Source

- **Keybindings**: `hyprctl binds -j` queries Hyprland IPC for current bindings
- **Global shortcuts**: `hyprctl globalshortcuts -j` queries registered global shortcuts
- **Formatting**: `jq` parses JSON and formats human-readable output
- **Display**: Piped to rofi or fzf for interactive filtering

### Performance

- Query time: ~1-2ms (hyprctl)
- Formatting: ~5-10ms (jq + column)
- Total latency: <20ms (imperceptible)

### Terminal Fallback

When triggered from a keybinding (not in a terminal), the script:
1. Detects if running in a terminal
2. If not, launches kitty or foot with the fzf display
3. Falls back to rofi if no terminal emulator available

## Dependencies

- `jq` - JSON parsing and formatting
- `fzf` - Terminal fuzzy finder (for terminal display)
- `rofi` - Application launcher (for GUI display)
- `hyprland` - Window manager (provides hyprctl)

All dependencies are automatically installed when the module is enabled.

## Example Output

### Keybindings Format
```
󰘳 Super + Shift + E      → exec      wlogout
󰘳 Super + Q              → killactive
󰘳 Super + 1              → workspace  1
 Ctrl + Alt + Delete     → exec      hyprctl dispatch exit
```

### Global Shortcuts Format
```
media_play_pause  → Play/Pause media
media_next        → Next track
media_previous    → Previous track
```
