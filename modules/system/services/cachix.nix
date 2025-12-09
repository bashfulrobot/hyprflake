{ config, lib, ... }:

# Hyprland Binary Cache Configuration
# Enables cachix.org binary cache for Hyprland to avoid building from source

{
  options.hyprflake.cachix = {
    enable = lib.mkEnableOption "Hyprland binary cache" // {
      default = true;
    };
  };

  config = lib.mkIf config.hyprflake.cachix.enable {
    nix.settings = {
      substituters = [
        "https://hyprland.cachix.org"
      ];

      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };
  };
}
