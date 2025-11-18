# Hyprlock Module

Screen lock for Hyprland with clean visual design and automatic Stylix theme integration.

## Features

- **Stylix Theme Integration**: Colors and fonts automatically match your system theme
- **Blurred Background**: Subtle blur effect with vibrancy for visual appeal
- **Password Input**: Clean input field with attempt counter on failures
- **Time Display**: Large centered clock
- **User Greeting**: Personalized welcome message
- **Layout Indicator**: Shows current keyboard layout

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
│                                     │
│                                     │
│          Hello Username!            │  ← User greeting
│                                     │
│            14:25:37                 │  ← Large clock
│                                     │
│                                     │
│      Current Layout : us            │  ← Keyboard layout
│      ┌──────────────────┐          │
│      │   Password...    │          │  ← Input field
│      └──────────────────┘          │
└─────────────────────────────────────┘
```

## Styling

All colors and fonts are managed by Stylix:
- Background color from theme
- Input field outline from theme accent
- Text colors from theme foreground
- Font families from Stylix configuration

The blur effect provides depth while maintaining visibility.

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
