# GPU Configuration Reference

Hyprflake supports AMD, NVIDIA, and Intel GPUs with specific optimizations for each.

## Enabling GPU Support

Use boolean flags in your configuration:

```nix
programs.hyprflake = {
  enable = true;
  amd = true;     # AMD GPU
  # nvidia = true;  # NVIDIA GPU
  # intel = true;   # Intel GPU
};
```

Multiple GPUs can be enabled simultaneously (e.g., Intel + NVIDIA hybrid).

## AMD Configuration

When `amd = true`:

- Enables AMD GPU drivers
- Configures initrd support for early KMS (kernel mode setting)
- Sets AMD-specific environment variables for Wayland

## NVIDIA Configuration

When `nvidia = true`:

- Enables NVIDIA proprietary drivers
- Configures NVIDIA-specific Wayland workarounds
- Sets environment variables for improved Wayland compatibility:
  - `GBM_BACKEND=nvidia-drm`
  - `__GLX_VENDOR_LIBRARY_NAME=nvidia`
  - `LIBVA_DRIVER_NAME=nvidia`
  - `WLR_NO_HARDWARE_CURSORS=1` (if needed)

## Intel Configuration

When `intel = true`:

- Enables Intel GPU drivers
- Includes Intel GPU tools for debugging
- Configures appropriate environment variables

## GPU Configuration Logic

- Uses boolean flags instead of enum for flexibility (supports hybrid setups)
- Each GPU type has specific driver and environment variable configuration
- NVIDIA includes Wayland-specific workarounds and optimizations
- AMD enables initrd support for early KMS
- Intel enables GPU tools for debugging

## Hybrid Graphics

For laptops with hybrid graphics (e.g., Intel + NVIDIA):

```nix
programs.hyprflake = {
  enable = true;
  intel = true;
  nvidia = true;
};
```

The appropriate environment variables and drivers for both GPUs will be configured.

## Troubleshooting

### NVIDIA flickering or tearing

Ensure you have the latest NVIDIA drivers and try:

```nix
hardware.nvidia = {
  modesetting.enable = true;
  powerManagement.enable = true;
};
```

### AMD screen corruption after resume

This may indicate suspend bugs with your GPU. See `extras/docs/power-management.md` for disabling suspend.

### Intel performance issues

Ensure hardware acceleration is enabled:

```nix
hardware.opengl = {
  enable = true;
  driSupport = true;
};
```
