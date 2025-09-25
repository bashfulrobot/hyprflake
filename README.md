# Hyprflake

> ⚠️ **WORK IN PROGRESS** - This flake is under heavy development and not ready for production use. APIs may change frequently.

A reusable NixOS flake for Hyprland desktop environment with theming, GPU optimization, and essential integrations.

## Quick Start

Add to your flake inputs:

```nix
inputs.hyprflake.url = "github:yourusername/hyprflake";
```

### NixOS Configuration

```nix
programs.hyprflake = {
  enable = true;
  nvidia = true; # or amd = true; intel = true;
};

services.hyprflake-cachix.enable = true;
```

### Home Manager Configuration

```nix
wayland.windowManager.hyprflake.enable = true;
```

## Theming

Set themes once, applied everywhere:

```nix
programs.hyprflake.theme = {
  gtkTheme = "Adwaita-dark";
  iconTheme = "Papirus";
  cursorTheme = "Adwaita";
  cursorSize = 24;
};
```

## Features

- 🎨 Unified theming (GTK, icons, cursors)
- 🖥️ GPU optimizations (AMD/NVIDIA/Intel)
- 📦 Complete Hyprland desktop environment
- 🚀 Helper functions for easy integration
- ⚡ Cachix support for faster builds

---

**🚧 Development Status**: This project is in active development. Expect breaking changes and incomplete features. Use at your own risk.

## License

MIT