{
  config,
  lib,
  pkgs,
  hyprflakeInputs,
  ...
}:

{
  # Stylix system-wide theming
  # Uses hyprflake.* options for consumer configuration

  options.hyprflake.style = {
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
      default = ../../../wallpapers/galaxy-waves.jpg;
      example = lib.literalExpression "./path/to/wallpaper.png";
      description = ''
        Path to wallpaper image file.
        Used by Stylix for system-wide theming.

        Default is the included Catppuccin Mocha galaxy-waves wallpaper.
        Override with your own local wallpaper:
          hyprflake.style.wallpaper = ./my-wallpaper.png;
      '';
    };

    # Theme polarity (light/dark mode)
    polarity = lib.mkOption {
      type = lib.types.enum [
        "dark"
        "light"
        "either"
      ];
      default = "dark";
      example = "light";
      description = ''
        Theme polarity for light/dark mode preference.

        - "dark": Dark theme (default)
        - "light": Light theme
        - "either": Auto-detect from wallpaper/scheme
      '';
    };

    # Font configuration
    # These set stylix.fonts.* - all modules get fonts from Stylix
    fonts = {
      monospace = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "SFMono Nerd Font";
          example = "JetBrains Mono";
          description = ''
            Name of the monospace font to use system-wide.
            Used for terminals, code editors, and fixed-width text.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = hyprflakeInputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-mono-nerd;
          example = lib.literalExpression "pkgs.jetbrains-mono";
          description = ''
            Package providing the monospace font.
          '';
        };
      };

      sansSerif = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "SF Pro Display";
          example = "Roboto";
          description = ''
            Name of the sans-serif font to use system-wide.
            Used for UI elements, labels, and body text.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = hyprflakeInputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.sf-pro;
          example = lib.literalExpression "pkgs.roboto";
          description = ''
            Package providing the sans-serif font.
          '';
        };
      };

      serif = {
        name = lib.mkOption {
          type = lib.types.str;
          default = "New York";
          example = "Liberation Serif";
          description = ''
            Name of the serif font to use system-wide.
            Used for document reading and formal text.
          '';
        };

        package = lib.mkOption {
          type = lib.types.package;
          default = hyprflakeInputs.apple-fonts.packages.${pkgs.stdenv.hostPlatform.system}.ny;
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
        default = "catppuccin-mocha-dark-cursors";
        example = "Bibata-Modern-Ice";
        description = ''
          Name of the cursor theme to use system-wide.

          Popular cursor themes:
          - catppuccin-mocha-dark-cursors (Catppuccin Mocha)
          - Bibata-Modern-Ice, Bibata-Modern-Classic
          - Adwaita (default GNOME)
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
        default = pkgs.catppuccin-cursors.mochaDark;
        example = lib.literalExpression "pkgs.bibata-cursors";
        description = ''
          Package providing the cursor theme.
        '';
      };
    };

    # Icon theme configuration
    # Stylix doesn't auto-theme icons, so we configure manually
    icon = {
      package = lib.mkOption {
        type = lib.types.package;
        default = pkgs.papirus-icon-theme;
        example = lib.literalExpression "pkgs.adwaita-icon-theme";
        description = ''
          Icon theme package to use system-wide.
          Default is Papirus (works well with Catppuccin).

          Popular icon themes:
          - Papirus (papirus-icon-theme)
          - Adwaita (adwaita-icon-theme)
          - Numix (numix-icon-theme)
          - Tela (tela-icon-theme)
        '';
      };

      name = lib.mkOption {
        type = lib.types.str;
        default = "Papirus-Dark";
        example = "Adwaita";
        description = ''
          Name of the icon theme.
          Must match the theme name provided by the package.

          For Papirus variants:
          - Papirus-Dark (dark variant)
          - Papirus-Light (light variant)
          - Papirus (adaptive)
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

    # Font sizes (in points, 72 points = 1 inch)
    # These set stylix.fonts.sizes.* - applied across the desktop.
    fontSizes = {
      terminal = lib.mkOption {
        type = lib.types.int;
        default = 14;
        example = 12;
        description = "Font size for terminals and code editors.";
      };

      applications = lib.mkOption {
        type = lib.types.int;
        default = 12;
        example = 11;
        description = "Font size for general applications.";
      };

      desktop = lib.mkOption {
        type = lib.types.int;
        default = 10;
        example = 11;
        description = "Font size for window titles, status bars, panels.";
      };

      popups = lib.mkOption {
        type = lib.types.int;
        default = 10;
        example = 11;
        description = "Font size for notifications and popups.";
      };
    };
  };

  config = {
    stylix = {
      enable = true;

      # Base16 color scheme from hyprflake.style.colorScheme option
      # Stylix auto-generates GTK theme from this color scheme
      base16Scheme = "${pkgs.base16-schemes}/share/themes/${config.hyprflake.style.colorScheme}.yaml";

      # Wallpaper from hyprflake.style.wallpaper option.
      # mkDefault so consumers can override with plain `stylix.image = ./foo.png;`
      # without needing lib.mkForce.
      image = lib.mkDefault config.hyprflake.style.wallpaper;

      # Icon theme: Stylix's HM icons module sets gtk.iconTheme and is also read by
      # the qt target to populate qt5ctSettings.Appearance.icon_theme. We feed the
      # same name to both `dark` and `light` so behavior matches the previous
      # hand-rolled gtk.iconTheme path (Stylix selects dark vs light based on
      # polarity); consumers who want polarity-aware themes can override
      # stylix.icons.{dark,light} directly.
      icons = {
        enable = true;
        inherit (config.hyprflake.style.icon) package;
        dark = config.hyprflake.style.icon.name;
        light = config.hyprflake.style.icon.name;
      };

      # Fonts from hyprflake.style options
      fonts = {
        monospace = {
          inherit (config.hyprflake.style.fonts.monospace) package name;
        };
        sansSerif = {
          inherit (config.hyprflake.style.fonts.sansSerif) package name;
        };
        serif = {
          inherit (config.hyprflake.style.fonts.serif) package name;
        };
        emoji = {
          inherit (config.hyprflake.style.fonts.emoji) package name;
        };

        # Font sizes (in points) from hyprflake.style.fontSizes options
        sizes = {
          inherit (config.hyprflake.style.fontSizes)
            terminal
            applications
            desktop
            popups
            ;
        };
      };

      # Cursor theme from options
      cursor = {
        inherit (config.hyprflake.style.cursor) name size package;
      };

      # Opacity from hyprflake.style options
      opacity = {
        inherit (config.hyprflake.style.opacity)
          terminal
          desktop
          popups
          applications
          ;
      };

      # Theme polarity from hyprflake.style options
      inherit (config.hyprflake.style) polarity;

      # Stylix's gtksourceview target patches the package with overrideAttrs to
      # inject a theme style file. That changes gtksourceview's store hash, so
      # every dependent — most painfully inkscape (a ~15min C++ build) — drops
      # out of cache.nixos.org and recompiles from source on each closure
      # change. Default the target off so the cached, pristine gtksourceview and
      # its dependents are substituted instead. Consumers who actually theme a
      # GtkSourceView editor (gedit, gnome-text-editor) can opt back in with
      # `stylix.targets.gtksourceview.enable = true;`.
      targets.gtksourceview.enable = lib.mkDefault false;
    };

    # The Stylix rofi target lives under home-manager (modules/rofi/hm.nix in
    # Stylix); it writes programs.rofi.theme, but hyprflake invokes rofi with
    # an explicit `-theme` path (see modules/desktop/hyprland), so the
    # generated theme is never used. Disable from HM context to skip the eval.
    home-manager.sharedModules = [
      {
        # rofi is retired; its Stylix target would write a theme for a
        # program that is no longer installed.
        stylix.targets.rofi.enable = false;
        # DankMaterialShell theming: Stylix feeds base16 colors, fonts,
        # opacity, and the wallpaper path. DMS is hyprflake's core shell and
        # always present, so the target is always enabled.
        stylix.targets.dank-material-shell.enable = true;
      }
    ];
  };
}
