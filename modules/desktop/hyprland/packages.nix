# environment.systemPackages for the Hyprland desktop.
{ pkgs, hypr-equalize-windows, hypr-record-region, tv-workspace }:

with pkgs; [
  # Hyprflake scripts
  hypr-equalize-windows
  hypr-record-region
  tv-workspace

  # Hyprland utilities
  # hyprpicker removed: screen color picking is dms ipc color-picker
  #   (SUPER+SHIFT+C), which copies the hex to the clipboard.
  # hyprsunset removed: night mode / color temperature is dms ipc night
  #   (configured in the DMS control center, with time/location automation).
  hyprpolkitagent

  # Wayland utilities
  wl-clipboard
  wl-clipboard-x11
  cliphist
  grim
  slurp
  hyprshot
  satty
  wf-recorder

  # System utilities
  # brightnessctl/pamixer removed: brightness and volume are driven by
  # `dms ipc brightness`/`dms ipc audio` under DankMaterialShell.
  # networkmanagerapplet removed: network UI lives in the DMS control
  # center; NetworkManager remains as the backend.
  # playerctl removed: media keys use dms ipc mpris.
  # pwvucontrol/impala removed: the DMS 1.5-beta control center now covers
  # both.
  # Its audio output detail ships a per-application mixer (per-app volume +
  # mute over PipeWire sink-input streams), and its network detail handles
  # WiFi scan/connect/disconnect/forget for normal use. Re-checked against
  # DMS 1.5-beta on 2026-06-09 (flake.lock pins DankMaterialShell at rev
  # 335c5b4); see docs/architecture.md. (DMS still lacks
  # per-app input/recording volume and per-stream device routing, the two
  # niche pwvucontrol features; re-add it if either is needed.)
  # blueman removed: DMS bundles its own bluetooth pairing agent + control
  # center UI; hardware.bluetooth stays enabled for the stack itself.

  # File management
  nautilus
  nautilus-open-any-terminal
  file-roller
  ranger
  libheif # HEIC image format support
  libheif.out # HEIC thumbnails in Nautilus

  # Desktop utilities
  libnotify
  desktop-file-utils
  shared-mime-info
  xdotool
  wtype
  yad
  dconf
  dconf2nix
  dconf-editor

  # Security & authentication
  # Note: keyring packages (gcr_4, libsecret, seahorse, pinentry-gnome3) are in system/keyring module

  # Icon & theme support
  hicolor-icon-theme
  gtk3.out # for gtk-update-icon-cache
  bibata-cursors
  papirus-folders

  # Fonts
  nerd-fonts.iosevka

  # System monitoring
  lm_sensors
  procps
  wirelesstools

  # Additional utilities
  annotator # Image annotation
]
