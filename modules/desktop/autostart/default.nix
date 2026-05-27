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

        # `exec-once` doesn't exist in the Lua backend (the serializer would
        # emit invalid `hl.exec-once(...)`). Register an hl.on hook instead;
        # the list form composes with other modules' startup hooks.
        wayland.windowManager.hyprland.settings.on = [
          {
            _args = [
              "hyprland.start"
              (lib.generators.mkLuaInline ''
                function()
                  hl.exec_cmd("${cfg.package}/bin/dex --autostart --environment Hyprland")
                end
              '')
            ];
          }
        ];
      })
    ];
  };
}
