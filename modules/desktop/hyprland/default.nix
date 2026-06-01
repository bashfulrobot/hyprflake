{ config
, lib
, pkgs
, hyprflakeInputs
, ...
}:

let
  termCfg = config.hyprflake.desktop.terminal;

  # Media control scripts. DankMaterialShell shows its own media/audio OSD
  # via MPRIS, so these just drive playerctl (no swayosd).
  hypr-media-play-pause = pkgs.writeShellApplication {
    name = "hypr-media-play-pause";
    runtimeInputs = [ pkgs.playerctl ];
    text = "playerctl play-pause";
  };

  hypr-media-next = pkgs.writeShellApplication {
    name = "hypr-media-next";
    runtimeInputs = [ pkgs.playerctl ];
    text = "playerctl next";
  };

  hypr-media-prev = pkgs.writeShellApplication {
    name = "hypr-media-prev";
    runtimeInputs = [ pkgs.playerctl ];
    text = "playerctl previous";
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

    # hyprpolkitagent ships WantedBy=graphical-session.target, so it auto-starts
    # for every Wayland session — including GDM's greeter. It then tries to
    # bind to the Hyprland wl_display, fails, and ABRTs in a restart loop that
    # tears the greeter down (blank login screen). Same class of bug as
    # nixpkgs#347651 for hypridle; canonical fix is still unmerged
    # (nixpkgs#355416). Gate on the gdm group rather than XDG_SESSION_DESKTOP
    # so it works without UWSM — gdm-greeter and gdm-greeter-{1..4} all share
    # primary group gdm, real users do not.
    systemd.user.services.hyprpolkitagent.unitConfig.ConditionGroup = "!gdm";

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
        hypr-equalize-windows
        hypr-record-region

        # Hyprland utilities
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

          # Wallpaper is owned by DankMaterialShell: the Stylix
          # dank-material-shell target sets session.wallpaperPath from
          # config.stylix.image and DMS renders it. hyprpaper is retired.

          wayland.windowManager.hyprland =
            let
              # Strings used in keyspecs / dispatcher commands. Preconcatenated
              # in Nix so the Lua serializer sees plain string literals — the
              # Lua VM does no further substitution.
              mod = "SUPER";
              term = lib.getExe termCfg.package;

              # mkLuaInline alias to keep the bind list compact.
              luaInline = lib.generators.mkLuaInline;

              # Helpers for building hl.bind entries with mandatory descriptions.
              # Descriptions populate Hyprland's bind table description field,
              # which the shortcuts-viewer surfaces in its HTML cheat-sheet
              # (the raw "__lua <ref>" handler/arg pair is meaningless to humans).
              mkBind = key: dispatcher: desc:
                { _args = [ key dispatcher { description = desc; } ]; };
              mkBindOpts = key: dispatcher: opts: desc:
                { _args = [ key dispatcher (opts // { description = desc; }) ]; };

              # Build one workspace/move pair for SUPER+<n> / SUPER+SHIFT+<n>.
              workspaceBinds = lib.concatMap
                (i:
                  let key = if i == 10 then "0" else toString i; in
                  [
                    (mkBind "${mod} + ${key}"
                      (luaInline ''hl.dsp.focus({ workspace = ${toString i} })'')
                      "Workspace ${toString i}")
                    (mkBind "${mod} + SHIFT + ${key}"
                      (luaInline ''hl.dsp.window.move({ workspace = ${toString i} })'')
                      "Move active window to workspace ${toString i}")
                  ]
                )
                (lib.range 1 10);
            in
            {
              enable = true;
              # Use the Lua config manager. It is the repo standard: the
              # conf.d loader below and downstream consumers emit `hl.*`
              # Lua snippets. (Originally adopted for hyprshell's runtime
              # `eval hl.bind`; hyprshell is gone but Lua stays.)
              configType = "lua";
              # Use packages from NixOS module to avoid conflicts
              package = null;
              portalPackage = null;
              systemd = {
                enable = !(config.programs.hyprland.withUWSM or false);
                variables = [ "--all" ];
              };

              settings = {
                # `hl.monitor({output=..., mode=..., ...})` per monitor.
                # NOT inside `hl.config` — monitor is not a config key; it
                # has its own dedicated Lua function. Use a list so consumers
                # can append rules with `lib.mkAfter`.
                monitor = [
                  {
                    output = "";
                    mode = "preferred";
                    position = "auto";
                    scale = "auto";
                  }
                ];

                # Everything below is wrapped in `hl.config({...})` because
                # the attribute name is `config`. Stylix and other modules
                # contribute extra keys under here too (e.g. `general.col.*`,
                # `decoration.*` colors). The Lua serializer's hl.config
                # walker maps nested table keys to canonical `section.field`
                # config names — and `:` → `.` / `-` → `_` normalisation
                # means stylix's `["col.active_border"]` form still works.
                config = {
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

                  general = {
                    gaps_in = 4;
                    gaps_out = 8;
                    border_size = 2;
                    # Border colors managed by stylix
                    resize_on_border = true;
                    layout = "dwindle";
                  };

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

                  animations = {
                    enabled = true;
                  };

                  dwindle = {
                    preserve_split = true;
                  };

                  master = {
                    new_status = "master";
                  };

                  misc = {
                    disable_hyprland_logo = true;
                    disable_splash_rendering = true;
                    force_default_wallpaper = 0;
                    key_press_enables_dpms = true;
                    mouse_move_enables_dpms = true;
                  };
                };

                # `hl.curve(name, {type=..., points={...}})` defines a bezier
                # or spring curve. The hyprlang form was
                # `bezier = myBezier, 0.05, 0.9, 0.1, 1.05`.
                curve = {
                  _args = [
                    "myBezier"
                    (luaInline ''{ type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } }'')
                  ];
                };

                # One `hl.animation({...})` per element. Each hyprlang line
                # `<leaf>, <enabled>, <speed>, <curve>[, <style>]` maps below.
                animation = [
                  { leaf = "windows"; enabled = true; speed = 7; bezier = "myBezier"; }
                  { leaf = "windowsOut"; enabled = true; speed = 7; bezier = "default"; style = "popin 80%"; }
                  { leaf = "border"; enabled = true; speed = 10; bezier = "default"; }
                  { leaf = "borderangle"; enabled = true; speed = 8; bezier = "default"; }
                  { leaf = "fade"; enabled = true; speed = 7; bezier = "default"; }
                  { leaf = "workspaces"; enabled = true; speed = 6; bezier = "default"; }
                ];

                # `hl.gesture({...})` per finger count.
                gesture = [
                  { fingers = 3; direction = "horizontal"; action = "workspace"; }
                  { fingers = 4; direction = "horizontal"; action = "workspace"; }
                ];

                # `hl.on("hyprland.start", function() ... end)` is the
                # exec-once equivalent. As a list so other modules can append
                # their own startup hooks via lib.mkAfter without clobbering.
                # NB: home-manager already auto-injects an `hl.on` hook that
                # runs `dbus-update-activation-environment --systemd --all`
                # plus the systemd hyprland-session.target restart — don't
                # duplicate it here.
                on = [
                  {
                    _args = [
                      "hyprland.start"
                      (luaInline ''
                        function()
                          hl.exec_cmd("${pkgs.wl-clipboard}/bin/wl-paste --type text --watch ${pkgs.cliphist}/bin/cliphist store")
                          hl.exec_cmd("${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store")
                          hl.exec_cmd("${pkgs.gcr_4}/libexec/gcr4-ssh-askpass")
                        end
                      '')
                    ];
                  }
                ];

                # `hl.bind(keyspec, dispatcher, opts?)` via mkBind/mkBindOpts.
                # The `description` field defined by these helpers populates
                # Hyprland's bind-table description column so the shortcuts
                # viewer can show meaningful labels instead of `__lua <ref>`.
                bind = [
                  # Launch applications
                  (mkBind "${mod} + RETURN" (luaInline ''hl.dsp.exec_cmd("${term}")'') "Open terminal")
                  (mkBind "${mod} + T" (luaInline ''hl.dsp.exec_cmd("${term}")'') "Open terminal")
                  (mkBind "${mod} + Space" (luaInline ''hl.dsp.exec_cmd("dms ipc spotlight toggle")'') "App launcher")
                  (mkBind "${mod} + E" (luaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.nautilus}")'') "Open Nautilus")
                  (mkBind "${mod} + B" (luaInline ''hl.dsp.exec_cmd("xdg-open https://")'') "Open default browser")
                  (mkBind "${mod} + N" (luaInline ''hl.dsp.exec_cmd("dms ipc notifications toggle")'') "Toggle notifications")
                  (mkBind "${mod} + I" (luaInline ''hl.dsp.exec_cmd("dms ipc control-center toggle")'') "Control center (network)")
                  (mkBind "${mod} + C" (luaInline ''hl.dsp.exec_cmd("dms ipc clipboard toggle")'') "Clipboard history")

                  # Window management
                  (mkBind "${mod} + Q" (luaInline "hl.dsp.window.close()") "Close active window")
                  (mkBind "${mod} + SHIFT + Q" (luaInline "hl.dsp.exit()") "Exit Hyprland")
                  (mkBind "${mod} + V" (luaInline ''hl.dsp.window.float({ action = "toggle" })'') "Toggle floating")
                  (mkBind "${mod} + P" (luaInline ''hl.dsp.exec_cmd("dms ipc powermenu toggle")'') "Power menu")
                  (mkBind "${mod} + J" (luaInline ''hl.dsp.layout("togglesplit")'') "Toggle split direction")
                  (mkBind "${mod} + SHIFT + E" (luaInline ''hl.dsp.exec_cmd("hypr-equalize-windows")'') "Equalize window sizes")
                  (mkBind "${mod} + F" (luaInline ''hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })'') "Toggle fullscreen")
                  (mkBind "${mod} + R" (luaInline ''hl.dsp.submap("resize")'') "Resize submap")

                  # Move focus
                  (mkBind "${mod} + left" (luaInline ''hl.dsp.focus({ direction = "left" })'') "Focus window left")
                  (mkBind "${mod} + right" (luaInline ''hl.dsp.focus({ direction = "right" })'') "Focus window right")
                  (mkBind "${mod} + up" (luaInline ''hl.dsp.focus({ direction = "up" })'') "Focus window up")
                  (mkBind "${mod} + down" (luaInline ''hl.dsp.focus({ direction = "down" })'') "Focus window down")

                  # Move windows
                  (mkBind "${mod} + SHIFT + left" (luaInline ''hl.dsp.window.move({ direction = "left" })'') "Move active window left")
                  (mkBind "${mod} + SHIFT + right" (luaInline ''hl.dsp.window.move({ direction = "right" })'') "Move active window right")
                  (mkBind "${mod} + SHIFT + up" (luaInline ''hl.dsp.window.move({ direction = "up" })'') "Move active window up")
                  (mkBind "${mod} + SHIFT + down" (luaInline ''hl.dsp.window.move({ direction = "down" })'') "Move active window down")

                  # Special workspace (scratchpad)
                  (mkBind "${mod} + S" (luaInline ''hl.dsp.workspace.toggle_special("magic")'') "Toggle magic scratchpad")
                  (mkBind "${mod} + SHIFT + S" (luaInline ''hl.dsp.window.move({ workspace = "special:magic" })'') "Move active window to magic scratchpad")

                  # Scroll through workspaces
                  (mkBind "${mod} + mouse_down" (luaInline ''hl.dsp.focus({ workspace = "e+1" })'') "Next workspace (mousewheel)")
                  (mkBind "${mod} + mouse_up" (luaInline ''hl.dsp.focus({ workspace = "e-1" })'') "Previous workspace (mousewheel)")

                  # Screenshots
                  (mkBind "Print" (luaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.hyprshot} -m region --raw | ${lib.getExe pkgs.satty} -f -")'') "Region screenshot → satty")
                  (mkBind "CTRL + ALT + P" (luaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.hyprshot} -m region --clipboard-only")'') "Region screenshot → clipboard")
                  (mkBind "CTRL + ALT + SHIFT + P" (luaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.hyprshot} -m region --raw | ${lib.getExe pkgs.satty} -f -")'') "Region screenshot → satty")
                  (mkBind "SHIFT + Print" (luaInline ''hl.dsp.exec_cmd("${lib.getExe pkgs.hyprshot} -m output --raw | ${lib.getExe pkgs.satty} -f -")'') "Full-output screenshot → satty")

                  # Screen recording
                  (mkBind "CTRL + ALT + R" (luaInline ''hl.dsp.exec_cmd("hypr-record-region")'') "Toggle region screen recording")

                  # Lock screen (DMS; loginctl lock-session also triggers it
                  # via loginctlLockIntegration)
                  (mkBind "${mod} + L" (luaInline ''hl.dsp.exec_cmd("dms ipc lock lock")'') "Lock screen")

                  # Media control via playerctl (DMS shows its own media OSD)
                  (mkBind "XF86AudioPlay" (luaInline ''hl.dsp.exec_cmd("hypr-media-play-pause")'') "Media play/pause")
                  (mkBind "XF86AudioPause" (luaInline ''hl.dsp.exec_cmd("hypr-media-play-pause")'') "Media play/pause")
                  (mkBind "XF86AudioNext" (luaInline ''hl.dsp.exec_cmd("hypr-media-next")'') "Media next")
                  (mkBind "XF86AudioPrev" (luaInline ''hl.dsp.exec_cmd("hypr-media-prev")'') "Media previous")

                  # Mouse drag/resize. Keyspecs starting with `mouse:` are
                  # internally treated as mouse binds; no extra flag needed.
                  (mkBind "${mod} + mouse:272" (luaInline "hl.dsp.window.drag()") "Drag window (mouse)")
                  (mkBind "${mod} + mouse:273" (luaInline "hl.dsp.window.resize()") "Resize window (mouse)")

                  # Repeatable + locked: volume / brightness (DMS IPC).
                  # The trailing "" on brightness is the device-name arg
                  # (empty = preferred device).
                  (mkBindOpts "XF86AudioRaiseVolume" (luaInline ''hl.dsp.exec_cmd("dms ipc audio increment 3")'') { locked = true; repeating = true; } "Volume up")
                  (mkBindOpts "XF86AudioLowerVolume" (luaInline ''hl.dsp.exec_cmd("dms ipc audio decrement 3")'') { locked = true; repeating = true; } "Volume down")
                  (mkBindOpts "XF86MonBrightnessUp" (luaInline ''hl.dsp.exec_cmd("dms ipc brightness increment 5 \"\"")'') { locked = true; repeating = true; } "Brightness up")
                  (mkBindOpts "XF86MonBrightnessDown" (luaInline ''hl.dsp.exec_cmd("dms ipc brightness decrement 5 \"\"")'') { locked = true; repeating = true; } "Brightness down")

                  # Locked: audio mute toggles
                  (mkBindOpts "XF86AudioMute" (luaInline ''hl.dsp.exec_cmd("dms ipc audio mute")'') { locked = true; } "Toggle audio mute")
                  (mkBindOpts "XF86AudioMicMute" (luaInline ''hl.dsp.exec_cmd("dms ipc audio micmute")'') { locked = true; } "Toggle mic mute")
                ] ++ workspaceBinds;
              };

              # The Lua serializer appends extraConfig verbatim after all
              # `hl.*` calls. Used for things that don't fit the structured
              # settings shape: window rules, the resize submap, and the
              # conf.d dofile loader.
              extraConfig = ''
                -- ===== window rules =====
                -- `hl.window_rule({name=..., match={...}, <effect>=<value>})`.
                -- opacity is a STRING ("active inactive"), tile is a bool.
                hl.window_rule({
                  name = "opacity-editors",
                  match = { class = "code|codium" },
                  opacity = "${toString osConfig.hyprflake.style.opacity.applications} ${toString osConfig.hyprflake.style.opacity.applications}",
                })
                hl.window_rule({
                  name = "opacity-browsers",
                  match = { class = "chromium|firefox" },
                  opacity = "${toString osConfig.hyprflake.style.opacity.applications} ${toString osConfig.hyprflake.style.opacity.applications}",
                })
                hl.window_rule({
                  name = "opacity-terminal",
                  match = { class = "${termCfg.name}" },
                  opacity = "${toString osConfig.hyprflake.style.opacity.terminal} ${toString osConfig.hyprflake.style.opacity.terminal}",
                })

                hl.window_rule({
                  name = "float-audio-net",
                  match = { class = "pwvucontrol|blueman-manager" },
                  float = true,
                })
                hl.window_rule({
                  name = "float-nm-editor",
                  match = { class = "nm-connection-editor" },
                  float = true,
                })
                hl.window_rule({
                  name = "float-pip",
                  match = { title = "Picture-in-Picture" },
                  float = true,
                })
                hl.window_rule({
                  name = "pin-pip",
                  match = { title = "Picture-in-Picture" },
                  pin = true,
                })

                -- ===== resize submap =====
                -- Inside `hl.define_submap`, hl.bind() is auto-scoped to the
                -- submap. `repeating = true` reproduces the old `binde`.
                hl.define_submap("resize", function()
                  -- Vim keys
                  hl.bind("h", hl.dsp.window.resize({ x = -50, y = 0,  relative = true }), { repeating = true })
                  hl.bind("l", hl.dsp.window.resize({ x = 50,  y = 0,  relative = true }), { repeating = true })
                  hl.bind("k", hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
                  hl.bind("j", hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })

                  -- Arrow keys
                  hl.bind("left",  hl.dsp.window.resize({ x = -50, y = 0,  relative = true }), { repeating = true })
                  hl.bind("right", hl.dsp.window.resize({ x = 50,  y = 0,  relative = true }), { repeating = true })
                  hl.bind("up",    hl.dsp.window.resize({ x = 0,   y = -50, relative = true }), { repeating = true })
                  hl.bind("down",  hl.dsp.window.resize({ x = 0,   y = 50,  relative = true }), { repeating = true })

                  -- Exit
                  hl.bind("escape", hl.dsp.submap("reset"))
                  hl.bind("return", hl.dsp.submap("reset"))
                end)

                -- ===== conf.d loader =====
                -- The Lua manager has no `source` keyword. Glob ~/.config/hypr/conf.d/*.lua
                -- and dofile each in sorted order. pcall keeps one broken
                -- snippet from killing the whole config; the error lands in
                -- hyprland's log.
                do
                  local conf_d = (os.getenv("HOME") or "~") .. "/.config/hypr/conf.d"
                  local handle = io.popen('find ' .. conf_d .. ' -maxdepth 1 -name "*.lua" 2>/dev/null | sort')
                  if handle then
                    for f in handle:lines() do
                      local ok, err = pcall(dofile, f)
                      if not ok then
                        io.stderr:write(string.format("[hyprflake] error loading %s: %s\n", f, err))
                      end
                    end
                    handle:close()
                  end
                end
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
