{ config, lib, pkgs, hyprflakeInputs, ... }:

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
    gcr_4  # Modern GCR for keyring password prompts
    libsecret
    seahorse
    pinentry-all

    # Icon & theme support
    hicolor-icon-theme
    gtk3.out  # for gtk-update-icon-cache
    bibata-cursors
    papirus-folders

    # System monitoring
    lm_sensors
    procps
    wirelesstools

    # Additional utilities
    annotator  # Image annotation
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
    QT_QPA_PLATFORMTHEME = lib.mkDefault "qt5ct";  # Hyprland recommended

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

  # Home Manager Hyprland configuration
  # This is where the actual Hyprland settings, keybinds, and rules live
  home-manager.sharedModules = [
    (_: {
      wayland.windowManager.hyprland = {
        enable = true;
        package = hyprflakeInputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
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

          # Gestures
          gestures = {
            workspace_swipe = true;
            workspace_swipe_fingers = 3;
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
            "waybar"
            "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store"
            "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store"
            "nm-applet --indicator"
            "blueman-applet"
            "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass"
          ];

          # Keybindings - Applications
          bind = [
            # Launch applications
            "$mainMod, RETURN, exec, $term"
            "$mainMod, D, exec, $menu"
            "$mainMod, E, exec, ${lib.getExe pkgs.nautilus}"

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

            # Volume control
            ", XF86AudioRaiseVolume, exec, ${lib.getExe pkgs.pamixer} -i 5"
            ", XF86AudioLowerVolume, exec, ${lib.getExe pkgs.pamixer} -d 5"
            ", XF86AudioMute, exec, ${lib.getExe pkgs.pamixer} -t"

            # Brightness control
            ", XF86MonBrightnessUp, exec, ${lib.getExe pkgs.brightnessctl} set +5%"
            ", XF86MonBrightnessDown, exec, ${lib.getExe pkgs.brightnessctl} set 5%-"

            # Media control
            ", XF86AudioPlay, exec, ${lib.getExe pkgs.playerctl} play-pause"
            ", XF86AudioPause, exec, ${lib.getExe pkgs.playerctl} play-pause"
            ", XF86AudioNext, exec, ${lib.getExe pkgs.playerctl} next"
            ", XF86AudioPrev, exec, ${lib.getExe pkgs.playerctl} previous"
          ];

          # Mouse bindings
          bindm = [
            "$mainMod, mouse:272, movewindow"
            "$mainMod, mouse:273, resizewindow"
          ];

          # Window rules
          windowrulev2 = [
            # Opacity rules
            "opacity ${toString config.hyprflake.opacity.applications}, class:^(code|codium)$"
            "opacity ${toString config.hyprflake.opacity.applications}, class:^(chromium|firefox)$"
            "opacity ${toString config.hyprflake.opacity.terminal}, class:^(kitty|alacritty)$"

            # Float rules
            "float, class:^(pavucontrol|blueman-manager)$"
            "float, class:^(nm-connection-editor)$"
            "float, title:^(Picture-in-Picture)$"

            # Pin PiP
            "pin, title:^(Picture-in-Picture)$"
          ];
        };
      };
    })
  ];
}
