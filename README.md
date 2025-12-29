# Hyprflake

Batteries-included Hyprland desktop for NixOS. Add one module, get complete desktop.

## What's Included

- **Hyprland** - Wayland compositor
- **Cachix** - Hyprland binary cache (no source builds)
- **Stylix** - System-wide theming
- **Waybar** - Status bar with auto-hide (enabled by default)
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

    hyprland = {
      url = "github:hyprwm/Hyprland";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprshell = {
      url = "github:H3rmt/hyprshell?ref=hyprshell-release";
      inputs.hyprland.follows = "hyprland";
    };

    waybar-auto-hide = {
      url = "github:bashfulrobot/nixpkg-waybar-auto-hide";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprflake = {
      url = "github:bashfulrobot/hyprflake";
      # IMPORTANT: Follow all inputs to ensure version consistency
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
        stylix.follows = "stylix";
        hyprland.follows = "hyprland";
        hyprshell.follows = "hyprshell";
        waybar-auto-hide.follows = "waybar-auto-hide";
      };
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

The `follows` mechanism ensures your flake's `flake.lock` becomes the single source of truth for all dependency versions.

**Without follows:**
- Multiple versions of the same dependency (wasted disk space)
- hyprflake's `flake.lock` controls versions you can't update independently
- Potential version conflicts between dependencies
- Larger closure size from duplicate packages

**With follows (recommended pattern above):**
- ✅ **Single source of truth:** Your `flake.lock` controls all versions
- ✅ **Independent updates:** `nix flake update hyprland` updates just Hyprland
- ✅ **Smaller closure:** No duplicate dependencies across the tree
- ✅ **Version control:** Pin specific versions when needed
- ✅ **Compatibility:** You control when dependencies update together

**What gets controlled:**
- `nixpkgs`: Ensures all packages come from same nixpkgs version
- `home-manager`: Must match your nixpkgs version
- `stylix`: Must match your nixpkgs version
- `hyprland`: You control Hyprland version independently from hyprflake
- `hyprshell`: You control version and ensure it uses your Hyprland
- `waybar-auto-hide`: You control version

**What you DON'T need to control:**
- Hyprland's internal dependencies (aquamarine, hyprcursor, etc.)
- These are tested together by upstream and should not be overridden
- Let upstream flakes manage their own deep dependencies

This pattern is recommended by the [Nix community](https://discourse.nixos.org/t/recommendations-for-use-of-flakes-input-follows/17413) and documented in the [official Nix manual](https://nix.dev/manual/nix/2.28/command-ref/new-cli/nix3-flake.html#flake-inputs)

For a complete visual explanation with dependency diagrams, see [`docs/input-management.md`](docs/input-management.md).

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

  # Disable Waybar auto-hide
  hyprflake.waybar-auto-hide.enable = false;

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

### Waybar Auto-Hide

Waybar automatically hides when the workspace is empty and shows when you move your cursor to the top edge. This feature is **enabled by default**.

**To disable:**
```nix
hyprflake.waybar-auto-hide.enable = false;
```

**How it works:**
- Monitors workspace state via Hyprland IPC
- Hides Waybar when no windows exist in the current workspace
- Reveals Waybar when cursor approaches the top screen edge
- No configuration needed - works automatically with Waybar IPC

## Structure

```
hyprflake/
├── modules/
│   ├── desktop/
│   │   ├── display-manager/  # GDM
│   │   ├── hyprland/         # Window manager
│   │   ├── rofi/             # Launcher
│   │   ├── stylix/           # Theming
│   │   ├── waybar/           # Status bar
│   │   └── waybar-auto-hide/ # Waybar auto-hide utility
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
