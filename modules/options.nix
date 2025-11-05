{ lib, config, ... }:

# Hyprflake Configuration Options
# These options allow consumers to customize hyprflake
# Stylix is the source of truth - other modules reference config.stylix.image

{
  options.hyprflake = {
    # Wallpaper configuration
    # This sets stylix.image - all modules should reference that
    wallpaper = {
      url = lib.mkOption {
        type = lib.types.str;
        default = "https://raw.githubusercontent.com/NixOS/nixos-artwork/master/wallpapers/nix-wallpaper-simple-blue.png";
        example = "https://example.com/wallpaper.png";
        description = ''
          URL to wallpaper image.
          This will be fetched and used by Stylix for system-wide theming.
          Other modules should reference config.stylix.image, not this option.
        '';
      };

      sha256 = lib.mkOption {
        type = lib.types.str;
        default = "sha256-Q7L0xNKBw1MdJlkXNYMHd5SWPq9n8Hd/akWCp1Cp2lE=";
        example = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
        description = ''
          SHA256 hash of the wallpaper image.
          Required for Nix to verify the downloaded file.
          Get this by running: nix-prefetch-url <url>
        '';
      };
    };
  };
}
