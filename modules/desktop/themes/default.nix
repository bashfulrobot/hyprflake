{ pkgs, ... }:

{
  # Theme-engine packages.
  #
  # The icon-theme package and cursor-theme package are now installed by Stylix
  # (via stylix.icons and stylix.cursor in modules/desktop/stylix), so we don't
  # duplicate those here.
  #
  # gnome-themes-extra is kept for compatibility with downstream GTK themes
  # that bypass Stylix's adw-gtk3 path. Small and harmless when unused.
  #
  # gtk-engine-murrine was removed from nixpkgs 2026-07-22 (unmaintained
  # upstream, depended on GTK2 -- pkgs.gtk-engine-murrine is now a `throw`,
  # not a package), so it can no longer be listed here at all. Every
  # third-party GTK theme that needed it is gone from nixpkgs for the same
  # reason (see pkgs/top-level/aliases.nix), so there's nothing left in this
  # tree that depends on it.
  environment.systemPackages = [
    pkgs.gnome-themes-extra # Adwaita and other base themes
  ];
}
