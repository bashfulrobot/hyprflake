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
@theme_base_color @theme_text_color
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
@text @subtext0 @subtext1;
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

## DankMaterialShell theming

The desktop shell (DMS) is themed through Stylix's first-party target rather
than a hand-rolled `style.nix`. `modules/desktop/stylix/default.nix` enables it:

```nix
stylix.targets.dank-material-shell.enable = config.hyprflake.desktop.dank.enable;
```

The target maps base16 colors into DMS's Material-3 roles, sets fonts and
opacity, and writes `session.wallpaperPath` (so DMS owns the wallpaper). The
`dank` module sets `programs.dank-material-shell.enableDynamicTheming = false`
so DMS's wallpaper-driven matugen does not compete with Stylix. Stylix remains
the single source of truth.

### What Stylix owns (do not set these on DMS directly)

The `dank-material-shell` Stylix target writes exactly these DMS settings and
nothing else. Change them through the corresponding `hyprflake.style.*` option,
not by setting the DMS key — setting both makes the two engines fight.

| DMS setting | Fed from | hyprflake knob |
|---|---|---|
| `customThemeFile` + `currentThemeName = "custom"` | base16 palette → Material-3 roles | `hyprflake.style.colorScheme` |
| `fontFamily`, `monoFontFamily` | Stylix fonts | `hyprflake.style.fonts.*` |
| `popupTransparency` | `opacity.popups` | `hyprflake.style.opacity.popups` |
| `dockTransparency` | `opacity.desktop` | `hyprflake.style.opacity.desktop` |
| `session.wallpaperPath{,Light,Dark}` | `stylix.image` | `hyprflake.style.wallpaper` |

### What is tunable

Every other DMS setting is unclaimed by Stylix and may be set declaratively in
the `programs.dank-material-shell.settings` block in
`modules/desktop/dank/default.nix`. The authoritative key list with defaults is
DMS's own `Common/settings/SettingsSpec.js` (in the `dms-shell` package). The
appearance-relevant families:

- **Global shape & motion:** `cornerRadius`, `fontWeight`, `fontScale`,
  `animationSpeed` (+ `popoutAnimationSpeed`, `modalAnimationSpeed` and their
  `custom*Duration` siblings), the `blur*` family (`blurEnabled`,
  `blurForegroundLayers`, `blurBorderColor/Opacity`, `blurredWallpaperLayer`,
  `blurWallpaperOnOverview`), and the colour-mapping overrides
  `widgetColorMode`, `buttonColorMode`, `controlCenterTileColorMode`,
  `widgetBackgroundColor`.
- **Bar appearance (per-bar, inside `barConfigs`):** `transparency`,
  `widgetTransparency`, `noBackground`, `squareCorners`, the border/outline set
  (`borderEnabled` + `borderColor/Opacity/Thickness`, `widgetOutlineEnabled` +
  `widgetOutline{Color,Opacity,Thickness}`), `gothCornersEnabled` +
  `gothCornerRadius{Override,Value}`, the shadow set (`shadowIntensity`,
  `shadowOpacity`, `shadowColorMode`, `shadowCustomColor`), and spacing/scale
  (`spacing`, `innerPadding`, `bottomGap`, `widgetPadding`,
  `removeWidgetPadding`, `fontScale`, `iconScale`, `maximizeWidgetIcons/Text`).
- **Workspace pills:** `showWorkspaceIndex`, `showWorkspaceName`,
  `showWorkspaceApps`, `showWorkspacePadding`, `maxWorkspaceIcons`.
- **System tray:** `systemTrayIconTintMode/Saturation/Strength`.
- **Dock (off by default, `showDock`):** `dockIconSize`, `dockIndicatorStyle`,
  `dockSpacing/BottomGap/Margin`, the `dockBorder*` set, `dockEnlargeOnHover`,
  and the `dockLauncherLogo*` block.
- **Notifications / lock:** `notificationPopupShadowEnabled`,
  `notificationOverlayEnabled`, `lockScreenShow{Time,PowerActions,SystemIcons}`,
  `fadeToLockEnabled`, `clockDateFormat`, `lockDateFormat`.
- **Wallpaper fit:** `wallpaperFillMode` (default `"Fill"`).

`barConfigs` is read verbatim when present (DMS only synthesises defaults when
the key is absent — `Common/settings/SettingsStore.js`), but each per-bar
styling field is read with a `?? default` fallback at the QML site, so a
`barConfigs` entry only needs the bar identity and widget lists; omitted styling
fields keep their upstream defaults. See the `barConfigs` block in
`modules/desktop/dank/default.nix` for the worked example.

> **Compositor-layout bridge.** `hyprlandLayoutGapsOverride`,
> `hyprlandLayoutRadiusOverride`, and `hyprlandLayoutBorderSize` (all default
> `-1` = "do not override") let DMS push gaps/radius/border into Hyprland. The
> Hyprland module already owns those values, so leave them at `-1` to avoid a
> second authority over window layout.

> **Persistence gotcha.** `~/.config/DankMaterialShell/settings.json` is a
> read-only symlink into the Nix store. DMS's in-app settings GUI can display
> and preview these keys, but any change made there is lost on the next rebuild.
> The `settings` block is the only durable home.

## Example Modules

See these modules for reference:

- `modules/desktop/shortcuts-viewer/` - injects `config.lib.stylix.colors` and
  `config.stylix.fonts` into an HTML template at build time (raw-sink pattern)

## Updating Styling

To change the theme, set `hyprflake.style.colorScheme` in your consumer config:

```nix
hyprflake.style.colorScheme = "catppuccin-mocha";  # any name from pkgs.base16-schemes
```

All modules using Stylix will automatically pick up the new palette.

To override the wallpaper, set `hyprflake.style.wallpaper` (or `stylix.image` directly).
Hyprflake sets `stylix.image` with `lib.mkDefault`, so plain `stylix.image = ./foo.png;`
in consumer config wins without needing `lib.mkForce`.
