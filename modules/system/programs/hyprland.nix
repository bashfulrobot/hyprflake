{ config, lib, pkgs, inputs, ... }:

{
  # Hyprland system-level configuration
  # Enables Hyprland, installs packages, sets environment variables

  # Enable D-Bus for proper desktop session integration
  services.dbus.enable = true;

  # USB automounting for Nautilus
  services.udisks2.enable = true;
  services.gvfs.enable = true;

  # Hyprland with latest version from flake
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
    withUWSM = false;
  };

  # XDG Desktop Portal for screensharing
  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gtk
    ];
  };

  # Essential system packages
  environment.systemPackages = with pkgs; [
    # Hyprland utilities
    hyprpaper
    hyprpicker
    hyprpolkitagent
    hyprsunset

    # Wayland utilities
    wl-clipboard
    wl-clipboard-x11
    cliphist
    grim
    slurp
    hyprshot
    satty

    # System utilities
    brightnessctl
    pamixer
    playerctl
    pwvucontrol
    networkmanagerapplet
    blueman

    # File management
    nautilus
    nautilus-open-any-terminal
    file-roller
    ranger

    # Desktop utilities
    libnotify
    desktop-file-utils
    shared-mime-info
    xdotool
    wtype
    yad

    # Security & authentication
    gcr_4 # Modern GCR for keyring password prompts
    libsecret
    seahorse
    pinentry-all

    # Icon & theme support
    hicolor-icon-theme
    gtk3.out # for gtk-update-icon-cache
    bibata-cursors
    papirus-folders

    # System monitoring
    lm_sensors
    procps
    wirelesstools

    # Additional utilities
    annotator # Image annotation
  ];

  # Comprehensive Wayland/Hyprland environment variables
  environment.variables = {
    # XDG & Session
    XDG_RUNTIME_DIR = "/run/user/$UID";
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
    CLUTTER_BACKEND = "wayland";
    SDL_VIDEODRIVER = "wayland";

    # Qt configuration
    QT_QPA_PLATFORM = "wayland;xcb";
    QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
    QT_AUTO_SCREEN_SCALE_FACTOR = "1";

    # Theming
    GTK_THEME = "Adwaita:dark";
    QT_STYLE_OVERRIDE = "adwaita-dark";
    QT_QPA_PLATFORMTHEME = "gnome";

    # Cursor from hyprflake options
    XCURSOR_THEME = config.hyprflake.cursor.name;
    XCURSOR_SIZE = toString config.hyprflake.cursor.size;

    # Keyring & SSH
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/keyring/ssh";
    GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring";

    # Electron apps
    ELECTRON_FORCE_DARK_MODE = "1";
    ELECTRON_ENABLE_DARK_MODE = "1";
    ELECTRON_USE_SYSTEM_THEME = "1";
    ELECTRON_DISABLE_DEFAULT_MENU_BAR = "1";

    # Java applications
    _JAVA_OPTIONS = "-Dswing.aatext=true -Dawt.useSystemAAFontSettings=on";

    # Misc
    WLR_RENDERER_ALLOW_SOFTWARE = "1";
    NIXPKGS_ALLOW_UNFREE = "1";
  };

  # Security
  security.polkit.enable = true;

  # Bluetooth
  hardware.bluetooth.enable = true;
  services.blueman.enable = true;
}
