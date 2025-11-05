{ lib, config, pkgs, ... }:

# Hyprflake Configuration Options
# These options allow consumers to customize hyprflake
# Stylix is the source of truth - other modules reference config.stylix.*

let
  settings = import ../settings/default.nix;
in
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

    # Wallpaper configuration (for remote URLs)
    # For local files, set stylix.image directly instead
    wallpaper = {
      url = lib.mkOption {
        type = lib.types.str;
        default = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-simple-blue.png";
        example = "https://example.com/wallpaper.png";
        description = ''
          URL to remote wallpaper image.
          This will be fetched and used by Stylix for system-wide theming.

          For local wallpapers, set stylix.image directly instead:
            stylix.image = ./path/to/wallpaper.png;

          Other modules should reference config.stylix.image, not this option.
        '';
      };

      sha256 = lib.mkOption {
        type = lib.types.str;
        default = "sha256-Q7L0xNKBw1MdJlkXNYMHd5SWPq9n8Hd/akWCp1Cp2lE=";
        example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        description = ''
          SHA256 hash of the remote wallpaper image.
          Required for Nix to verify the downloaded file.
          Get this by running: nix-prefetch-url <url>

          Not needed for local wallpapers (use stylix.image instead).
        '';
      };
    };
  };
}
