# environment.variables for the Wayland/Hyprland session.
{ config }:

{
  # XDG & Session
  # XDG_RUNTIME_DIR is intentionally not set here: pam_systemd already
  # exports it for every session before this file is ever consumed, and
  # NixOS environment.variables generates /etc/set-environment with keys
  # in alphabetical order, not declaration order. Re-declaring it here
  # would place its own `export` line after any earlier-sorted variable
  # that references `$XDG_RUNTIME_DIR`, so such a reference still cannot
  # rely on this file having set it. The two variables that reference it
  # (SSH_AUTH_SOCK and GNOME_KEYRING_CONTROL, in
  # ../../system/keyring/default.nix) therefore carry their own
  # `${XDG_RUNTIME_DIR:-/run/user/$(id -u)}` fallback instead.
  XDG_CURRENT_DESKTOP = "Hyprland";
  XDG_SESSION_DESKTOP = "Hyprland";
  XDG_SESSION_TYPE = "wayland";

  # Wayland backend support
  GDK_BACKEND = "wayland,x11,*";
  NIXOS_OZONE_WL = "1";
  ELECTRON_OZONE_PLATFORM_HINT = "auto";
  MOZ_ENABLE_WAYLAND = "1";
  OZONE_PLATFORM = "wayland";
  EGL_PLATFORM = "wayland";
  SDL_VIDEODRIVER = "wayland";

  # Qt configuration
  QT_QPA_PLATFORM = "wayland;xcb";
  QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
  QT_AUTO_SCREEN_SCALE_FACTOR = "1";

  # Theming: GTK_THEME, QT_STYLE_OVERRIDE, and QT_QPA_PLATFORMTHEME are
  # intentionally not set here. Stylix's gtk/qt home-manager targets own
  # them (see docs/architecture.md, "Stylix stays the single source of
  # truth"): GTK_THEME as an env var overrides settings.ini and would
  # silently defeat Stylix's colorScheme-driven GTK theme, and
  # QT_STYLE_OVERRIDE/QT_QPA_PLATFORMTHEME would race Stylix's own
  # home.sessionVariables/systemd.user.sessionVariables declarations of
  # the same vars through a different, unordered delivery path.

  # Cursor from hyprflake.style options
  XCURSOR_THEME = config.hyprflake.style.cursor.name;
  XCURSOR_SIZE = toString config.hyprflake.style.cursor.size;

  # Keyring & SSH: SSH_AUTH_SOCK, SSH_ASKPASS, and GNOME_KEYRING_CONTROL
  # are declared once, in ../../system/keyring/default.nix, not here.

  # Removed as dead, checked against Hyprland 0.57 / aquamarine 0.15, Electron's
  # documented env vars and the nixerator closure (no reader of any of them):
  # WLR_RENDERER_ALLOW_SOFTWARE (wlroots, aquamarine ignores it),
  # ELECTRON_{FORCE_DARK_MODE,ENABLE_DARK_MODE,USE_SYSTEM_THEME,
  # DISABLE_DEFAULT_MENU_BAR} (not real Electron variables; dark mode comes
  # from the GTK/portal color-scheme Stylix owns), CLUTTER_BACKEND (no Clutter
  # app installed), _JAVA_OPTIONS (no JDK; it also prints a banner on every
  # java invocation). To restore one, git revert the commit that removed it.

  # Misc
  NIXPKGS_ALLOW_UNFREE = "1";
}
