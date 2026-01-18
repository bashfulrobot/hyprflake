{ config, lib, ... }:

{
  # Kitty terminal configuration
  # Colors are handled automatically by Stylix with visibility improvements
  # Fonts are inherited from Stylix config

  home-manager.sharedModules = [
    ({ config, ... }: {
      programs.kitty = {
        enable = true;
        enableGitIntegration = true;

        # Font inherited from Stylix (can be overridden by user config)
        font = {
          name = lib.mkDefault config.stylix.fonts.monospace.name;
          package = lib.mkDefault config.stylix.fonts.monospace.package;
          size = lib.mkDefault config.stylix.fonts.sizes.terminal;
        };

        # Shell integration
        shellIntegration = {
          enableBashIntegration = true;
          enableFishIntegration = true;
          enableZshIntegration = true;
        };

        # Basic settings
        settings = {
          # Improve visibility of color8 (bright black) used for fish autosuggestions
          # The tinted-kitty theme sets color8 to base02 which is too dark
          # Override with base04 for better readability
          color8 = "#${config.lib.stylix.colors.base04}";
          # Font variants (auto-detect from main font)
          bold_font = "auto";
          italic_font = "auto";
          bold_italic_font = "auto";

          # Window
          window_padding_width = 15;
          hide_window_decorations = "yes";
          confirm_os_window_close = 0;

          # Cursor
          cursor_shape = "block";
          cursor_blink_interval = 0;

          # Clipboard
          clipboard_max_size = 0; # Unlimited clipboard history

          # Mouse
          copy_on_select = "yes";
          strip_trailing_spaces = "smart";

          # Performance
          repaint_delay = 10;
          input_delay = 3;
          sync_to_monitor = "yes";

          # Terminal bell
          enable_audio_bell = "no";
          visual_bell_duration = 0;

          # URL handling
          url_style = "curly";
          open_url_with = "default";
        };

        # Environment variables
        environment = {
          COLORTERM = "truecolor"; # Enable 24-bit color support
          WINIT_X11_SCALE_FACTOR = "1"; # Disable X11 scaling
        };

        # Keybindings
        keybindings = {
          # Copy/Paste
          "ctrl+shift+c" = "copy_to_clipboard";
          "ctrl+shift+v" = "paste_from_clipboard";

          # Font size
          "ctrl+shift+equal" = "change_font_size all +2.0";
          "ctrl+shift+minus" = "change_font_size all -2.0";
          "ctrl+shift+0" = "change_font_size all 0";

          # Tab management
          "ctrl+shift+t" = "new_tab";
          "ctrl+shift+q" = "close_tab";
          "ctrl+shift+right" = "next_tab";
          "ctrl+shift+left" = "previous_tab";

          # Window management
          "ctrl+shift+enter" = "new_window";
          "ctrl+shift+w" = "close_window";
        };
      };
    })
  ];
}

