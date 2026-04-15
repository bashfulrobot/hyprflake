{ config
, lib
, pkgs
, hyprflakeInputs
, ...
}:

let
  termCfg = config.hyprflake.desktop.terminal;

  # Media control scripts with SwayOSD notifications
  hypr-media-play-pause = pkgs.writeShellApplication {
    name = "hypr-media-play-pause";
    runtimeInputs = [
      pkgs.playerctl
      pkgs.swayosd
    ];
    text = ''
      playerctl play-pause
      sleep 0.2
      swayosd-client --custom-icon audio-x-generic \
        --custom-message "$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo 'Play/Pause')"
    '';
  };

  hypr-media-next = pkgs.writeShellApplication {
    name = "hypr-media-next";
    runtimeInputs = [
      pkgs.playerctl
      pkgs.swayosd
    ];
    text = ''
      playerctl next
      sleep 0.3
      swayosd-client --custom-icon media-skip-forward \
        --custom-message "$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo 'Next')"
    '';
  };

  hypr-mic-mute-toggle = pkgs.writeShellApplication {
    name = "hypr-mic-mute-toggle";
    runtimeInputs = [
      pkgs.wireplumber
      pkgs.swayosd
      pkgs.gnugrep
    ];
    text = ''
      wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
      if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
        swayosd-client --custom-icon source-volume-muted-symbolic \
          --custom-message "Mic Muted"
      else
        swayosd-client --custom-icon source-volume-high-symbolic \
          --custom-message "Mic On"
      fi
    '';
  };

  hypr-media-prev = pkgs.writeShellApplication {
    name = "hypr-media-prev";
    runtimeInputs = [
      pkgs.playerctl
      pkgs.swayosd
    ];
    text = ''
      playerctl previous
      sleep 0.3
      swayosd-client --custom-icon media-skip-backward \
        --custom-message "$(playerctl metadata --format '{{artist}} - {{title}}' 2>/dev/null || echo 'Previous')"
    '';
  };

  hypr-equalize-windows = pkgs.writeShellApplication {
    name = "hypr-equalize-windows";
    runtimeInputs = [ pkgs.jq ];
    text = ''
      active=$(hyprctl activewindow -j)
      active_addr=$(echo "$active" | jq -r '.address')
      ws_id=$(echo "$active" | jq -r '.workspace.id')

      addrs=$(hyprctl clients -j | jq -r --argjson ws "$ws_id" \
        '.[] | select(.workspace.id == $ws) | .address')

      batch=""
      for addr in $addrs; do
        batch+="dispatch focuswindow address:$addr; dispatch splitratio exact 1.0; "
      done

      hyprctl --batch "$batch dispatch focuswindow address:$active_addr"
    '';
  };

  hypr-record-region = pkgs.writeShellApplication {
    name = "hypr-record-region";
    runtimeInputs = [
      pkgs.wf-recorder
      pkgs.slurp
      pkgs.coreutils
      pkgs.libnotify
    ];
    text = ''
      if pgrep -x wf-recorder > /dev/null; then
        pkill wf-recorder
        notify-send -i media-record -u normal "Recording stopped" "Saved to ~/Videos"
      else
        mkdir -p "$HOME/Videos"
        outfile="$HOME/Videos/recording-$(date +%Y%m%d-%H%M%S).mp4"
        notify-send -i media-record -u critical "Recording started" "CTRL ALT R to stop"
        wf-recorder -g "$(slurp)" -f "$outfile"
      fi
    '';
  };
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
      description = "Terminal emulator package for keybinds, rofi, and nautilus.";
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

      # Bluetooth
      blueman.enable = true;
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
        withUWSM = false;
      };
    };

    # Nautilus enhancements
    # Enable HEIC image thumbnails
    environment = {
      pathsToLink = [ "share/thumbnailers" ];

      # Essential system packages
      systemPackages = with pkgs; [
        # Hyprflake scripts
        hypr-media-play-pause
        hypr-media-next
        hypr-media-prev
        hypr-mic-mute-toggle
        hypr-equalize-windows
        hypr-record-region

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
        wf-recorder

        # System utilities
        brightnessctl
        pamixer
        playerctl
        pwvucontrol
        networkmanagerapplet
        rofi-network-manager
        qrencode # For rofi-network-manager QR code sharing
        impala # WiFi TUI
        blueman

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
      ];

      # Comprehensive Wayland/Hyprland environment variables
      variables = {
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

        # Cursor from hyprflake.style options
        XCURSOR_THEME = config.hyprflake.style.cursor.name;
        XCURSOR_SIZE = toString config.hyprflake.style.cursor.size;

        # Keyring & SSH
        # Using gcr-ssh-agent for keyring integration (same as nixcfg/GNOME)
        SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
        SSH_ASKPASS = lib.mkForce "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass";
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
    };

    # Add GStreamer plugins to Nautilus for audio/video file properties
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
      (
        { osConfig, ... }:
        {
          # Configure xdg-desktop-portal-hyprland to fix Chrome screen sharing double-prompt
          # https://www.ssp.sh/brain/screen-sharing-on-wayland-hyprland-with-chrome/
          xdg.configFile."hypr/xdph.conf".text = ''
            screencopy {
              allow_token_by_default = true
            }
          '';

          # Hyprpaper configuration with new block syntax (v0.53.0+)
          # Stylix/Home Manager still generate old one-line syntax which is broken
          # Tracking: https://github.com/nix-community/home-manager/issues/8482
          # See also: https://wiki.hypr.land/Hypr-Ecosystem/hyprpaper/
          # See also: https://www.reddit.com/r/archlinux/comments/1pzy41t/hyprpaper_not_working/
          xdg.configFile."hypr/hyprpaper.conf".text = ''
            preload = ${osConfig.stylix.image}
            splash = false

            wallpaper {
              monitor =
              path = ${osConfig.stylix.image}
            }
          '';

          # Enable hyprpaper via systemd user service but keep our manual config.
          # Stylix/Home Manager still generate old syntax, so keep settings empty.
          services.hyprpaper = {
            enable = true;
            settings = lib.mkForce { };
          };

          wayland.windowManager.hyprland = {
            enable = true;
            # Use packages from NixOS module to avoid conflicts
            package = null;
            portalPackage = null;
            systemd = {
              enable = !(config.programs.hyprland.withUWSM or false);
              variables = [ "--all" ];
            };

            settings = {
              # Variables
              "$mainMod" = "SUPER";
              "$term" = "${lib.getExe termCfg.package}";
              "$menu" = "${lib.getExe pkgs.rofi} -show drun -theme ~/.config/rofi/launchers/type-3/style-1.rasi";

              # Monitor configuration (default to auto)
              monitor = [ ",preferred,auto,1" ];

              # Input configuration
              input = {
                kb_layout = osConfig.hyprflake.desktop.keyboard.layout;
                kb_variant = osConfig.hyprflake.desktop.keyboard.variant;
                repeat_delay = 300;
                repeat_rate = 30;
                # Mode 2 = loose focus: click-to-focus for windows, but hover works in popups (hyprshell)
                follow_mouse = 2;
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
                key_press_enables_dpms = true;
                mouse_move_enables_dpms = true;
                vfr = true;
              };

              # Startup applications
              exec-once = [
                "dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP DISPLAY HYPRLAND_INSTANCE_SIGNATURE"
                # waybar is started by systemd service (see waybar module)
                "${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store"
                "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store"
                "${pkgs.gcr_4}/libexec/gcr4-ssh-askpass"
              ];

              # Keybindings - Applications
              bind = [
                # Launch applications
                "$mainMod, RETURN, exec, $term"
                "$mainMod, T, exec, $term"
                "$mainMod, Space, exec, $menu"
                "$mainMod, E, exec, ${lib.getExe pkgs.nautilus}"
                "$mainMod, B, exec, xdg-open https://"
                "$mainMod, N, exec, swaync-client -t -sw"
                "$mainMod, I, exec, rofi-network-manager"
                "$mainMod, period, exec, ${lib.getExe pkgs.rofimoji}"

                # Window management
                "$mainMod, Q, killactive,"
                "$mainMod SHIFT, Q, exit,"
                "$mainMod, V, togglefloating,"
                "$mainMod, P, exec, wlogout -b 3 -c 60 -r 60"
                "$mainMod, J, layoutmsg, togglesplit"
                "$mainMod SHIFT, E, exec, hypr-equalize-windows"
                "$mainMod, F, fullscreen, 0"
                "$mainMod, R, submap, resize"

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
                ", Print, exec, ${lib.getExe pkgs.hyprshot} -m region --raw | ${lib.getExe pkgs.satty} -f -"
                "CTRL ALT, P, exec, ${lib.getExe pkgs.hyprshot} -m region --clipboard-only"
                "CTRL ALT SHIFT, P, exec, ${lib.getExe pkgs.hyprshot} -m region --raw | ${lib.getExe pkgs.satty} -f -"
                "SHIFT, Print, exec, ${lib.getExe pkgs.hyprshot} -m output --raw | ${lib.getExe pkgs.satty} -f -"

                # Screen recording
                "CTRL ALT, R, exec, hypr-record-region"

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
                ", XF86AudioMicMute, exec, hypr-mic-mute-toggle"
              ];

            };

            # Resize submap configuration
            # Use binde for repeatable resize actions (hold key to keep resizing)
            # Window rules are here (not in settings.windowrule) so consumers can
            # define windowrule in any format without merge conflicts
            extraConfig = ''
              # Window rules - opacity
              windowrule = opacity ${toString osConfig.hyprflake.style.opacity.applications} ${toString osConfig.hyprflake.style.opacity.applications}, match:class code|codium
              windowrule = opacity ${toString osConfig.hyprflake.style.opacity.applications} ${toString osConfig.hyprflake.style.opacity.applications}, match:class chromium|firefox
              windowrule = opacity ${toString osConfig.hyprflake.style.opacity.terminal} ${toString osConfig.hyprflake.style.opacity.terminal}, match:class ${termCfg.name}

              # Window rules - float & pin
              windowrule = float on, match:class pwvucontrol|blueman-manager
              windowrule = float on, match:class nm-connection-editor
              windowrule = float on, match:title Picture-in-Picture
              windowrule = pin on, match:title Picture-in-Picture

              submap = resize

              # Resize with vim keys
              binde = , h, resizeactive, -50 0
              binde = , l, resizeactive, 50 0
              binde = , k, resizeactive, 0 -50
              binde = , j, resizeactive, 0 50

              # Resize with arrow keys
              binde = , left, resizeactive, -50 0
              binde = , right, resizeactive, 50 0
              binde = , up, resizeactive, 0 -50
              binde = , down, resizeactive, 0 50

              # Exit resize submap
              bind = , escape, submap, reset
              bind = , return, submap, reset

              submap = reset

              # Allow dynamic user overrides from conf.d
              source = ~/.config/hypr/conf.d/*.conf
            '';
          };

          # GNOME dconf settings
          dconf.settings = with hyprflakeInputs.home-manager.lib.hm.gvariant; {
            "org/gnome/desktop/wm/preferences" = {
              button-layout = "appmenu"; # Remove close/minimize/maximize buttons
            };
          };
        }
      )
    ];
  };
}
