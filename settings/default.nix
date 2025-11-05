{
  # Default theme settings for Hyprflake
  # Override these in your consuming flake or via module options

  theme = {
    # Base16 color scheme
    base16Scheme = "catppuccin-mocha";

    # Wallpaper configuration
    wallpaper = {
      url = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-simple-blue.png";
      sha256 = "sha256-Q7L0xNKBw1MdJlkXNYMHd5SWPq9n8Hd/akWCp1Cp2lE=";
    };

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
