# Hyprflake - Reusable Hyprland Flake

A modular and reusable NixOS flake for Hyprland desktop environment with comprehensive theming, GPU optimization, and essential integrations.

## Project Structure

```
hyprflake/
├── flake.nix                           # Main flake with inputs & helper functions
└── modules/
    ├── default.nix                     # Module aggregator
    ├── options.nix                     # Hyprflake configuration options
    ├── desktop/
    │   ├── display-manager/            # GDM login manager
    │   ├── hyprland/                   # Hyprland window manager config
    │   ├── hypridle/                   # Idle management
    │   ├── hyprlock/                   # Lock screen
    │   ├── rofi/                       # Application launcher
    │   ├── stylix/                     # Stylix theming integration
    │   ├── swaync/                     # Notification daemon
    │   ├── swayosd/                    # On-screen display (volume, brightness)
    │   ├── themes/                     # GTK/icon/cursor themes
    │   ├── waybar/                     # Status bar
    │   ├── waybar-auto-hide/           # Waybar auto-hide utility
    │   └── wlogout/                    # Logout menu
    ├── home/
    │   ├── gtk/                        # GTK theme configuration
    │   └── kitty/                      # Terminal emulator
    └── system/
        ├── keyring/                    # GNOME Keyring with SSH auto-discovery
        ├── plymouth/                   # Plymouth boot splash
        ├── services/
        │   └── cachix.nix              # Hyprland binary cache
        └── user/                       # User account management

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
- Waybar status bar with auto-hide (enabled by default)
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

# Optional: Enable Plymouth boot splash (auto-matches colorScheme)
# Uses Catppuccin Plymouth theme if colorScheme is catppuccin-*,
# otherwise falls back to Circle HUD theme
hyprflake.plymouth.enable = true;

# Optional: Disable Waybar auto-hide (enabled by default)
hyprflake.waybar-auto-hide.enable = false;
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
- [x] Waybar configuration with theming integration
- [x] Waybar auto-hide utility (enabled by default)
- [x] Application-specific theming (kitty, rofi, swaync, swayosd, wlogout)

### 🔄 Next Steps

- [ ] Add more theme packages (GTK themes, icon themes)
- [ ] Hyprpaper/wallpaper management
- [ ] Example configurations and documentation
- [ ] Testing framework for different GPU configurations

## Technical Notes

### Waybar Auto-Hide

The waybar-auto-hide utility provides automatic Waybar visibility management:

1. **Integration**: Enabled by default via `hyprflake.waybar-auto-hide.enable = true`
2. **Functionality**:
   - Monitors workspace state through Hyprland IPC
   - Automatically hides Waybar when workspace is empty
   - Reveals Waybar when cursor approaches top screen edge
3. **Requirements**:
   - Waybar IPC enabled (configured automatically in waybar module)
   - Launched via Hyprland `exec-once` (handled by module)
4. **Source**: [bashfulrobot/nixpkg-waybar-auto-hide](https://github.com/bashfulrobot/nixpkg-waybar-auto-hide)

### Theme Propagation Flow

1. User sets `hyprflake.colorScheme` (e.g., "catppuccin-mocha")
2. Stylix applies the base16 color scheme system-wide
3. Plymouth auto-detects and matches the color scheme
   - Catppuccin variants use catppuccin-plymouth
   - Other schemes fall back to Circle HUD theme
4. NixOS dconf module applies themes via `programs.dconf.profiles.user.databases`
5. Home Manager dconf module applies via `dconf.settings`
6. Home Manager GTK module configures themes directly
7. Wallpaper is shared between Hyprland and Stylix

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