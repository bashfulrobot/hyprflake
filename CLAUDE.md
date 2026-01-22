# Hyprflake - Reusable Hyprland Flake

A modular NixOS flake for Hyprland with theming, GPU optimization, and essential integrations.

## Project Structure

```
hyprflake/
├── flake.nix              # Main flake with inputs & helper functions
├── modules/
│   ├── default.nix        # Module aggregator
│   ├── options.nix        # Configuration options
│   ├── desktop/           # Hyprland, waybar, rofi, notifications, etc.
│   ├── home/              # GTK, kitty terminal
│   └── system/            # Keyring, plymouth, power management, user
└── extras/
    ├── docs/              # Detailed documentation (see below)
    └── decisions/         # Architectural decisions
```

## Key Features

- **Unified theming** - Configure once, applied everywhere (Stylix integration)
- **GPU support** - AMD, NVIDIA, Intel with specific optimizations
- **Complete DE** - Hyprland, waybar, rofi, notifications, lock screen
- **Power management** - Idle timeouts, power profiles, sleep control
- **XDG autostart** - Automatic `.desktop` file execution via dex
- **Shortcuts viewer** - Dynamic keybinding discovery (Super+/)

## Quick Start

```nix
programs.hyprflake = {
  enable = true;
  withUWSM = true;
  nvidia = true;  # or amd/intel
  theme = {
    gtkTheme = "Adwaita-dark";
    iconTheme = "Papirus";
    cursorTheme = "Adwaita";
    cursorSize = 24;
  };
};

programs.hyprflake-dconf.enable = true;
services.hyprflake-display.enable = true;
services.hyprflake-keyring.enable = true;
```

## Development Commands

```bash
statix check .      # Check Nix syntax
nixpkgs-fmt .       # Format Nix code
nix flake check     # Test flake evaluation
nix develop         # Build development environment
```

## Detailed Documentation

For in-depth configuration options, read these files:

- `extras/docs/power-management.md` - Idle, sleep, power profiles, TLP, thermald
- `extras/docs/theming.md` - Stylix, GTK, theme propagation, plymouth
- `extras/docs/gpu-configuration.md` - AMD, NVIDIA, Intel setup and troubleshooting
- `extras/docs/consuming-flake.md` - Input follows, helper functions, integration
- `extras/docs/technical-notes.md` - Waybar auto-hide, hyprshell, shortcuts viewer

## Upstream Documentation

- [Stylix Documentation](https://nix-community.github.io/stylix/configuration.html)
- [NixOS Hyprland Wiki](https://wiki.nixos.org/wiki/Hyprland)
- [Hyprland NixOS Wiki](https://wiki.hypr.land/Nix/Hyprland-on-NixOS/)

---

## Maintaining This Documentation

This CLAUDE.md uses a modular documentation pattern to reduce token consumption while keeping detailed information accessible.

### When to Add to CLAUDE.md Directly

Add content here when it is:

- **Essential context** needed for most tasks (project structure, quick start)
- **Brief** - fits in a few lines without detailed examples
- **Frequently referenced** - used in majority of conversations

### When to Create a Separate Doc in `extras/docs/`

Create a new file when the content is:

- **Detailed reference material** - comprehensive options, many examples
- **Topic-specific** - only relevant when working on that specific area
- **Long-form** - more than ~20-30 lines of content

### How to Add a New Documentation File

1. Create the file in `extras/docs/` with a descriptive name (e.g., `wallpaper-management.md`)
2. Add a brief link in the "Detailed Documentation" section above
3. Use clear headings and code examples in the new file

### Documentation File Template

```markdown
# Topic Name Reference

Brief description of what this document covers.

## Section 1

Content with code examples:

\`\`\`nix
# Example configuration
\`\`\`

## Section 2

More details...
```

### Guidelines

- Keep CLAUDE.md under ~100 lines of actual content
- Each `extras/docs/` file should be self-contained
- Use descriptive link text so the LLM knows when to consult each doc
- Prefer showing "what" in CLAUDE.md, detailed "how" in extras/docs/
