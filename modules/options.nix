{ lib, config, pkgs, ... }:

# Hyprflake Configuration Options
# These options allow consumers to customize hyprflake
# Stylix is the source of truth - other modules reference config.stylix.*

{
  options.hyprflake = {
    # Color scheme configuration
    # This sets stylix.base16Scheme - all modules get colors from Stylix
    colorScheme = lib.mkOption {
      type = lib.types.str;
      default = "catppuccin-mocha";
      example = "gruvbox-dark-hard";
      description = ''
        Base16 color scheme name from pkgs.base16-schemes.
        This will be used by Stylix for system-wide theming.

        Popular schemes:
        - catppuccin-mocha, catppuccin-latte, catppuccin-frappe, catppuccin-macchiato
        - gruvbox-dark-hard, gruvbox-dark-medium, gruvbox-dark-soft
        - nord, dracula, tokyo-night-dark, tokyo-night-storm
        - solarized-dark, solarized-light
        - one-dark, palenight, material-darker

        Browse all schemes: https://tinted-theming.github.io/base16-gallery/

        Alternatively, set stylix.base16Scheme directly with a custom path.
      '';
    };

    # Wallpaper configuration
    wallpaper = lib.mkOption {
      type = lib.types.path;
      default = ../wallpapers/galaxy-waves.jpg;
      example = lib.literalExpression "./path/to/wallpaper.png";
      description = ''
        Path to wallpaper image file.
        Used by Stylix for system-wide theming.

        Default is the included Catppuccin Mocha galaxy-waves wallpaper.
        Override with your own local wallpaper:
          hyprflake.wallpaper = ./my-wallpaper.png;
      '';
    };

    # Font configuration
    # These set stylix.fonts.* - all modules get fonts from Stylix
    fonts = {
      monospace = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "JetBrains Mono";
          example = "Fira Code";
          description = ''
            Name of the monospace font to use system-wide.
            Used for terminals, code editors, and fixed-width text.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.jetbrains-mono;
          example = lib.literalExpression "pkgs.fira-code";
          description = ''
            Package providing the monospace font.
          '';
        };
      };

      sansSerif = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Inter";
          example = "Roboto";
          description = ''
            Name of the sans-serif font to use system-wide.
            Used for UI elements, labels, and body text.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.inter;
          example = lib.literalExpression "pkgs.roboto";
          description = ''
            Package providing the sans-serif font.
          '';
        };
      };

      serif = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Noto Serif";
          example = "Liberation Serif";
          description = ''
            Name of the serif font to use system-wide.
            Used for document reading and formal text.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.noto-fonts;
          example = lib.literalExpression "pkgs.liberation_ttf";
          description = ''
            Package providing the serif font.
          '';
        };
      };

      emoji = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "Noto Color Emoji";
          example = "Twitter Color Emoji";
          description = ''
            Name of the emoji font to use system-wide.
            Used for color emoji rendering.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = pkgs.noto-fonts-color-emoji;
          example = lib.literalExpression "pkgs.twitter-color-emoji";
          description = ''
            Package providing the emoji font.
          '';
        };
      };
    };

    # Cursor configuration
    # These set stylix.cursor.* - all modules get cursor from Stylix
    cursor = {
      name = lib.mkOption {
        type = lib.types.str;
        default = "Adwaita";
        example = "Bibata-Modern-Ice";
        description = ''
          Name of the cursor theme to use system-wide.

          Popular cursor themes:
          - Adwaita (default GNOME)
          - Bibata-Modern-Ice, Bibata-Modern-Classic
          - Catppuccin-Mocha-Cursor
          - Breeze, Breeze-Dark
        '';
      };

      size = lib.mkOption {
        type = lib.types.int;
        default = 24;
        example = 32;
        description = ''
          Size of the cursor in pixels.
          Common sizes: 24 (default), 32, 48
        '';
      };

      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.adwaita-icon-theme;
        example = lib.literalExpression "pkgs.bibata-cursors";
        description = ''
          Package providing the cursor theme.
        '';
      };
    };

    # Keyboard configuration
    keyboard = {
      layout = lib.mkOption {
        type = lib.types.str;
        default = "us";
        example = "us,de";
        description = ''
          Keyboard layout(s) to use system-wide.
          Multiple layouts can be specified separated by commas.
          Examples: "us", "us,de", "gb", "dvorak"
        '';
      };

      variant = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "colemak";
        description = ''
          Keyboard variant for the layout.
          Examples: "colemak", "dvorak", "altgr-intl"
          Leave empty for default variant.
        '';
      };
    };

    # Opacity configuration
    # These set stylix.opacity.* - applied to UI elements
    opacity = {
      terminal = lib.mkOption {
        type = lib.types.float;
        default = 0.9;
        example = 0.85;
        description = ''
          Opacity for terminal windows (0.0 - 1.0).
          1.0 = fully opaque, 0.0 = fully transparent.
        '';
      };

      desktop = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        example = 0.95;
        description = ''
          Opacity for desktop background (0.0 - 1.0).
          Usually kept at 1.0 for wallpaper visibility.
        '';
      };

      popups = lib.mkOption {
        type = lib.types.float;
        default = 0.95;
        example = 0.9;
        description = ''
          Opacity for popup windows and menus (0.0 - 1.0).
        '';
      };

      applications = lib.mkOption {
        type = lib.types.float;
        default = 1.0;
        example = 0.95;
        description = ''
          Opacity for regular application windows (0.0 - 1.0).
        '';
      };
    };

    # Theme polarity (light/dark mode)
    polarity = lib.mkOption {
      type = lib.types.enum [ "dark" "light" "either" ];
      default = "dark";
      example = "light";
      description = ''
        Theme polarity for light/dark mode preference.

        - "dark": Dark theme (default)
        - "light": Light theme
        - "either": Auto-detect from wallpaper/scheme
      '';
    };

    # User configuration
    user = {
      username = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
        example = "dustin";
        description = ''
          Username for user-specific configurations.
          Required for features like user profile photo.

          Set this to your primary user's username:
            hyprflake.user.username = "dustin";
        '';
      };

      photo = lib.mkOption {
        type = lib.types.nullOr lib.types.path;
        default = null;
        example = lib.literalExpression "./my-photo.jpg";
        description = ''
          Path to user profile photo/avatar image.
          Used by display managers (GDM) and AccountsService.

          Requires hyprflake.user.username to be set.
          Photo will be copied to /var/lib/AccountsService/icons/

          Supported formats: JPG, PNG
          Recommended size: 96x96 or larger (square)
        '';
      };
    };
  };
}
