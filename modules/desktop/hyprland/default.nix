{ config, lib, pkgs, hyprflakeInputs, ... }:

let
  # Media control scripts with SwayOSD notifications
  hypr-media-play-pause = pkgs.writeShellApplication {
    name = "hypr-media-play-pause";
    runtimeInputs = [ pkgs.playerctl pkgs.swayosd ];
    text = ''
      playerctl play-pause
      sleep 0.2
      swayosd-client --custom-icon audio-x-generic \
        --custom-message "$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo 'Play/Pause')"
    '';
  };

  hypr-media-next = pkgs.writeShellApplication {
    name = "hypr-media-next";
    runtimeInputs = [ pkgs.playerctl pkgs.swayosd ];
    text = ''
      playerctl next
      sleep 0.3
      swayosd-client --custom-icon media-skip-forward \
        --custom-message "$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo 'Next')"
    '';
  };

  hypr-media-prev = pkgs.writeShellApplication {
    name = "hypr-media-prev";
    runtimeInputs = [ pkgs.playerctl pkgs.swayosd ];
    text = ''
      playerctl previous
      sleep 0.3
      swayosd-client --custom-icon media-skip-backward \
        --custom-message "$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo 'Previous')"
    '';
  };
in
{
  # Comprehensive Hyprland desktop environment configuration
  # Opinionated setup with extensive keybindings, window rules, and integrations

  # Enable D-Bus for proper desktop session integration
  services.dbus.enable = true;

  # Hyprland with latest version from flake
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    package = hyprflakeInputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    portalPackage = hyprflakeInputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
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
    # Hyprflake scripts
    hypr-media-play-pause
    hypr-media-next
    hypr-media-prev

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
    grimblast
    swappy

    # System utilities
    brightnessctl
    pamixer
    playerctl
    pavucontrol
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
    QT_QPA_PLATFORMTHEME = lib.mkDefault "qt5ct"; # Hyprland recommended

    # Cursor from hyprflake options
    XCURSOR_THEME = config.hyprflake.cursor.name;
    XCURSOR_SIZE = toString config.hyprflake.cursor.size;

    # Keyring & SSH
    # Using gcr-ssh-agent for keyring integration (same as nixcfg/GNOME)
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
    SSH_ASKPASS = lib.mkForce "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass";
    SSH_ASKPASS_REQUIRE = "prefer"; # Force graphical prompts when available
    GNOME_KEYRING_CONTROL = "$XDG_RUNTIME_DIR/keyring"; # Required for secret storage

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

  # Home Manager Hyprland configuration
  # This is where the actual Hyprland settings, keybinds, and rules live
  home-manager.sharedModules = [
    (_: {
      wayland.windowManager.hyprland = {
        enable = true;
        # Use packages from NixOS module to avoid conflicts
        package = null;
        portalPackage = null;
        xwayland.enable = true;
        systemd = {
          enable = !(config.programs.hyprland.withUWSM or false);
          variables = [ "--all" ];
        };

        settings = {
          # Variables
          "$mainMod" = "SUPER";
          "$term" = "${lib.getExe pkgs.kitty}";
          "$menu" = "${lib.getExe pkgs.rofi} -show drun";

          # Monitor configuration (default to auto)
          monitor = [ ",preferred,auto,1" ];

          # Input configuration
          input = {
            kb_layout = config.hyprflake.keyboard.layout;
            kb_variant = config.hyprflake.keyboard.variant;
            repeat_delay = 300;
            repeat_rate = 30;
            follow_mouse = 1;
            sensitivity = 0;
            force_no_accel = true;

            touchpad = {
              natural_scroll = true;
              disable_while_typing = true;
            };
          };

          # General window settings
          general = {
            gaps_in = 4;
            gaps_out = 8;
            border_size = 2;
            # Border colors managed by stylix
            # "col.active_border" = lib.mkDefault "rgba(89b4faff) rgba(cba6f7ff) 45deg";
            # "col.inactive_border" = "rgba(${config.lib.stylix.colors.base00}88)";
            resize_on_border = true;
            layout = "dwindle";
          };

          # Decoration settings
          decoration = {
            rounding = 8;

            blur = {
              enabled = true;
              size = 3;
              passes = 1;
              new_optimizations = true;
            };

            shadow = {
              enabled = true;
              range = 4;
              render_power = 3;
            };
          };

          # Animation settings
          animations = {
            enabled = true;
            bezier = "myBezier, 0.05, 0.9, 0.1, 1.05";
            animation = [
              "windows, 1, 7, myBezier"
              "windowsOut, 1, 7, default, popin 80%"
              "border, 1, 10, default"
              "borderangle, 1, 8, default"
              "fade, 1, 7, default"
              "workspaces, 1, 6, default"
            ];
          };

          # Dwindle layout
          dwindle = {
            pseudotile = true;
            preserve_split = true;
          };

          # Master layout
          master = {
            new_status = "master";
          };

          # Gestures (Hyprland 0.51+ syntax)
          gestures = {
            gesture = [
              "3, horizontal, workspace"
              "4, horizontal, workspace"
            ];
          };

          # Miscellaneous settings
          misc = {
            disable_hyprland_logo = true;
            disable_splash_rendering = true;
            force_default_wallpaper = 0;
            vfr = true;
          };

          # Startup applications
          exec-once = [
            "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP"
            # waybar is started by systemd service (see waybar module)
            "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store"
            "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store"
            "blueman-applet"
            "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass"
          ];

          # Keybindings - Applications
          bind = [
            # Launch applications
            "$mainMod, RETURN, exec, $term"
            "$mainMod, D, exec, $menu"
            "$mainMod, E, exec, ${lib.getExe pkgs.nautilus}"
            "$mainMod, N, exec, swaync-client -t -sw"

            # Window management
            "$mainMod, Q, killactive,"
            "$mainMod SHIFT, Q, exit,"
            "$mainMod, V, togglefloating,"
            "$mainMod, P, pseudo,"
            "$mainMod, J, togglesplit,"
            "$mainMod, F, fullscreen, 0"

            # Move focus
            "$mainMod, left, movefocus, l"
            "$mainMod, right, movefocus, r"
            "$mainMod, up, movefocus, u"
            "$mainMod, down, movefocus, d"

            # Move windows
            "$mainMod SHIFT, left, movewindow, l"
            "$mainMod SHIFT, right, movewindow, r"
            "$mainMod SHIFT, up, movewindow, u"
            "$mainMod SHIFT, down, movewindow, d"

            # Switch workspaces
            "$mainMod, 1, workspace, 1"
            "$mainMod, 2, workspace, 2"
            "$mainMod, 3, workspace, 3"
            "$mainMod, 4, workspace, 4"
            "$mainMod, 5, workspace, 5"
            "$mainMod, 6, workspace, 6"
            "$mainMod, 7, workspace, 7"
            "$mainMod, 8, workspace, 8"
            "$mainMod, 9, workspace, 9"
            "$mainMod, 0, workspace, 10"

            # Move active window to workspace
            "$mainMod SHIFT, 1, movetoworkspace, 1"
            "$mainMod SHIFT, 2, movetoworkspace, 2"
            "$mainMod SHIFT, 3, movetoworkspace, 3"
            "$mainMod SHIFT, 4, movetoworkspace, 4"
            "$mainMod SHIFT, 5, movetoworkspace, 5"
            "$mainMod SHIFT, 6, movetoworkspace, 6"
            "$mainMod SHIFT, 7, movetoworkspace, 7"
            "$mainMod SHIFT, 8, movetoworkspace, 8"
            "$mainMod SHIFT, 9, movetoworkspace, 9"
            "$mainMod SHIFT, 0, movetoworkspace, 10"

            # Special workspace (scratchpad)
            "$mainMod, S, togglespecialworkspace, magic"
            "$mainMod SHIFT, S, movetoworkspace, special:magic"

            # Scroll through workspaces
            "$mainMod, mouse_down, workspace, e+1"
            "$mainMod, mouse_up, workspace, e-1"

            # Screenshots
            ", Print, exec, ${lib.getExe pkgs.grimblast} copy area"
            "SHIFT, Print, exec, ${lib.getExe pkgs.grimblast} copy screen"

            # Lock screen
            "$mainMod, L, exec, loginctl lock-session"

            # Media control with SwayOSD song display
            ", XF86AudioPlay, exec, hypr-media-play-pause"
            ", XF86AudioPause, exec, hypr-media-play-pause"
            ", XF86AudioNext, exec, hypr-media-next"
            ", XF86AudioPrev, exec, hypr-media-prev"
          ];

          # Mouse bindings
          bindm = [
            "$mainMod, mouse:272, movewindow"
            "$mainMod, mouse:273, resizewindow"
          ];

          # Repeatable bindings for volume and brightness (swayosd)
          bindel = [
            ", XF86AudioRaiseVolume, exec, swayosd-client --output-volume raise"
            ", XF86AudioLowerVolume, exec, swayosd-client --output-volume lower"
            ", XF86MonBrightnessUp, exec, swayosd-client --brightness raise"
            ", XF86MonBrightnessDown, exec, swayosd-client --brightness lower"
          ];

          # Locked bindings for toggles (swayosd)
          bindl = [
            ", XF86AudioMute, exec, swayosd-client --output-volume mute-toggle"
            ", XF86AudioMicMute, exec, swayosd-client --input-volume mute-toggle"
          ];

          # Window rules (commented out - TODO: fix and re-enable)
          # windowrule = [
          #   # Opacity rules (active inactive)
          #   "opacity ${toString config.hyprflake.opacity.applications} ${toString config.hyprflake.opacity.applications}, class:code|codium"
          #   "opacity ${toString config.hyprflake.opacity.applications} ${toString config.hyprflake.opacity.applications}, class:chromium|firefox"
          #   "opacity ${toString config.hyprflake.opacity.terminal} ${toString config.hyprflake.opacity.terminal}, class:kitty|alacritty"

          #   # Float rules
          #   "float, class:pavucontrol|blueman-manager"
          #   "float, class:nm-connection-editor"
          #   "float, title:Picture-in-Picture"

          #   # Pin PiP
          #   "pin, title:Picture-in-Picture"
          # ];
        };
      };
    })
  ];
}
