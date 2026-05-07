{ pkgs, ... }:

{
  # Theme-engine packages.
  #
  # The icon-theme package and cursor-theme package are now installed by Stylix
  # (via stylix.icons and stylix.cursor in modules/desktop/stylix), so we don't
  # duplicate those here.
  #
  # gtk-engine-murrine and gnome-themes-extra are kept for compatibility with
  # downstream GTK themes that bypass Stylix's adw-gtk3 path. Both are small
  # and harmless when unused.
  environment.systemPackages = [
    pkgs.gtk-engine-murrine # required by many third-party GTK themes
    pkgs.gnome-themes-extra # Adwaita and other base themes
  ];
}
