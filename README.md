# Hyprflake

Batteries-included Hyprland desktop for NixOS. Add one module, get complete desktop.

## What's Included

- **Hyprland** - Wayland compositor (from nixpkgs - stable, tested releases)
- **DankMaterialShell (DMS)** - The desktop shell: status bar, app launcher,
  notifications, on-screen display, power menu, lock screen, and idle daemon in
  a single process. Always enabled — hyprflake's core shell.
- **Stylix** - System-wide theming
- **PipeWire** - Audio stack
- **GDM** - Login manager
- **Fonts** - Curated collection (Apple SF family via apple-fonts)
- **Keyring** - Secret management with auto-unlock
- **XDG** - Portal support

hyprflake is **DMS-first**: DankMaterialShell provides the shell, and new
desktop-shell features prefer DMS's built-in capability over standalone tools.
The previous Waybar-based stack (waybar, swaync, swayosd, rofi, rofimoji,
wlogout, hyprshell, hyprlock, hypridle) has been retired in favor of DMS.

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

- `nixpkgs`: Ensures all packages come from same nixpkgs version (includes Hyprland)
- `home-manager`: Must match your nixpkgs version
- `stylix`: Must match your nixpkgs version
- `waybar-auto-hide`: Simple IPC utility (version independent)

**Hyprland from nixpkgs:**

- hyprflake uses Hyprland from **nixpkgs** (not the upstream flake)
- Versions managed by nixpkgs maintainers - stable, tested releases
- No binary cache configuration needed (nixpkgs is cached by default)
- Update with `nix flake update nixpkgs` like any other package

This pattern is recommended by the [Nix community](https://discourse.nixos.org/t/recommendations-for-use-of-flakes-input-follows/17413) and documented in the [official Nix manual](https://nix.dev/manual/nix/2.28/command-ref/new-cli/nix3-flake.html#flake-inputs)

For a complete visual explanation with dependency diagrams, see [`docs/input-management.md`](docs/input-management.md).

## Configuration

### Quick Start

Minimal configuration using defaults (all options are optional with sensible defaults):

```nix
# configuration.nix
{
  # Optional but recommended: set username for user-specific configurations
  hyprflake.user = {
    username = "myuser";
    photo = ./.face;  # Optional profile picture (requires username)
  };
}
```

**Note:** While hyprflake works without any configuration, setting `user.username` is recommended for proper user-specific features like profile photos and display manager integration.

### Customizing Options

Override specific options while keeping other defaults:

```nix
# configuration.nix
{
  hyprflake = {
    # Style configuration
    style = {
      colorScheme = "gruvbox-dark-hard";
      wallpaper = ./wallpaper.png;

      # Custom fonts
      fonts.monospace = {
        name = "JetBrains Mono";
        package = pkgs.jetbrains-mono;
      };

      # Cursor
      cursor = {
        name = "Adwaita";
        size = 32;
        package = pkgs.adwaita-icon-theme;
      };

      # Opacity
      opacity.terminal = 0.85;
    };

    # Desktop configuration
    desktop = {
      keyboard = {
        layout = "us,de";
        variant = "colemak";
      };

      # Idle ladder (lock / DPMS / suspend timeouts), consumed by DMS
      idle.lockTimeout = 600;
    };

    # System configuration
    system = {
      plymouth.enable = true;
    };

    # User (required)
    user = {
      username = "myuser";
      photo = ./.face;
    };
  };
}
```

### Complete Options Reference

For a complete list of all available options with descriptions and defaults, see [`docs/options.md`](docs/options.md).

Browse color schemes: https://tinted-theming.github.io/base16-gallery/

### Advanced Overrides

Override any standard NixOS/Stylix option:

```nix
{
  # Override Stylix directly
  stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord.yaml";

  # Disable components
  services.pipewire.enable = lib.mkForce false;
}
```

### The Desktop Shell (DankMaterialShell)

The status bar, launcher, notifications, OSD, power menu, lock screen, and idle
daemon are all provided by [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell)
(DMS), which runs as a single systemd user service (`dms.service`). It is always
enabled — there is no toggle, because hyprflake supports one shell.

Bar layout and shell appearance are configured **declaratively** via
`programs.dank-material-shell.settings` in the dank module, and themed by Stylix
(the `dank-material-shell` target feeds it colors, fonts, opacity, and the
wallpaper). DMS's own in-app settings GUI cannot persist, because its
`settings.json` is a read-only symlink into the Nix store — the declarative
block is the single source of truth. See [`docs/styling.md`](docs/styling.md)
for the full breakdown of what Stylix owns versus what is tunable.

> **Migrating from the old Waybar stack?** Options like
> `hyprflake.desktop.waybar.*`, `desktop.swaync.enable`, `desktop.rofi.enable`,
> etc. still evaluate as no-op deprecation stubs (each emits a warning) so old
> configs keep building, but they render nothing — DMS provides these now.

### Screen Sharing

hyprflake automatically fixes the double-prompt issue when screen sharing in Chromium browsers (Chrome, Brave, Edge). No configuration needed - it works out of the box.

See [`docs/screensharing.md`](docs/screensharing.md) for technical details.

## Structure

```
hyprflake/
├── flake.nix
├── lib/
│   ├── stylix-helpers.nix    # mkStyle CSS substitution helper
│   └── systemd-helpers.nix   # mkGraphicalUserService systemd unit helper
├── modules/
│   ├── default.nix
│   ├── desktop/
│   │   ├── autostart/         # XDG autostart via dex
│   │   ├── dank/              # DankMaterialShell — the core shell (bar,
│   │   │                      #   launcher, notifications, OSD, power menu,
│   │   │                      #   lock, idle); always enabled, no toggle
│   │   ├── display-manager/   # GDM (Wayland session)
│   │   ├── gtk/               # GTK theming (icons via Stylix)
│   │   ├── hyprland/          # Compositor + keybinds (dispatch to dms ipc)
│   │   ├── kitty/             # Terminal
│   │   ├── shortcuts-viewer/  # hyprctl binds -> themed HTML cheat sheet
│   │   ├── stylix/            # Theming entry point (+ DMS Stylix target)
│   │   ├── system-actions/    # Lock / Reboot / Shutdown .desktop entries
│   │   ├── themes/            # Theme-engine packages
│   │   ├── voxtype/           # Push-to-talk Whisper transcription
│   │   ├── waybar/            # Deprecated stub (kept options only)
│   │   ├── waybar-auto-hide/  # Deprecated stub (kept options only)
│   │   ├── wl-clip-persist/   # Clipboard watcher daemons
│   │   └── deprecated-stubs.nix  # No-op stubs for swaync, swayosd, rofi,
│   │                          #   rofimoji, wlogout, hyprshell, hyprlock,
│   │                          #   hypridle — all now provided by DMS
│   └── system/
│       ├── hyprctl-compat/    # Legacy `hyprctl dispatch` shim for Lua backend
│       ├── keyring/           # GNOME Keyring + SSH agent
│       ├── plymouth/          # Boot splash
│       ├── power/             # PPD / TLP / thermald / sleep / logind
│       └── user/              # AccountsService user photo
├── docs/                      # User-facing docs (architecture, options, styling, ...)
├── wallpapers/
└── justfile                   # Local dev recipes
```

## Philosophy

- Sensible defaults
- Configurable via `hyprflake.*` options
- Override anything via standard NixOS options
- Stylix for consistent theming
- **DMS-first** — DankMaterialShell is the shell; new desktop-shell features
  prefer DMS's built-in capability over bolting on a standalone tool

## Requirements

- NixOS with flakes enabled
- Home Manager (included as dependency)

## License

MIT
