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
          # Only persist selections whose offered MIME types are all non-media.
          # wl-clip-persist works by reading every offered type into memory and
          # re-serving it; when it hits a read error on image/audio/video data
          # it overwrites the clipboard with a text-only copy, which destroys a
          # copied image before an app (e.g. Claude Code) can paste it. This
          # negative-lookahead regex makes wl-clip-persist skip any selection
          # offering a media type, so images pass through untouched (pastable
          # while the source app is open) while text/code still persists.
          # Requires fancy-regex lookahead, which wl-clip-persist bundles.
          # See https://github.com/Linus789/wl-clip-persist#images
          extraOptions = [
            "--all-mime-type-regex"
            "(?i)^(?!(?:image|audio|video|font|model)/).+"
          ];
        };
      })
    ];
  };
}

