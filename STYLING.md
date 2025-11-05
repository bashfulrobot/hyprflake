# Hyprflake Styling Guide

This document explains how to integrate Stylix theming into hyprflake modules.

## Overview

Hyprflake uses **Stylix** for system-wide theming. All modules should access Stylix values through the **Stylix helper library** for consistency.

## The Stylix Helper Library

Located at `lib/stylix-helpers.nix`, this provides:
- **`mkStyle`** - Helper to import style files with config
- **`fonts`** - Font names, packages, and sizes
- **`colors`** - Direct hex color access (base00-0F)
- **`opacity`** - Opacity values for different contexts
- **`cursor`** - Cursor theme information
- **`wallpaper`** - Configured wallpaper path
- **`gtkColorVars`** - Reference for GTK CSS variables

## Module Pattern

### In `default.nix`:

```nix
{ pkgs, config, lib, ... }:

let
  stylix = import ../../lib/stylix-helpers.nix { inherit lib config; };
in
{
  # Your module configuration

  home-manager.sharedModules = [
    (_: {
      programs.yourProgram = {
        enable = true;

        # Use stylix.mkStyle for CSS/styling
        style = stylix.mkStyle ./style.nix;

        # Or access values directly
        font = stylix.fonts.mono;
        cursorSize = stylix.cursor.size;
      };
    })
  ];
}
```

### In `style.nix`:

```nix
{ config }:

''
  /* Always accept { config } parameter */

  * {
    /* Fonts from Stylix */
    font-family: "${config.stylix.fonts.monospace.name}";
    font-size: ${toString config.stylix.fonts.sizes.applications}px;
  }

  .window {
    /* GTK variables - preferred for colors (auto-updates with theme) */
    background: @theme_base_color;
    color: @theme_text_color;
    border-color: @blue;

    /* Opacity from Stylix */
    opacity: ${toString config.stylix.opacity.popups};
  }

  .special {
    /* Direct hex colors when GTK variables aren't available */
    background: #${config.lib.stylix.colors.base00};
    border: 2px solid #${config.lib.stylix.colors.base0D};
  }
''
```

## Available Stylix Values

### Fonts
```nix
config.stylix.fonts.monospace.name     # "JetBrains Mono"
config.stylix.fonts.sansSerif.name     # "Inter"
config.stylix.fonts.serif.name         # "Noto Serif"
config.stylix.fonts.sizes.applications # 11 (pixels)
config.stylix.fonts.sizes.desktop      # 10
config.stylix.fonts.sizes.popups       # 10
config.stylix.fonts.sizes.terminal     # 12
```

### Colors

**GTK CSS Variables (preferred in CSS):**
```css
/* Base colors */
@theme_base_color
@theme_text_color
@theme_bg_color
@theme_fg_color
@theme_selected_bg_color

/* Catppuccin colors (common themes) */
@blue @red @green @yellow @pink @lavender
@teal @sky @sapphire @mauve @peach
@maroon @flamingo @rosewater

/* Surfaces and overlays */
@surface0 @surface1 @surface2
@overlay0 @overlay1 @overlay2
@crust @mantle @base
@text @subtext0 @subtext1
```

**Direct Hex Colors (for non-CSS contexts):**
```nix
config.lib.stylix.colors.base00  # Background
config.lib.stylix.colors.base01  # Lighter background
config.lib.stylix.colors.base02  # Selection background
config.lib.stylix.colors.base03  # Comments, invisibles
config.lib.stylix.colors.base04  # Dark foreground
config.lib.stylix.colors.base05  # Default foreground
config.lib.stylix.colors.base06  # Light foreground
config.lib.stylix.colors.base07  # Light background
config.lib.stylix.colors.base08  # Red
config.lib.stylix.colors.base09  # Orange
config.lib.stylix.colors.base0A  # Yellow
config.lib.stylix.colors.base0B  # Green
config.lib.stylix.colors.base0C  # Cyan
config.lib.stylix.colors.base0D  # Blue
config.lib.stylix.colors.base0E  # Purple
config.lib.stylix.colors.base0F  # Brown
```

### Opacity
```nix
config.stylix.opacity.terminal      # 0.9
config.stylix.opacity.desktop       # 1.0
config.stylix.opacity.popups        # 0.95
config.stylix.opacity.applications  # 1.0
```

### Cursor
```nix
config.stylix.cursor.name     # "Adwaita"
config.stylix.cursor.size     # 24
config.stylix.cursor.package  # pkgs.adwaita-icon-theme
```

### Wallpaper
```nix
config.stylix.image  # Path to wallpaper
```

## Best Practices

1. **Always use GTK variables in CSS** - They update automatically with theme changes
2. **Use direct hex colors only when necessary** - For non-GTK contexts or when GTK vars aren't available
3. **Use stylix.mkStyle** - Consistent pattern across all modules
4. **Document your style.nix** - Add comments explaining which Stylix values you're using
5. **Keep it DRY** - Don't hardcode values that Stylix provides

## Example Modules

See these modules for reference:
- `modules/desktop/waybar/` - Status bar with comprehensive styling
- More examples coming as modules are added

## Updating Styling

To change the theme, update `settings/default.nix`:
```nix
theme = {
  base16Scheme = "catppuccin-mocha";  # Change this
  # ... other settings
}
```

All modules using Stylix will automatically update.
