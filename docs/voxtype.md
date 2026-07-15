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

This installs voxtype, generates `~/.config/voxtype/config.toml`, and sets up a systemd user service for the daemon.

## Options

| Option         | Type         | Default             | Description                                                         |
| -------------- | ------------ | ------------------- | ------------------------------------------------------------------- |
| `enable`       | `bool`       | `false`             | Enable voxtype                                                      |
| `acceleration` | `enum`       | `"cpu"`             | Inference backend: `cpu`, `vulkan`, or `rocm`                       |
| `package`      | `package`    | variant from `acceleration` | The voxtype package (overrides `acceleration` when set)     |
| `hotkey`       | `string`     | `"SCROLLLOCK"`      | Evdev key name for push-to-talk (use `evtest` to find names)        |
| `model`        | `string`     | `"base.en"`         | Whisper model for transcription                                     |
| `threads`      | `nullOr int` | `null`              | CPU threads for Whisper inference. When null, voxtype auto-detects. |

## Whisper Models

`.en` models are English-only but faster and more accurate for English.

| Model            | Speed    | Accuracy | VRAM   |
| ---------------- | -------- | -------- | ------ |
| `tiny.en`        | Fastest  | Lower    | ~1 GB  |
| `base.en`        | Fast     | Good     | ~1 GB  |
| `small.en`       | Moderate | Better   | ~2 GB  |
| `medium.en`      | Slow     | High     | ~5 GB  |
| `large-v3`       | Slowest  | Highest  | ~10 GB |
| `large-v3-turbo` | Moderate | Highest  | ~6 GB  |

## Hardware Acceleration

By default voxtype runs whisper.cpp on the CPU. On a machine with a capable
GPU, set `acceleration` to offload inference and run larger models comfortably:

```nix
{
  hyprflake.desktop.voxtype = {
    enable = true;
    acceleration = "vulkan"; # or "rocm" / "cuda"
    model = "large-v3-turbo";
  };
}
```

`acceleration` picks the matching variant from voxtype's flake, so consumers no
longer need to reach into the transitive input by hand. Pick by GPU:

| GPU                       | Recommended `acceleration` | Notes                                                            |
| ------------------------- | -------------------------- | ---------------------------------------------------------------- |
| AMD (RDNA/RDNA2/RDNA3)    | `vulkan`                   | Works out of the box; no ROCm runtime needed.                    |
| AMD (ROCm-supported card) | `rocm`                     | Only if you already run ROCm; Vulkan is the simpler default.     |
| Intel Arc / Xe (iGPU)     | `vulkan`                   | Needs voxtype >= 0.7.3 (fixes a Vulkan SIGILL on Intel CPUs).    |
| NVIDIA                    | `vulkan`                   | voxtype ships no whisper.cpp CUDA build; Vulkan runs on NVIDIA.  |

The GPU variants are Linux-only. On a laptop, weigh battery and thermals: a GPU
build with `small.en` is often a better trade than a CPU build straining under
`medium.en`. `package` still takes precedence if you set it explicitly (for a
Parakeet or ONNX build the enum doesn't cover).

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

## Compositor Integration

Push-to-talk reads the keyboard via evdev directly, so voxtype needs no Hyprland keybinding or submap wiring. If you use hyprflake's DankMaterialShell bar, its `privacyIndicator` widget shows recording feedback whenever the microphone is live.

## Common Hotkey Choices

- `SCROLLLOCK` (default) - dedicated key, rarely used otherwise
- `F13`-`F24` - available on programmable keyboards
- `INSERT` - convenient on full-size keyboards
- `PAUSE` - another rarely-used dedicated key

Use `evtest` to discover the exact evdev key name for your keyboard.
