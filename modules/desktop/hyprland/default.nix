{ config
, lib
, pkgs
, hyprflakeInputs
, ...
}:

let
  termCfg = config.hyprflake.desktop.terminal;

  # Media keys are handled directly by DankMaterialShell over MPRIS
  # (dms ipc call mpris ...), so no playerctl wrapper scripts are needed.

  scripts = import ./scripts.nix { inherit pkgs; };
  inherit (scripts) hypr-equalize-windows hypr-record-region tv-workspace;
in
{
  # Comprehensive Hyprland desktop environment configuration
  # Opinionated setup with extensive keybindings, window rules, and integrations

  # keyboard options are defined here but also consumed by display-manager module
  options.hyprflake.desktop.keyboard = {
    layout = lib.mkOption {
      type = lib.types.str;
      default = "us";
      example = "us,de";
      description = ''
        Keyboard layout(s) to use system-wide.
        Multiple layouts can be specified separated by commas.
        Examples: "us", "us,de", "gb", "dvorak"
      '';
    };

    variant = lib.mkOption {
      type = lib.types.str;
      default = "";
      example = "colemak";
      description = ''
        Keyboard variant for the layout.
        Examples: "colemak", "dvorak", "altgr-intl"
        Leave empty for default variant.
      '';
    };
  };

  options.hyprflake.desktop.terminal = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.kitty;
      description = "Terminal emulator package for keybinds and nautilus.";
    };
    name = lib.mkOption {
      type = lib.types.str;
      default = lib.getName config.hyprflake.desktop.terminal.package;
      description = "Terminal name string for nautilus-open-any-terminal and window rules.";
    };
  };

  config = {
    # Enable D-Bus for proper desktop session integration
    services = {
      dbus.enable = true;

      # PipeWire for screen sharing and audio
      pipewire = {
        enable = true;
        pulse.enable = true;
      };

      # USB automounting and file system support for Nautilus
      # udisks2: Disk management daemon for automounting USB drives
      # gvfs: Virtual filesystem for trash, remote locations, etc.
      # Note: If automounting fails, try the workaround from https://github.com/NixOS/nixpkgs/issues/412131
      #       services.gvfs.package = lib.mkForce pkgs.gnome.gvfs;
      udisks2.enable = true;
      gvfs.enable = true;
    };

    # Home Manager's dconfSettings activation step runs dconf over a private
    # dbus-run-session. That bus autostarts gvfsd and gvfsd-fuse, and
    # gvfsd-fuse segfaults (g_mount_tracker_set_property) on every boot. Force
    # GLib's local VFS for the activation unit only so it never spawns them;
    # the real session's gvfs is unaffected.
    systemd.services = lib.mkIf (config.hyprflake.user.username != null) {
      "home-manager-${config.hyprflake.user.username}".environment.GIO_USE_VFS = "local";
    };

    # Enable dconf for GNOME application settings
    programs = {
      dconf.enable = true;

      # Configure Nautilus "Open in Terminal" extension
      nautilus-open-any-terminal = {
        enable = true;
        terminal = termCfg.name;
      };

      # Hyprland from nixpkgs (stable, tested releases)
      hyprland = {
        enable = true;
        xwayland.enable = true;
        # Use nixpkgs versions - no need to specify package/portalPackage

        # Manage the session with UWSM. This is required by the greetd
        # (DankGreeter) login path, not optional polish. greetd is a minimal
        # login manager: unlike GDM it does not set up the systemd user
        # graphical session, import the environment, or pick a session for the
        # user. DankGreeter offers both wayland-sessions the Hyprland package
        # ships (hyprland.desktop and hyprland-uwsm.desktop) and, with no saved
        # choice, defaults to the alphabetically-first one, which is the UWSM
        # variant ("-" sorts before "."). That session runs `uwsm start`, so
        # UWSM must be enabled or its user units (wayland-session-bindpid@) are
        # missing, `systemctl --user start` returns 5, the session dies in under
        # a second, and greetd respawns the greeter in a login crash-loop (and
        # DMS never reaches graphical-session.target, so the wallpaper never
        # paints). withUWSM = true makes nixpkgs enable programs.uwsm and install
        # those units, so UWSM provides the per-session systemd integration GDM
        # used to. The home-manager hyprland systemd integration below keys off
        # this flag and turns itself off, letting UWSM own the session.
        withUWSM = true;
      };
    };

    # hyprpolkitagent ships WantedBy=graphical-session.target, so it auto-starts
    # for every Wayland session — including the greetd greeter session. It then
    # tries to bind to the Hyprland wl_display, can fail, and ABRTs in a restart
    # loop that tears the greeter down (blank login screen). Same class of bug as
    # nixpkgs#347651 for hypridle; canonical fix is still unmerged
    # (nixpkgs#355416). Gate on the greetd `greeter` group rather than
    # XDG_SESSION_DESKTOP so it works without UWSM — the greetd greeter runs as
    # user `greeter` (primary group `greeter`), real users do not.
    systemd.user.services.hyprpolkitagent.unitConfig.ConditionGroup = "!greeter";

    # Nautilus enhancements
    # Enable HEIC image thumbnails
    environment = {
      pathsToLink = [ "share/thumbnailers" ];

      # Essential system packages
      systemPackages = import ./packages.nix {
        inherit pkgs hypr-equalize-windows hypr-record-region tv-workspace;
      };

      # Comprehensive Wayland/Hyprland environment variables
      variables = import ./session-variables.nix { inherit config; };
    };

    # Add GStreamer plugins to Nautilus for audio/video file properties
    #
    # The earlier glaze 7.2.0 pin for hyprland is gone. nixpkgs now relaxes
    # hyprland's glaze version check itself (pkgs/by-name/hy/hyprland/package.nix
    # replaces "glaze 7...<8" with "glaze"), and the pin's patched glaze source
    # no longer built against nixpkgs' glaze patches (2026-11-11 nixpkgs).
    nixpkgs.overlays = [
      (_final: prev: {
        nautilus = prev.nautilus.overrideAttrs (old: {
          buildInputs =
            old.buildInputs
            ++ (with pkgs.gst_all_1; [
              gst-plugins-good
              gst-plugins-bad
            ]);
        });
      })
    ];

    # XDG Desktop Portal for screensharing
    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-hyprland # Hyprland screen sharing, window picker
        xdg-desktop-portal-gtk # GTK file choosers, settings
      ];
      # Set portal priority to prevent double window picker
      config = {
        hyprland = {
          default = [
            "hyprland"
            "gtk"
          ];
        };
      };
    };

    # Security
    security.polkit.enable = true;

    # Bluetooth
    hardware.bluetooth.enable = true;

    # Home Manager Hyprland configuration
    # This is where the actual Hyprland settings, keybinds, and rules live
    home-manager.sharedModules = [
      (import ./home.nix { inherit config lib pkgs hyprflakeInputs termCfg; })
      ./extra-lua.nix
    ];
  };
}
