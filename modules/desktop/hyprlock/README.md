# Hyprlock Module

Screen lock for Hyprland with Style 8 inspired design and automatic Stylix theme integration.

## Features

- **Style 8 Inspired Layout**: Large split clock display with modern aesthetic (based on [Hyprlock-Styles](https://github.com/MrVivekRajan/Hyprlock-Styles))
- **Stylix Theme Integration**: Colors, fonts, and wallpaper automatically match your system theme
- **Wallpaper Background**: Uses the same wallpaper as Hyprland with blur effect
- **Split Time Display**: Hour and minute shown separately in large typography
- **Date Display**: Day and date with accent color highlighting
- **Password Input**: Semi-transparent input field with personalized greeting
- **Layout Indicator**: Shows current keyboard layout at bottom

## Configuration

The module provides a complete lock screen with no additional configuration needed:

```nix
{
  imports = [ ./modules/desktop/hyprlock ];
}
```

## Visual Layout

```
┌─────────────────────────────────────┐
│         [Wallpaper Background]      │
│                                     │
│               14                    │  ← Hour (accent color, 180px)
│                                     │
│               25                    │  ← Minutes (white, 180px)
│                                     │
│        Monday, 23 December          │  ← Date
│                                     │
│      ┌──────────────────┐          │
│      │   Hi, username   │          │  ← Input field
│      └──────────────────┘          │
│                                     │
│      Current Layout: us             │  ← Keyboard layout
└─────────────────────────────────────┘
```

## Styling

All visual elements are automatically themed via Stylix:
- **Wallpaper**: Same as Hyprland (`config.stylix.image`)
- **Hour color**: Base0A (yellow/accent) with 60% opacity
- **Minute color**: Base05 (foreground/white) with 60% opacity
- **Date colors**: Base05 for day, Base0A for date
- **Input field**: Base02 background with Base05 text
- **Fonts**: Sans-serif for time/date, monospace for layout indicator

The wallpaper has blur, contrast, and vibrancy adjustments for optimal readability.

**Note**: This module disables Stylix's hyprlock target (`stylix.targets.hyprlock.enable = false`) to use the custom Style 8 layout while still pulling colors, fonts, and wallpaper from your Stylix theme.

## Integration with Hypridle

Hyprlock works seamlessly with hypridle:
- Hypridle triggers lock via `loginctl lock-session`
- Hyprlock listens for session lock events
- Unlock signal (`SIGUSR1`) from hypridle on resume

## Manual Locking

Lock screen manually:
```bash
loginctl lock-session
# or directly
hyprlock
```

## Customization

Override any setting via home-manager:

```nix
home-manager.sharedModules = [
  (_: {
    programs.hyprlock.settings = {
      # Change blur intensity
      background = [
        {
          monitor = "";
          blur_passes = 3;  # More blur
        }
      ];

      # Customize labels
      label = lib.mkForce [
        {
          monitor = "";
          text = "🔒 Locked";
          font_size = 48;
        }
      ];
    };
  })
];
```

## Variables Available

- `$TIME` - Current time (formatted by system)
- `$USER` - Username
- `$LAYOUT` - Current keyboard layout
- `$FAIL` - Failure message on wrong password
- `$ATTEMPTS` - Number of failed attempts

## Dependencies

- **hyprland**: Window manager
- **pam**: Authentication
- **stylix**: Theme integration (optional but recommended)

## See Also

- [Hypridle Module](../hypridle/README.md) - Automatic idle management
- [Hyprland Wiki - Hyprlock](https://wiki.hypr.land/Hypr-Ecosystem/hyprlock/)
