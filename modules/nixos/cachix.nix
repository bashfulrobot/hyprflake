{ config, lib, pkgs, ... }:

with lib;

{
  options.services.hyprflake-cachix = {
    enable = mkEnableOption "Enable cachix binary caching for Hyprland";
  };

  config = mkIf config.services.hyprflake-cachix.enable {
    nix.settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };
  };
}