{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake.desktop.autostart;
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "hyprflake" "autostart" "enable" ]
      [ "hyprflake" "desktop" "autostart" "enable" ])
    (lib.mkRenamedOptionModule
      [ "hyprflake" "autostart" "package" ]
      [ "hyprflake" "desktop" "autostart" "package" ])
  ];

  options.hyprflake.desktop.autostart = {
    enable = lib.mkEnableOption "XDG autostart support via dex" // {
      default = true;
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.dex;
      description = "The dex package to use for autostart";
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.sharedModules = [
      (_: {
        home.packages = [ cfg.package ];

        wayland.windowManager.hyprland.settings.exec-once = [
          "${cfg.package}/bin/dex --autostart --environment Hyprland"
        ];
      })
    ];
  };
}
