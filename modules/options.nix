{ lib, config, ... }:

# Hyprflake Configuration Options
# These options allow consumers to customize hyprflake without modifying settings
# All options have sensible defaults from settings/default.nix

let
  settings = import ../settings/default.nix;
in
{
  options.hyprflake = {
    # Wallpaper configuration
    wallpaper = {
      url = lib.mkOption {
        type = lib.types.str;
        default = settings.theme.wallpaper.url;
        example = "https://example.com/wallpaper.png";
        description = ''
          URL to wallpaper image.
          This will be fetched and used by Stylix for system-wide theming.
        '';
      };

      sha256 = lib.mkOption {
        type = lib.types.str;
        default = settings.theme.wallpaper.sha256;
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
