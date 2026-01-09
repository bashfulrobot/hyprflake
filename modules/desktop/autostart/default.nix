{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.hyprflake.autostart;
in
{
  options.hyprflake.autostart = {
    enable = mkEnableOption "XDG autostart support via dex" // {
      default = true;
    };

    package = mkOption {
      type = types.package;
      default = pkgs.dex;
      description = "The dex package to use for autostart";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    wayland.windowManager.hyprland.settings.exec-once = [
      "${cfg.package}/bin/dex --autostart --environment Hyprland"
    ];
  };
}
