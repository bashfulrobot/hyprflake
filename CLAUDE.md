# Hyprflake - Reusable Hyprland Flake

A modular and reusable NixOS flake for Hyprland desktop environment with comprehensive theming, GPU optimization, and essential integrations.

## Project Structure

```
hyprflake/
├── flake.nix                           # Main flake with inputs & helper functions
└── modules/
    ├── nixos/
    │   ├── hyprland.nix                # Core Hyprland system config with GPU options
    │   ├── cachix.nix                  # Hyprland binary cache configuration
    │   ├── stylix.nix                  # Stylix theming integration
    │   ├── dconf.nix                   # dconf with theme settings
    │   ├── xdg.nix                     # XDG configuration
    │   ├── display-manager.nix         # Login/display manager configuration
    │   ├── plymouth.nix                # Plymouth boot splash with wallpaper
    │   └── keyring.nix                 # Keyring/credential management
    └── home-manager/
        ├── hyprland.nix                # Hyprland window manager config
        ├── stylix.nix                  # Home Manager stylix theming
        ├── dconf.nix                   # Home Manager dconf theme settings
        └── xdg.nix                     # XDG user directories & MIME

```

## Key Features

### 🎨 Unified Theming System

- Theme options configurable once, applied everywhere
- GTK, icon, and cursor themes with dconf integration
- Stylix integration for system-wide theming
- Consistent theming across NixOS and Home Manager
- Plymouth boot splash using the same wallpaper as Hyprland

### 🖥️ GPU Optimization

- Boolean flags for AMD, NVIDIA, and Intel GPUs
- GPU-specific drivers and environment variables
- NVIDIA Wayland optimizations included

### 📦 Complete Desktop Environment

- Hyprland with sensible defaults and UWSM support
- XDG portals configured correctly
- Audio via PipeWire
- Display manager (gdm)
- Essential Wayland utilities included

### 🚀 Easy Integration

Helper functions for other flakes:

- `mkHyprlandSystem` - Complete NixOS system
- `mkHyprlandHome` - Home Manager configuration

## Usage Examples

### NixOS System Configuration

```nix
programs.hyprflake = {
  enable = true;
  withUWSM = true;  # Recommended for NixOS 24.11+
  nvidia = true;  # or amd = true; intel = true;
  theme = {
    gtkTheme = "Adwaita-dark";
    iconTheme = "Papirus";
    cursorTheme = "Adwaita";
    cursorSize = 24;
  };
};

services.hyprflake-cachix.enable = true;
programs.hyprflake-dconf.enable = true;
services.hyprflake-display = {
  enable = true;
  autoLogin = "myuser";  # Optional auto-login
};
services.hyprflake-keyring.enable = true;

# Optional: Enable Plymouth boot splash with Hyprland wallpaper
hyprflake.plymouth.enable = true;
```

### Home Manager Configuration

```nix
wayland.windowManager.hyprflake = {
  enable = true;
  theme = {
    gtkTheme = "Adwaita-dark";
    iconTheme = "Papirus";
    cursorTheme = "Adwaita";
    cursorSize = 24;
  };
};

dconf.hyprflake.enable = true;
services.hyprflake-keyring-hm.enable = true;
```

### Using Helper Functions

```nix
# In another flake
inputs.hyprflake.lib.mkHyprlandSystem {
  extraModules = [
    ./hardware-configuration.nix
    { networking.hostName = "my-system"; }
  ];
}
```

## Development Status

### ✅ Completed

- [x] Basic flake structure with all inputs
- [x] Modular NixOS and Home Manager configurations
- [x] GPU-specific optimizations (AMD/NVIDIA/Intel)
- [x] Theme system with dconf integration
- [x] Cachix integration for faster builds
- [x] XDG portals and desktop integration
- [x] Essential Wayland packages and services
- [x] Helper functions for easy consumption
- [x] Plymouth boot splash with wallpaper integration

### 🔄 Next Steps

- [ ] Add more theme packages (GTK themes, icon themes)
- [ ] Waybar configuration with theming integration
- [ ] Hyprpaper/wallpaper management
- [ ] Application-specific theming (kitty, rofi, etc.)
- [ ] Example configurations and documentation
- [ ] Testing framework for different GPU configurations

## Technical Notes

### Theme Propagation Flow

1. User sets theme options in either NixOS or Home Manager module
2. NixOS dconf module applies themes via `programs.dconf.profiles.user.databases`
3. Home Manager dconf module applies via `dconf.settings`
4. Home Manager GTK module configures themes directly
5. Stylix can override with system-wide theming
6. Wallpaper is shared between Hyprland, Stylix, and Plymouth for consistency

### GPU Configuration Logic

- Uses boolean flags instead of enum for flexibility
- Each GPU type has specific driver and environment variable configuration
- NVIDIA includes Wayland-specific workarounds and optimizations
- AMD enables initrd support for early KMS
- Intel enables GPU tools for debugging

### Module Dependencies

- All modules are optional with enable flags
- NixOS hyprland module enables core Hyprland functionality
- Other modules extend with specific features (caching, theming, etc.)
- Helper functions automatically include all necessary modules

## Commands for Development

```bash
# Check Nix syntax
statix check .

# Format Nix code
nixpkgs-fmt .

# Test flake evaluation
nix flake check

# Build development environment
nix develop
```

## Integration Points

This flake is designed to be consumed by other flakes that need Hyprland. It provides:

- Complete system-level configuration via NixOS modules
- User-level configuration via Home Manager modules
- Helper functions for common use cases
- Flexible theming that works with or without Stylix
- GPU optimization for different hardware configurations

The modular design allows consumers to pick and choose which features they need while maintaining consistency and avoiding duplication.

## Development Resources

### Project Organization

- Project documentation is in `extras/docs/`.
- Architectural decisions are in `extras/decisions/`.

### Upstream Documentation

- [Stylix Documentation](https://nix-community.github.io/stylix/configuration.html)
- [NixOS Hyprland Wiki](https://wiki.nixos.org/wiki/Hyprland)
- [Hyprland NixOS Wiki](https://wiki.hypr.land/Nix/Hyprland-on-NixOS/)