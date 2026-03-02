{ config, lib, ... }:

let
  cfg = config.hyprflake.desktop.wl-clip-persist;
in
{
  options.hyprflake.desktop.wl-clip-persist.enable = lib.mkEnableOption "wl-clip-persist clipboard persistence" // { default = true; };

  config = lib.mkIf cfg.enable {
    # wl-clip-persist - Keep clipboard contents alive after apps exit
    # Prevents clipboard from being cleared when the owning application closes

    home-manager.sharedModules = [
      (_: {
        services.wl-clip-persist = {
          enable = true;
          clipboardType = "both";
        };
      })
    ];
  };
}

