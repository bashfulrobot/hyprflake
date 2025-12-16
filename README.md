# Hyprflake

Batteries-included Hyprland desktop for NixOS. Add one module, get complete desktop.

## What's Included

- **Hyprland** - Wayland compositor
- **Cachix** - Hyprland binary cache (no source builds)
- **Stylix** - System-wide theming
- **PipeWire** - Audio stack
- **GDM** - Login manager
- **Fonts** - Curated collection
- **Keyring** - Secret management with auto-unlock
- **XDG** - Portal support

### SSH Key Auto-Discovery

The keyring module automatically discovers and loads all SSH keys on login:

- **Auto-detects:** `id_rsa`, `id_ed25519`, `id_ecdsa`, `work_id_ed25519`, etc.
- **Pattern matching:** `~/.ssh/id_*` and `~/.ssh/*_id_*`
- **No hardcoding:** Works with any key naming convention
- **Secure storage:** Passphrases saved in GNOME Keyring after first use

See [`docs/keyring.md`](docs/keyring.md) for complete configuration details.

## Installation

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprflake = {
      url = "github:bashfulrobot/hyprflake";
      # IMPORTANT: Follow all inputs to avoid version conflicts
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.stylix.follows = "stylix";
    };
  };

  outputs = { nixpkgs, hyprflake, ... }: {
    nixosConfigurations.myhost = nixpkgs.lib.nixosSystem {
      modules = [
        ./configuration.nix
        hyprflake.nixosModules.default
      ];
    };
  };
}
```

### Why Follow All Inputs?

**Without follows:**
- Multiple nixpkgs versions (wasted disk space)
- Stylix version mismatch warnings
- Potential build failures

**With follows:**
- Single nixpkgs version
- No conflicts
- Smaller Nix store

Pattern recommended by [Nix community](https://discourse.nixos.org/t/recommendations-for-use-of-flakes-input-follows/17413).

### Controlling Hyprland Version (Recommended)

By default, hyprflake's Hyprland version is locked in its own flake.lock. To control which Hyprland version you use and update it independently:

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Add Hyprland as a direct input
    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprflake = {
      url = "github:bashfulrobot/hyprflake";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.home-manager.follows = "home-manager";
      inputs.stylix.follows = "stylix";
      inputs.hyprland.follows = "hyprland";  # Use your Hyprland version
    };
  };
}
```

**Benefits:**
- ✅ Update Hyprland with `nix flake update hyprland`
- ✅ Pin to specific Hyprland versions independently
- ✅ Not dependent on hyprflake maintainer to update Hyprland
- ✅ Simpler dependency tree (fewer duplicate sub-dependencies)

**Without this pattern:**
- ❌ Hyprland version locked in hyprflake's flake.lock
- ❌ Must wait for hyprflake maintainer to update
- ❌ Cannot update Hyprland independently

## Configuration

### Basic Options

```nix
# configuration.nix
{
  # Color scheme (Base16)
  hyprflake.colorScheme = "catppuccin-mocha";  # default

  # Browse schemes: https://tinted-theming.github.io/base16-gallery/
  # Popular: gruvbox-dark-hard, nord, dracula, tokyo-night-dark

  # Wallpaper (local file)
  hyprflake.wallpaper = ./wallpaper.png;

  # Or remote URL
  hyprflake.wallpaper = {
    url = "https://example.com/wallpaper.png";
    sha256 = "sha256-...";  # nix-prefetch-url <url>
  };

  # Cursor
  hyprflake.cursor = {
    name = "Adwaita";
    size = 24;
    package = pkgs.adwaita-icon-theme;
  };

  # Keyboard layout
  hyprflake.keyboard = {
    layout = "us";
    variant = "";  # colemak, dvorak, etc.
  };

  # Opacity
  hyprflake.opacity = {
    terminal = 0.9;
    desktop = 1.0;
    popups = 0.95;
    applications = 1.0;
  };

  # User (required)
  hyprflake.user = {
    username = "myuser";
    photo = ./.face;  # Optional profile picture
  };
}
```

### Advanced

Override any standard NixOS/Stylix option:

```nix
{
  # Disable binary cache (build from source)
  hyprflake.cachix.enable = false;

  # Custom fonts
  hyprflake.fonts = {
    monospace = {
      name = "JetBrains Mono";
      package = pkgs.jetbrains-mono;
    };
  };

  # Override Stylix directly
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";

  # Disable components
  services.pipewire.enable = lib.mkForce false;
}
```

## Structure

```
hyprflake/
├── modules/
│   ├── desktop/
│   │   ├── display-manager/  # GDM
│   │   ├── hyprland/         # Window manager
│   │   ├── rofi/             # Launcher
│   │   ├── stylix/           # Theming
│   │   └── waybar/           # Status bar
│   └── system/
│       ├── audio/            # PipeWire
│       ├── cachix/           # Binary cache
│       ├── fonts/            # Font packages
│       ├── graphics/         # OpenGL/Vulkan
│       ├── keyring/          # GNOME Keyring
│       └── xdg/              # Portals
└── flake.nix
```

## Philosophy

- Sensible defaults
- Configurable via `hyprflake.*` options
- Override anything via standard NixOS options
- Stylix for consistent theming

## Requirements

- NixOS with flakes enabled
- Home Manager (included as dependency)

## License

MIT
