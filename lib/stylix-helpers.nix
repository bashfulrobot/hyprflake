{ lib, config }:

# Stylix Helper Library
# Provides consistent access to Stylix theming values across all modules
#
# Usage in modules:
#   let
#     stylix = import ../../lib/stylix-helpers.nix { inherit lib config; };
#   in
#   {
#     style = stylix.mkStyle ./style.nix;
#     someValue = stylix.fonts.mono;
#   }
#
# Usage in style.nix files:
#   { config }: ''
#     font-family: "${config.stylix.fonts.monospace.name}";
#     background: @theme_base_color;  /* GTK variable */
#   ''

rec {
  # Helper to import style files with config
  # Usage: style = stylix.mkStyle ./style.nix;
  mkStyle = stylePath: import stylePath { inherit config; };

  # Font shortcuts for non-CSS contexts
  fonts = {
    # Font names
    mono = config.stylix.fonts.monospace.name;
    sans = config.stylix.fonts.sansSerif.name;
    serif = config.stylix.fonts.serif.name;

    # Font packages (for installing)
    monoPackage = config.stylix.fonts.monospace.package;
    sansPackage = config.stylix.fonts.sansSerif.package;
    serifPackage = config.stylix.fonts.serif.package;

    # Font sizes (in pixels)
    applications = config.stylix.fonts.sizes.applications;
    desktop = config.stylix.fonts.sizes.desktop;
    popups = config.stylix.fonts.sizes.popups;
    terminal = config.stylix.fonts.sizes.terminal;
  };

  # Direct color access (for non-GTK contexts)
  # In CSS, prefer GTK variables like @blue, @theme_base_color
  # Use these only when you need direct hex colors
  colors = config.lib.stylix.colors;  # base00 through base0F

  # Opacity values (0.0 - 1.0)
  opacity = {
    terminal = config.stylix.opacity.terminal;
    desktop = config.stylix.opacity.desktop;
    popups = config.stylix.opacity.popups;
    applications = config.stylix.opacity.applications;
  };

  # Cursor theme
  cursor = {
    name = config.stylix.cursor.name;
    size = config.stylix.cursor.size;
    package = config.stylix.cursor.package;
  };

  # Wallpaper (from Stylix - the source of truth)
  # Use this in modules that need the wallpaper path
  wallpaper = config.stylix.image;

  # GTK CSS color variables reference
  # Use these in CSS files with @variable syntax
  # They automatically update when theme changes
  gtkColorVars = {
    # Base colors
    base = "@theme_base_color";
    text = "@theme_text_color";
    bg = "@theme_bg_color";
    fg = "@theme_fg_color";
    selected = "@theme_selected_bg_color";
    selectedFg = "@theme_selected_fg_color";

    # Catppuccin colors (common in Stylix themes)
    blue = "@blue";
    red = "@red";
    green = "@green";
    yellow = "@yellow";
    pink = "@pink";
    lavender = "@lavender";
    teal = "@teal";
    sky = "@sky";
    sapphire = "@sapphire";
    mauve = "@mauve";
    peach = "@peach";
    maroon = "@maroon";
    flamingo = "@flamingo";
    rosewater = "@rosewater";

    # Surfaces and overlays
    surface0 = "@surface0";
    surface1 = "@surface1";
    surface2 = "@surface2";
    overlay0 = "@overlay0";
    overlay1 = "@overlay1";
    overlay2 = "@overlay2";

    # Catppuccin special colors (additional)
    crust = "@crust";
    mantle = "@mantle";
    subtext0 = "@subtext0";
    subtext1 = "@subtext1";
  };

  # Documentation for style.nix authors
  styleDocs = ''
    # Stylix Integration Guide for style.nix files

    All style.nix files should accept { config }:

    ## Fonts
    - Monospace: config.stylix.fonts.monospace.name
    - Sans-Serif: config.stylix.fonts.sansSerif.name
    - Serif: config.stylix.fonts.serif.name
    - Size: config.stylix.fonts.sizes.applications

    ## Colors (prefer GTK variables in CSS)
    - GTK variables: @blue, @theme_base_color, @surface0 (auto-updates)
    - Direct hex: #''${config.lib.stylix.colors.base0D} (static)

    ## Opacity
    - Popups: config.stylix.opacity.popups
    - Terminal: config.stylix.opacity.terminal
    - Desktop: config.stylix.opacity.desktop
    - Applications: config.stylix.opacity.applications

    ## Example style.nix:
    { config }: '''
      * {
        font-family: "''${config.stylix.fonts.monospace.name}";
        font-size: ''${toString config.stylix.fonts.sizes.applications}px;
      }

      .window {
        background: @theme_base_color;  /* GTK variable - preferred */
        color: @theme_text_color;
        opacity: ''${toString config.stylix.opacity.popups};
      }

      .accent {
        color: @blue;  /* GTK variable for theming */
      }
    '''
  '';
}
