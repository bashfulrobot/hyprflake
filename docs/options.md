# Hyprflake Configuration Options

Complete reference for all hyprflake configuration options, organized into logical groups.

## Table of Contents

- [Style Configuration](#style-configuration)
- [User Configuration](#user-configuration)
- [Desktop Configuration](#desktop-configuration)
- [System Configuration](#system-configuration)
- [Configuration Examples](#configuration-examples)

## Style Configuration

Visual appearance and theming options for your Hyprland desktop.

### Color & Theming

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `style.colorScheme` | `string` | `"catppuccin-mocha"` | Base16 color scheme from pkgs.base16-schemes. Browse schemes at [base16-gallery](https://tinted-theming.github.io/base16-gallery/) |
| `style.wallpaper` | `path` | `../wallpapers/galaxy-waves.jpg` | Path to wallpaper image file |
| `style.polarity` | `"dark"` \| `"light"` \| `"either"` | `"dark"` | Theme polarity preference |

### Fonts

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `style.fonts.monospace.name` | `string` | `"Iosevka Nerd Font"` | Monospace font name for terminals and code |
| `style.fonts.monospace.package` | `package` | `pkgs.nerd-fonts.iosevka` | Monospace font package |
| `style.fonts.sansSerif.name` | `string` | `"Inter"` | Sans-serif font name for UI elements |
| `style.fonts.sansSerif.package` | `package` | `pkgs.inter` | Sans-serif font package |
| `style.fonts.serif.name` | `string` | `"Noto Serif"` | Serif font name for documents |
| `style.fonts.serif.package` | `package` | `pkgs.noto-fonts` | Serif font package |
| `style.fonts.emoji.name` | `string` | `"Noto Color Emoji"` | Emoji font name |
| `style.fonts.emoji.package` | `package` | `pkgs.noto-fonts-color-emoji` | Emoji font package |

### Cursor

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `style.cursor.name` | `string` | `"catppuccin-mocha-dark-cursors"` | Cursor theme name |
| `style.cursor.size` | `int` | `24` | Cursor size in pixels (common: 24, 32, 48) |
| `style.cursor.package` | `package` | `pkgs.catppuccin-cursors.mochaDark` | Cursor theme package |

### Icon Theme

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `style.icon.name` | `string` | `"Papirus-Dark"` | Icon theme name |
| `style.icon.package` | `package` | `pkgs.papirus-icon-theme` | Icon theme package |

### Opacity

Window opacity settings (0.0 = transparent, 1.0 = opaque).

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `style.opacity.terminal` | `float` | `0.9` | Terminal window opacity |
| `style.opacity.desktop` | `float` | `1.0` | Desktop background opacity |
| `style.opacity.popups` | `float` | `0.95` | Popup window opacity |
| `style.opacity.applications` | `float` | `1.0` | Application window opacity |

## User Configuration

User profile settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `user.username` | `nullOr string` | `null` | **Optional but recommended.** Username for user-specific configurations. Required if setting `user.photo`. |
| `user.photo` | `nullOr path` | `null` | Path to user profile photo (96x96+ recommended, JPG/PNG). Requires `user.username` to be set. |

**Note:** While these options have default values of `null`, it's recommended to set `user.username` for proper user-specific configurations. The `user.photo` option requires `user.username` to be set.

## Desktop Configuration

Desktop environment behavior and input settings.

### Keyboard

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `desktop.keyboard.layout` | `string` | `"us"` | Keyboard layout (can be comma-separated: "us,de") |
| `desktop.keyboard.variant` | `string` | `""` | Keyboard variant (e.g., "colemak", "dvorak") |

### Waybar

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `desktop.waybar.autoHide` | `bool` | `true` | Auto-hide Waybar when workspace is empty |

## System Configuration

System-level settings.

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `system.plymouth.enable` | `bool` | `false` | Enable Plymouth boot splash (auto-detects Catppuccin themes) |

## Configuration Examples

### Minimal Configuration (Using Defaults)

The simplest configuration uses all defaults and only specifies user information:

```nix
{
  hyprflake.user = {
    username = "dustin";
    photo = ./my-photo.jpg;
  };
}
```

This gives you:
- Catppuccin Mocha color scheme
- Default galaxy-waves wallpaper
- Iosevka Nerd Font for terminals
- Inter font for UI
- Dark theme
- All other defaults

### Customizing Selected Options

Here's an example showing how to override specific options while keeping other defaults:

```nix
{
  hyprflake = {
    # Customize visual style
    style = {
      colorScheme = "gruvbox-dark-hard";
      wallpaper = ./wallpapers/my-wallpaper.png;

      # Use JetBrains Mono instead of default Iosevka
      fonts.monospace = {
        name = "JetBrainsMono Nerd Font";
        package = pkgs.nerd-fonts.jetbrains-mono;
      };

      # Larger cursor for HiDPI displays
      cursor.size = 32;

      # More transparent terminal
      opacity.terminal = 0.85;
    };

    # User profile
    user = {
      username = "dustin";
      photo = ./my-photo.jpg;
    };

    # Enable Plymouth boot splash
    system.plymouth.enable = true;
  };
}
```

### Overriding in Host Configuration

You can override any hyprflake setting in your host-specific configuration:

```nix
# In your host configuration.nix
{
  # Override just the wallpaper for this host
  hyprflake.style.wallpaper = ./host-specific-wallpaper.png;

  # Override keyboard layout for this host
  hyprflake.desktop.keyboard = {
    layout = "us,de";
    variant = "colemak";
  };
}
```

## Notes

### Mandatory vs Optional

- **All options are technically optional** and have sensible defaults
- **Recommended minimum**: Set `user.username` for proper user-specific configurations
- **User Photo**: If you want to use `user.photo`, you must also set `user.username`

### Integration Details

- **Stylix Integration**: Most style options are passed to Stylix, which handles system-wide theming
- **Font Packages**: When changing fonts, both `name` and `package` must match
- **Multiple Keyboards**: Use comma-separated layouts: `"us,de"`
- **Opacity Values**: Range from 0.0 (transparent) to 1.0 (opaque)
