# Hyprflake Styling Guide

This document explains how to integrate Stylix theming into hyprflake modules.

## Overview

Hyprflake uses **Stylix** for system-wide theming. Modules read Stylix values straight from `config.stylix.*` and `config.lib.stylix.colors`; there is no wrapper library.

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

## Font rendering

hyprflake sets `fonts.fontconfig.subpixel.rgba = "rgb"` and
`fonts.fontconfig.hinting.style = "slight"` (options
`hyprflake.style.fontRendering.{subpixel,hintStyle}`; `slight` is also the
nixpkgs default, so the option only pins it). NixOS otherwise ships
`10-sub-pixel-none.conf` (grayscale AA only), which reads soft at ~110 PPI and
`scale=1.0`.

GTK3/GTK4 on Wayland ignore fontconfig for antialiasing and read
`org.gnome.desktop.interface` `font-antialiasing` and `font-rgba-order`, so the
Hyprland module's `dconf.settings` mirrors `subpixel` into those keys.

Verify after a rebuild:

- `fc-match --verbose sans | grep rgba` reports `rgba: 1` (rgb), not `rgba: 5`.
- `gsettings get org.gnome.desktop.interface font-antialiasing` prints `'rgba'`.

Terminal and popup surfaces are translucent by default
(`style.opacity.terminal = 0.9`, `popups = 0.95`). Toolkits commonly fall back
to grayscale on a surface with alpha, so kitty and DMS popouts may not change
(UNVERIFIED). Opaque native windows are the sure beneficiaries.

Per-host overrides (set in the consumer, not here):

- High-density panel (> ~200 PPI) or OLED with a non-RGB subpixel layout
  (WOLED, QD-OLED): `hyprflake.style.fontRendering.subpixel = "none";`
- BGR or vertical panel: `"bgr"`, `"vrgb"` or `"vbgr"`.

### Web apps on standard-density displays

Chromium (Ozone Wayland) and WebKitGTK (Wails apps) generally render grayscale
AA on Wayland whatever fontconfig says, because the compositor may transform
the surface. For web-based apps that still look jagged, scale them up. The
gain is unverified (LOW CONFIDENCE); compare against baseline per host. The
two knobs scale different things, so the factor is not interchangeable:

| App type | Knob | Scales |
| --- | --- | --- |
| Chrome `--app` windows | `--force-device-scale-factor=1.25` | the whole UI, layout included |
| Wails / WebKitGTK apps | `GDK_DPI_SCALE=1.25` | text only, widget geometry unchanged (text can overflow fixed-size chrome) |
| Wails / WebKitGTK apps | `GDK_SCALE=2` | the whole UI, integer factors only |

hyprflake defines no web-app launchers, so apply these in the consumer's
launcher or desktop entry.

## Best Practices

1. **Always use GTK variables in CSS** - They update automatically with theme changes
2. **Use direct hex colors only when necessary** - For non-GTK contexts or when GTK vars aren't available
3. **Read values from `config.stylix.*` directly** - No wrapper layer; DMS gets its theme from the Stylix target
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

| DMS setting                                       | Fed from                          | hyprflake knob                    |
| ------------------------------------------------- | --------------------------------- | --------------------------------- |
| `customThemeFile` + `currentThemeName = "custom"` | base16 palette → Material-3 roles | `hyprflake.style.colorScheme`     |
| `fontFamily`, `monoFontFamily`                    | Stylix fonts                      | `hyprflake.style.fonts.*`         |
| `popupTransparency`                               | `opacity.popups`                  | `hyprflake.style.opacity.popups`  |
| `dockTransparency`                                | `opacity.desktop`                 | `hyprflake.style.opacity.desktop` |
| `session.wallpaperPath{,Light,Dark}`              | `stylix.image`                    | `hyprflake.style.wallpaper`       |

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

### Frosted glass (`desktop.dank.frostedGlass.enable`)

The `blur*` keys above only blur what DMS draws itself. On Hyprland (no
`ext-bg-effect-v1`) the windows _behind_ a DMS layer surface are blurred only
when a `layerrule` matches that surface's `dms:*` namespace — DMS namespaces
everything `dms:*` for exactly this. Rather than hand-managing both, the
`hyprflake.desktop.dank.frostedGlass.enable` switch (default `false`, so the look
stays flat/transparent) turns on both halves together: it sets `blurEnabled` +
`blurWallpaperOnOverview` here, and emits the `hl.layer_rule` blur + slide
animations for the `dms:*` namespaces via the hyprland module's `extraLua`
channel. Both leaves stay `mkDefault`, so a consumer or GUI capture can still
override the individual `blur*` keys. Namespaces follow
[the DMS layers docs](https://danklinux.com/docs/dankmaterialshell/layers).

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
