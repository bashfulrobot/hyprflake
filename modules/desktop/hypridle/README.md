# Hypridle Module

Idle management daemon for Hyprland that handles screen locking, display power management, and system suspend.

## Features

- **Automatic Screen Lock**: Locks screen after 5 minutes of inactivity
- **Display Power Management**: Turns off display after 6 minutes
- **System Suspend**: Suspends system after 10 minutes
- **D-Bus Inhibit Respect**: Honors application requests to prevent idle (e.g., video players)
- **Sleep Integration**: Locks session before sleep and restores display on wake

## Configuration

The module provides sensible defaults and requires no additional configuration:

```nix
{
  imports = [ ./modules/desktop/hypridle ];
}
```

## How It Works

### Timeout Chain

1. **5 minutes** - Lock screen (via `loginctl lock-session`, triggers hyprlock)
2. **6 minutes** - Turn off display (via `hyprctl dispatch dpms off`)
3. **10 minutes** - Suspend system (via `systemctl suspend`)

### Integration with Hyprlock

Hypridle works seamlessly with hyprlock:
- Uses `pidof hyprlock || hyprlock` to prevent duplicate lock screen instances
- Sends `SIGUSR1` signal to unlock hyprlock when resuming
- Locks session before system sleep

### D-Bus Inhibit

Applications can prevent idle via D-Bus inhibit:
- Video players (mpv, VLC, Firefox videos)
- Presentation software
- Games

Set `ignore_dbus_inhibit = true` in settings to override this behavior.

## Customization

Override timeout values via home-manager:

```nix
home-manager.sharedModules = [
  (_: {
    services.hypridle.settings.listener = lib.mkForce [
      { timeout = 600; on-timeout = "loginctl lock-session"; }
      { timeout = 900; on-timeout = "systemctl suspend"; }
    ];
  })
];
```

## Manual Control

Lock screen manually:
```bash
loginctl lock-session
```

Toggle display power:
```bash
hyprctl dispatch dpms off  # Turn off
hyprctl dispatch dpms on   # Turn on
```

## Dependencies

- **hyprlock**: Screen lock program (separate module)
- **systemd**: For `loginctl` and `systemctl` commands
- **hyprland**: For `hyprctl` display power management

## See Also

- [Hyprlock Module](../hyprlock/README.md) - Screen lock visual configuration
- [Hyprland Wiki - Hypridle](https://wiki.hypr.land/Hypr-Ecosystem/hypridle/)
