{ config, lib, ... }:

let
  cfg = config.hyprflake.desktop.gtk;
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "hyprflake" "home" "gtk" "enable" ]
      [ "hyprflake" "desktop" "gtk" "enable" ])
  ];

  options.hyprflake.desktop.gtk.enable = lib.mkEnableOption "GTK theme configuration" // { default = true; };

  config = lib.mkIf cfg.enable {
    home-manager.sharedModules = [
      (_: {
        # GTK is fully managed by Stylix:
        #   - gtk.theme       → Stylix's gtk target (adw-gtk3 + base16 CSS)
        #   - gtk.font        → Stylix's gtk target (from stylix.fonts.sansSerif)
        #   - gtk.iconTheme   → Stylix's HM icons module (from stylix.icons.*,
        #                       fed by hyprflake.style.icon in modules/desktop/stylix)
        #   - home.pointerCursor → Stylix's HM cursor module (from stylix.cursor)
        # Just enable gtk so the Stylix-managed config is materialized.
        gtk.enable = true;
      })
    ];
  };
}
