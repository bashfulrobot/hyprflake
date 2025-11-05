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

All components use standard NixOS/Home Manager options. Override anything:

```nix
# configuration.nix
{
  # Override Stylix theme
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark-hard.yaml";

  # Override wallpaper
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