# Theming System Reference

Hyprflake provides a unified theming system that applies consistent styling across all components.

## Theme Configuration

Configure themes once, applied everywhere:

```nix
programs.hyprflake = {
  enable = true;
  theme = {
    gtkTheme = "Adwaita-dark";
    iconTheme = "Papirus";
    cursorTheme = "Adwaita";
    cursorSize = 24;
  };
};
```

## Stylix Integration

Hyprflake integrates with Stylix for system-wide base16 color schemes:

1. Set `hyprflake.colorScheme` (e.g., "catppuccin-mocha")
2. Stylix applies the color scheme system-wide
3. All hyprflake components inherit the colors

## Theme Propagation Flow

1. User sets `hyprflake.colorScheme` (e.g., "catppuccin-mocha")
2. Stylix applies the base16 color scheme system-wide
3. Plymouth auto-detects and matches the color scheme
   - Catppuccin variants use catppuccin-plymouth
   - Other schemes fall back to Circle HUD theme
4. NixOS dconf module applies themes via `programs.dconf.profiles.user.databases`
5. Home Manager dconf module applies via `dconf.settings`
6. Home Manager GTK module configures themes directly
7. Wallpaper is shared between Hyprland and Stylix

## Plymouth Boot Splash

Enable Plymouth with automatic color scheme matching:

```nix
hyprflake.plymouth.enable = true;
```

- Catppuccin color schemes automatically use catppuccin-plymouth
- Other schemes use Circle HUD theme
- Wallpaper matches Hyprland wallpaper

## Application-Specific Theming

These applications receive automatic theming from hyprflake:

- **kitty** - Terminal emulator colors
- **rofi** - Application launcher
- **swaync** - Notification daemon
- **swayosd** - On-screen display
- **wlogout** - Logout menu
- **waybar** - Status bar

## dconf Integration

Enable dconf theme application:

**NixOS:**

```nix
programs.hyprflake-dconf.enable = true;
```

**Home Manager:**

```nix
dconf.hyprflake.enable = true;
```

## GTK Configuration

Home Manager GTK theming is handled automatically when using the hyprflake Home Manager module.

The GTK module in `modules/home/gtk/` configures:

- GTK theme
- Icon theme
- Cursor theme and size
- Font configuration (via Stylix)
