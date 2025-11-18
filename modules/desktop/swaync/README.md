# SwayNC - Notification Center

## Overview

Minimal SwayNotificationCenter implementation with full Stylix theming support. Provides simple desktop notifications with a notification center panel.

## Features

- ✅ Desktop notifications for all applications
- ✅ Notification center with history
- ✅ Do Not Disturb toggle
- ✅ Automatic Stylix theming (colors and fonts)
- ✅ Waybar integration (notification counter)
- ✅ Urgency levels (low, normal, critical)

## Configuration

### Minimal Design Philosophy

This implementation follows hyprflake's minimal approach:
- **No complex widgets** - Just title, DND, and notifications
- **Stylix theming only** - All colors/fonts from Stylix
- **Simple settings** - Basic notification display

### What's NOT Included (vs nixcfg)

- ❌ MPRIS media controls
- ❌ Quick action buttons (bluetooth, network, etc.)
- ❌ Custom button grids
- ❌ Multiple widgets

**Rationale:** Keep it simple. Complex widgets can be added later if needed.

## Waybar Integration

The waybar module (already configured) provides:

**Notification Icon:**
- Shows notification count when notifications are present
- Click: Toggle notification center
- Right-click: Toggle Do Not Disturb

**Module Location:** `modules-center` in waybar

## Keyboard Shortcuts

SwayNC has built-in keyboard shortcuts when the notification center is open:
- `Escape` - Close notification center
- `Delete` - Clear all notifications
- Arrow keys - Navigate notifications

## Theming

All styling is automatic via Stylix:

### Colors (GTK Variables)
- Background: `@theme_base_color`
- Text: `@theme_text_color`
- Borders: `@surface1`
- Urgency indicators: `@green`, `@blue`, `@red`
- Buttons: `@blue`, `@lavender`

### Fonts
- Font family: `config.stylix.fonts.sansSerif.name`
- Font size: `config.stylix.fonts.sizes.applications`

### Customization

To customize, edit:
- **Settings:** `modules/desktop/swaync/default.nix`
- **Styling:** `modules/desktop/swaync/style.nix`

Both files use the Stylix helper library for consistent theming.

## Usage

### For Users

Notifications appear automatically in the top-right corner.

**Open notification center:**
- Click waybar notification icon
- Or: `swaync-client -t -sw`

**Toggle Do Not Disturb:**
- Right-click waybar notification icon
- Or toggle in notification center

### For Developers

**Test notifications:**
```bash
notify-send "Test" "This is a test notification"
notify-send -u critical "Critical" "This is urgent"
```

**Check status:**
```bash
swaync-client --help
swaync-client --get-dnd
swaync-client --toggle-dnd
```

## Architecture

```
modules/desktop/swaync/
├── default.nix    - Service configuration
├── style.nix      - Stylix-aware CSS
└── README.md      - This file
```

**Integration:**
- Uses `lib/stylix-helpers.nix` for theme access
- Loaded via `modules/default.nix`
- Waybar integration in `modules/desktop/waybar/default.nix`

## Comparison with nixcfg

| Feature | nixcfg | hyprflake |
|---------|--------|-----------|
| Basic notifications | ✅ | ✅ |
| Notification center | ✅ | ✅ |
| DND toggle | ✅ | ✅ |
| Stylix theming | ✅ | ✅ |
| MPRIS controls | ✅ | ❌ |
| Button grid | ✅ | ❌ |
| Custom widgets | ✅ | ❌ |

**Philosophy:** hyprflake provides the foundation. Consumers can extend with additional widgets if needed.

## Future Enhancements

Potential additions (opt-in):
- [ ] MPRIS widget for media controls
- [ ] Quick action buttons
- [ ] Custom notification actions
- [ ] Sound on notification
- [ ] Per-app notification settings

## Dependencies

**Runtime:**
- swaynotificationcenter (package)
- waybar (for notification counter)
- Stylix (for theming)

**Provided by other modules:**
- Font packages (from Stylix)
- GTK theme (from Stylix)

## Troubleshooting

**No notifications appearing:**
```bash
# Check if service is running
systemctl --user status swaync.service

# Restart service
systemctl --user restart swaync.service
```

**Styling not applied:**
- Verify Stylix is enabled and configured
- Check `~/.config/swaync/style.css` exists
- Restart swaync: `swaync-client --reload-css`

**Waybar icon not updating:**
- Verify `swaync-client` is in PATH
- Check waybar module has `custom/notification` configured
- Restart waybar: `pkill waybar`
