{ lib, pkgs, hyprflakeInputs, ... }:

# Hyprflake Configuration Options
# These options allow consumers to customize hyprflake
# Stylix is the source of truth - other modules reference config.stylix.*

{
  options.hyprflake = {
    # Style configuration - Visual appearance and theming
    style = {
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
            hyprflake.style.wallpaper = ./my-wallpaper.png;
        '';
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
            default = hyprflakeInputs.apple-fonts.packages.${pkgs.system}.sf-mono-nerd;
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
            default = hyprflakeInputs.apple-fonts.packages.${pkgs.system}.sf-pro;
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
            default = hyprflakeInputs.apple-fonts.packages.${pkgs.system}.ny;
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
    };

    # User configuration - User profile settings
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

    # Desktop configuration - Desktop environment behavior
    desktop = {
      # Waybar auto-hide configuration
      waybar = {
        autoHide = lib.mkOption {
          type = lib.types.bool;
          default = true;
          example = false;
          description = ''
            Enable waybar-auto-hide utility for Hyprland.

            Automatically hides Waybar when workspace is empty and
            shows it when cursor moves to the top edge of the screen.

            Set to false to disable auto-hide behavior:
              hyprflake.desktop.waybar.autoHide = false;
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

      # Idle management configuration (hypridle)
      idle = {
        lockTimeout = lib.mkOption {
          type = lib.types.int;
          default = 300;
          example = 600;
          description = ''
            Timeout in seconds before locking the screen.
            Default is 300 seconds (5 minutes).
            Set to 0 to disable automatic screen locking.
          '';
        };

        dpmsTimeout = lib.mkOption {
          type = lib.types.int;
          default = 360;
          example = 420;
          description = ''
            Timeout in seconds before turning off the display (DPMS).
            Default is 360 seconds (6 minutes).
            Set to 0 to disable automatic display power management.
            Should be greater than lockTimeout if both are enabled.
          '';
        };

        suspendTimeout = lib.mkOption {
          type = lib.types.int;
          default = 600;
          example = 0;
          description = ''
            Timeout in seconds before suspending the system.
            Default is 600 seconds (10 minutes).
            Set to 0 to disable automatic system suspend.
            Should be greater than dpmsTimeout if both are enabled.
          '';
        };
      };

      # Voxtype - Push-to-talk voice-to-text
      voxtype = {
        enable = lib.mkEnableOption "Voxtype push-to-talk voice-to-text with whisper.cpp";

        package = lib.mkOption {
          type = lib.types.package;
          default = hyprflakeInputs.voxtype.packages.${pkgs.system}.default;
          description = ''
            The voxtype package to use.
            Defaults to the voxtype package from hyprflake's input.
          '';
        };

        hotkey = lib.mkOption {
          type = lib.types.str;
          default = "SCROLLLOCK";
          example = "SCROLLLOCK";
          description = ''
            Evdev key name for push-to-talk activation.
            Hold to record, release to transcribe.

            Common choices: INSERT, SCROLLLOCK, PAUSE, RIGHTALT, F13-F24
            Use `evtest` to find key names for your keyboard.
          '';
        };

        model = lib.mkOption {
          type = lib.types.str;
          default = "base.en";
          example = "tiny.en";
          description = ''
            Whisper model for transcription.
            .en models are English-only but faster and more accurate for English.

            Options: tiny, tiny.en, base, base.en, small, small.en,
                     medium, medium.en, large-v3, large-v3-turbo
          '';
        };

        threads = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
          example = 4;
          description = ''
            Number of CPU threads for Whisper inference.
            When null (default), voxtype uses its own default.
            Should not exceed the number of physical CPU cores.
            Lower values reduce CPU usage; higher values speed up transcription.
          '';
        };
      };
    };

    # System configuration - System-level configuration
    system = {
      # Plymouth boot splash
      plymouth = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = ''
            Enable Plymouth boot splash screen.
            Auto-detects Catppuccin variants from colorScheme.
            Falls back to Circle HUD theme for non-Catppuccin schemes.
          '';
        };
      };

      # Power management configuration
      power = {
        # Power profile management (mutually exclusive options)
        profilesBackend = lib.mkOption {
          type = lib.types.enum [ "none" "power-profiles-daemon" "tlp" ];
          default = "none";
          example = "power-profiles-daemon";
          description = ''
            Power profile management backend to use.

            Options:
            - "none": No automatic power profile management (default)
            - "power-profiles-daemon": Modern power management (recommended for laptops)
            - "tlp": Advanced laptop power management with more granular control

            Note: power-profiles-daemon and tlp are mutually exclusive.
            Choose power-profiles-daemon for simplicity, TLP for advanced tuning.
          '';
        };

        # TLP settings (only used when profilesBackend = "tlp")
        tlp = {
          settings = lib.mkOption {
            type = lib.types.attrs;
            default = { };
            example = lib.literalExpression ''
              {
                CPU_SCALING_GOVERNOR_ON_AC = "performance";
                CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
                START_CHARGE_THRESH_BAT0 = 20;
                STOP_CHARGE_THRESH_BAT0 = 80;
              }
            '';
            description = ''
              TLP configuration settings.
              Only applies when profilesBackend = "tlp".

              See TLP documentation for all available settings:
              https://linrunner.de/tlp/settings/
            '';
          };
        };

        # Thermal management
        thermald = {
          enable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = ''
              Enable thermald thermal management daemon.
              Recommended for Intel CPUs to prevent overheating.

              Thermald monitors and controls CPU temperature through
              P-states, T-states, and cooling device adjustments.
            '';
          };
        };

        # Sleep/hibernate configuration
        sleep = {
          hibernateDelay = lib.mkOption {
            type = lib.types.nullOr lib.types.str;
            default = null;
            example = "2h";
            description = ''
              Delay before hibernating after suspend (suspend-then-hibernate).
              Format: "30min", "1h", "2h", etc.

              If set, system will suspend first, then automatically hibernate
              after the specified delay to preserve battery on long idle periods.

              Requires swap to be configured for hibernation.
              Set to null to disable suspend-then-hibernate behavior.
            '';
          };

          allowSuspend = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Allow system suspend via systemd.
              Set to false to disable suspend functionality system-wide.
              Useful for desktop systems that should never suspend.
            '';
          };

          allowHibernation = lib.mkOption {
            type = lib.types.bool;
            default = true;
            description = ''
              Allow system hibernation via systemd.
              Set to false to disable hibernation functionality system-wide.
            '';
          };
        };

        # Resume hooks
        resumeCommands = lib.mkOption {
          type = lib.types.lines;
          default = "";
          example = ''
            # Restart network manager
            systemctl restart NetworkManager
          '';
          description = ''
            Shell commands to execute after system resumes from suspend/hibernate.
            Useful for restarting services or fixing hardware state after resume.
          '';
        };

        # Battery charge thresholds (laptop-specific)
        battery = {
          startThreshold = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            example = 20;
            description = ''
              Battery charge start threshold (percentage).
              Battery will only start charging when below this percentage.

              Supported on some laptops (ThinkPad, Dell, etc.) when using TLP.
              Requires profilesBackend = "tlp" and hardware support.
              Set to null to disable.
            '';
          };

          stopThreshold = lib.mkOption {
            type = lib.types.nullOr lib.types.int;
            default = null;
            example = 80;
            description = ''
              Battery charge stop threshold (percentage).
              Battery will stop charging when reaching this percentage.

              Extending battery lifespan by limiting charge to 80% is recommended
              for laptops that are frequently plugged in.

              Supported on some laptops (ThinkPad, Dell, etc.) when using TLP.
              Requires profilesBackend = "tlp" and hardware support.
              Set to null to disable.
            '';
          };
        };

        # Logind power event handling
        logind = {
          handlePowerKey = lib.mkOption {
            type = lib.types.enum [ "ignore" "poweroff" "reboot" "halt" "kexec" "suspend" "hibernate" "hybrid-sleep" "suspend-then-hibernate" "lock" ];
            default = "poweroff";
            example = "suspend";
            description = ''
              Action to take when the power button is pressed.

              Options:
              - "poweroff": Shut down the system (default)
              - "suspend": Suspend to RAM
              - "hibernate": Hibernate to disk
              - "lock": Lock the session
              - "ignore": Do nothing
            '';
          };

          handleLidSwitch = lib.mkOption {
            type = lib.types.enum [ "ignore" "poweroff" "reboot" "halt" "kexec" "suspend" "hibernate" "hybrid-sleep" "suspend-then-hibernate" "lock" ];
            default = "suspend";
            example = "lock";
            description = ''
              Action to take when the laptop lid is closed.

              Options:
              - "suspend": Suspend to RAM (default)
              - "lock": Lock the session (recommended for desktops with lid switch)
              - "ignore": Do nothing
              - "poweroff": Shut down the system
            '';
          };

          handleLidSwitchDocked = lib.mkOption {
            type = lib.types.enum [ "ignore" "poweroff" "reboot" "halt" "kexec" "suspend" "hibernate" "hybrid-sleep" "suspend-then-hibernate" "lock" ];
            default = "ignore";
            example = "ignore";
            description = ''
              Action to take when the laptop lid is closed while docked.
              Default is "ignore" (no action when external displays are connected).
            '';
          };

          idleAction = lib.mkOption {
            type = lib.types.enum [ "ignore" "poweroff" "reboot" "halt" "kexec" "suspend" "hibernate" "hybrid-sleep" "suspend-then-hibernate" "lock" ];
            default = "ignore";
            example = "suspend";
            description = ''
              Action to take when the system is idle.
              Default is "ignore" (handled by hypridle instead).

              Note: If set to something other than "ignore", this takes precedence
              over hypridle's idle management. Consider using hypridle configuration
              instead for more granular control.
            '';
          };

          idleActionSec = lib.mkOption {
            type = lib.types.int;
            default = 0;
            example = 1800;
            description = ''
              Idle timeout in seconds before idleAction is triggered.
              Set to 0 to disable (default).

              Only relevant if idleAction is not "ignore".
              Recommended to keep at 0 and use hypridle for idle management.
            '';
          };
        };
      };
    };
  };
}
