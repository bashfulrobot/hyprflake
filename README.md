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

  # Fonts - customize any or all font types
  hyprflake.fonts = {
    monospace = {
      name = "Fira Code";
      package = pkgs.fira-code;
    };
    sansSerif = {
      name = "Roboto";
      package = pkgs.roboto;
    };
    serif = {
      name = "Liberation Serif";
      package = pkgs.liberation_ttf;
    };
    emoji = {
      name = "Twitter Color Emoji";
      package = pkgs.twitter-color-emoji;
    };
  };

  # Cursor theme
  hyprflake.cursor = {
    name = "Bibata-Modern-Ice";
    size = 32;
    package = pkgs.bibata-cursors;
  };
}
```

**Font Types:**
- **monospace**: Used for terminals, code editors, and fixed-width text
- **sansSerif**: Used for UI elements, labels, and body text
- **serif**: Used for document reading and formal text
- **emoji**: Used for color emoji rendering

**Popular Font Combinations:**

**Developer Setup:**
```nix
hyprflake.fonts.monospace = {
  name = "JetBrains Mono";
  package = pkgs.jetbrains-mono;
};
hyprflake.fonts.sansSerif = {
  name = "Inter";
  package = pkgs.inter;
};
```

**Classic Look:**
```nix
hyprflake.fonts.monospace = {
  name = "Courier New";
  package = pkgs.corefonts;
};
hyprflake.fonts.sansSerif = {
  name = "Arial";
  package = pkgs.corefonts;
};
```

**Modern Minimal:**
```nix
hyprflake.fonts.monospace = {
  name = "Source Code Pro";
  package = pkgs.source-code-pro;
};
hyprflake.fonts.sansSerif = {
  name = "Source Sans 3";
  package = pkgs.source-sans;
};
```

**Popular Cursor Themes:**

**Bibata (Modern & Smooth):**
```nix
hyprflake.cursor = {
  name = "Bibata-Modern-Ice";
  size = 24;
  package = pkgs.bibata-cursors;
};
```

**Catppuccin (Matches Catppuccin color scheme):**
```nix
hyprflake.cursor = {
  name = "catppuccin-mocha-dark-cursors";
  size = 24;
  package = pkgs.catppuccin-cursors.mochaDark;
};
```

**Breeze (KDE Style):**
```nix
hyprflake.cursor = {
  name = "Breeze";
  size = 24;
  package = pkgs.libsForQt5.breeze-icons;
};
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
├── lib/
│   └── stylix-helpers.nix   # Stylix theming helpers
├── modules/
│   ├── default.nix          # Main module import
│   ├── options.nix          # Consumer configuration options (hyprflake.*)
│   ├── desktop/
│   │   ├── display-manager/ # GDM configuration
│   │   ├── hyprland/        # Hyprland window manager
│   │   ├── rofi/            # Application launcher
│   │   ├── stylix/          # System-wide theming
│   │   └── waybar/          # Status bar
│   └── system/
│       ├── audio/           # PipeWire audio
│       ├── cachix/          # Binary cache
│       ├── fonts/           # Font packages
│       ├── graphics/        # OpenGL/Vulkan
│       ├── keyring/         # Credential management
│       └── xdg/             # Directory structure
└── flake.nix               # Main flake
```

## Philosophy

**Opinionated with escape hatches:**
- Sensible defaults out of the box
- Configurable via `hyprflake.*` options
- Override anything via standard NixOS/Stylix options
- Stylix as single source of truth for theming

**Consumable:**
- Import one module, get complete desktop
- Works with any NixOS flake
- Follows nixpkgs input for compatibility

## Requirements

- NixOS with flakes enabled
- Home Manager (brought in as dependency)

## License

MIT