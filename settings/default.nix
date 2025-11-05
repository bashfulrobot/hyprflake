{
  # Default theme settings for Hyprflake
  # Override these in your consuming flake or via module options

  theme = {
    # Base16 color scheme
    base16Scheme = "catppuccin-mocha";

    # Font configuration
    fonts = {
      monospace = {
        name = "JetBrains Mono";
        package = "jetbrains-mono";
      };
      sansSerif = {
        name = "Inter";
        package = "inter";
      };
      serif = {
        name = "Noto Serif";
        package = "noto-fonts";
      };
    };

    # GTK theme
    gtk = {
      theme = "Adwaita-dark";
      iconTheme = "Adwaita";
    };

    # Cursor theme
    cursor = {
      theme = "Adwaita";
      size = 24;
    };
  };

  # System defaults
  system = {
    audio = {
      enable = true;
      lowLatency = false;
    };

    fonts = {
      enable = true;
    };

    keyring = {
      enable = true;
    };

    keyboard = {
      layout = "us";
      variant = "";
    };
  };
}
