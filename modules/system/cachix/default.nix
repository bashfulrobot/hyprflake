{ config, lib, pkgs, ... }:

{
  # Hyprland Cachix binary cache
  # Provides pre-built Hyprland binaries to avoid long compilation times

  nix.settings = {
    substituters = [
      "https://hyprland.cachix.org"
    ];
    trusted-public-keys = [
      "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
    ];
  };
}
