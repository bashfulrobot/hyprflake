{ config, lib, ... }:

# Hyprland Binary Cache Configuration
# Enables cachix.org binary cache for Hyprland to avoid building from source

{
  config = lib.mkIf config.hyprflake.system.cachix.enable {
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
