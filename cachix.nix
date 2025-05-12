{ config, lib, pkgs, ... }:

{
  # Configure binary caches
  nix = {
    settings = {
      substituters = [
        "https://hyprland.cachix.org"
        "https://cache.nixos.org"
      ];
      trusted-public-keys = [
        "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
      ];
    };

  };
}