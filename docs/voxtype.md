# Voxtype - Push-to-Talk Voice-to-Text

Voxtype provides offline push-to-talk voice-to-text using whisper.cpp. Hold a hotkey to record, release to transcribe, and the text is typed at your cursor.

## Enabling

```nix
{
  hyprflake.desktop.voxtype = {
    enable = true;
  };
}
```

This installs voxtype, generates `~/.config/voxtype/config.toml`, sets up a systemd user service for the daemon, and adds a Hyprland submap for modifier suppression during text output.

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `enable` | `bool` | `false` | Enable voxtype |
| `package` | `package` | voxtype flake input | The voxtype package |
| `hotkey` | `string` | `"SCROLLLOCK"` | Evdev key name for push-to-talk (use `evtest` to find names) |
| `model` | `string` | `"base.en"` | Whisper model for transcription |
| `threads` | `nullOr int` | `null` | CPU threads for Whisper inference. When null, voxtype auto-detects. |

## Whisper Models

`.en` models are English-only but faster and more accurate for English.

| Model | Speed | Accuracy | VRAM |
|-------|-------|----------|------|
| `tiny.en` | Fastest | Lower | ~1 GB |
| `base.en` | Fast | Good | ~1 GB |
| `small.en` | Moderate | Better | ~2 GB |
| `medium.en` | Slow | High | ~5 GB |
| `large-v3` | Slowest | Highest | ~10 GB |
| `large-v3-turbo` | Moderate | Highest | ~6 GB |

## Threads

By default, the `threads` option is `null` and no threads setting is written to the config file, letting voxtype auto-detect an appropriate value. Set it explicitly to limit CPU usage:

```nix
{
  hyprflake.desktop.voxtype = {
    enable = true;
    threads = 4;
  };
}
```

The value should not exceed the number of physical CPU cores. Lower values reduce CPU usage; higher values speed up transcription.

## Hyprland Integration

The module installs a Hyprland submap configuration that suppresses modifier keys during text output. This prevents compositor keybindings (like Super) from interfering when voxtype types transcribed text. The submap is loaded from `~/.config/hypr/conf.d/voxtype-submap.conf`.

## Common Hotkey Choices

- `SCROLLLOCK` (default) - dedicated key, rarely used otherwise
- `F13`-`F24` - available on programmable keyboards
- `INSERT` - convenient on full-size keyboards
- `PAUSE` - another rarely-used dedicated key

Use `evtest` to discover the exact evdev key name for your keyboard.
