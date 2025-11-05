# Hyprflake

Opinionated, batteries-included Hyprland desktop environment for NixOS. Designed to be consumed by other flakes.

## What's Included

- **Hyprland** - Dynamic tiling Wayland compositor
- **Stylix** - System-wide theming (colors, fonts, wallpaper)
- **Audio** - PipeWire with ALSA and PulseAudio compatibility
- **Graphics** - OpenGL/Vulkan with 32-bit support
- **Fonts** - Curated font collection
- **Keyring** - GNOME Keyring for secret management
- **XDG** - Proper directory structure

## Quick Start

Add hyprflake to your flake inputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    hyprflake = {
      url = "github:bashfulrobot/hyprflake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, hyprflake, ... }:
    {
      nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
        modules = [
          ./configuration.nix
          hyprflake.nixosModules.default
        ];
      };
    };
}
```

That's it! Hyprland desktop is now configured.

## Customization

### Color Schemes

Hyprflake uses **Base16** color schemes via Stylix for consistent theming across all applications.

#### Setting a Color Scheme

```nix
# configuration.nix
{
  hyprflake.colorScheme = "gruvbox-dark-hard";
}
```

#### Finding Available Schemes

**Option 1: Browse the gallery**
Visit the [Base16 Gallery](https://tinted-theming.github.io/base16-gallery/) to preview all available schemes.

**Option 2: List schemes on your system**
```bash
ls $(nix-build --no-out-link '<nixpkgs>' -A base16-schemes)/share/themes/
```

**Popular schemes:**
- **Catppuccin**: `catppuccin-mocha`, `catppuccin-latte`, `catppuccin-frappe`, `catppuccin-macchiato`
- **Gruvbox**: `gruvbox-dark-hard`, `gruvbox-dark-medium`, `gruvbox-dark-soft`, `gruvbox-light-hard`
- **Nord**: `nord`
- **Dracula**: `dracula`
- **Tokyo Night**: `tokyo-night-dark`, `tokyo-night-storm`, `tokyo-night-light`
- **Solarized**: `solarized-dark`, `solarized-light`
- **Material**: `material-darker`, `material-palenight`, `material-ocean`
- **One**: `one-dark`, `onedark`

Use the filename without the `.yaml` extension.

### Hyprflake Options

Configure hyprflake-specific settings:

```nix
# configuration.nix
{
  # Color scheme (Base16)
  hyprflake.colorScheme = "nord";

  # Wallpaper (remote URL)
  hyprflake.wallpaper = {
    url = "https://example.com/my-wallpaper.png";
    sha256 = "sha256-...";  # Get with: nix-prefetch-url <url>
  };
}
```

**For local wallpapers**, set `stylix.image` directly (no hash needed):

```nix
{
  # Local wallpaper (bypasses hyprflake.wallpaper)
  stylix.image = ./path/to/wallpaper.png;
}
```

### Standard NixOS Options

All components use standard NixOS/Home Manager options. Override anything:

```nix
# configuration.nix
{
  # Override Stylix theme
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

  # Alternative: Set wallpaper directly via Stylix (local file)
  stylix.image = ./my-wallpaper.png;

  # Disable a component
  services.pipewire.enable = lib.mkForce false;

  # Add packages
  environment.systemPackages = [ pkgs.myapp ];
}
```

## Structure

```
hyprflake/
├── settings/
│   └── default.nix          # Theme defaults (DRY)
├── modules/
│   ├── default.nix          # Main module import
│   ├── desktop/
│   │   ├── hyprland/        # Hyprland configuration
│   │   └── stylix/          # Theme application
│   └── system/
│       ├── audio/           # PipeWire setup
│       ├── fonts/           # Font collection
│       ├── graphics/        # OpenGL/Vulkan
│       ├── keyring/         # Secret management
│       └── xdg/             # Directory structure
└── flake.nix               # Main flake
```

## Philosophy

**Opinionated, not configurable:**
- Sensible defaults out of the box
- No custom enable options
- Use standard NixOS options to customize
- DRY - settings as data

**Consumable:**
- Import one module, get complete desktop
- Works with any NixOS flake
- Follows nixpkgs input for compatibility

## Requirements

- NixOS with flakes enabled
- Home Manager (brought in as dependency)

## License

MIT