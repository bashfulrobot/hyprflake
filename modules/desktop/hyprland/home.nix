# Home Manager side of the Hyprland module: settings, binds, window rules, dconf.
{ config, lib, pkgs, hyprflakeInputs, termCfg }:

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
      # mkLuaInline alias to keep the Lua snippets compact.
      luaInline = lib.generators.mkLuaInline;

      # hyprflake.desktop.hyprland.* (options.nix); defaults equal the values
      # this module hardcoded before the options existed.
      hcfg = osConfig.hyprflake.desktop.hyprland;
    in
    {
      enable = true;
      # Use the Lua config manager. It is the repo standard: the
      # hyprflake.hyprland.extraLua modules and downstream consumers
      # emit `hl.*` Lua snippets. (Originally adopted for hyprshell's
      # runtime `eval hl.bind`; hyprshell is gone but Lua stays.)
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
            repeat_delay = hcfg.input.repeatDelay;
            repeat_rate = hcfg.input.repeatRate;
            # Mode 2 = loose focus: click-to-focus for windows, but hover works in popups (hyprshell)
            follow_mouse = hcfg.input.followMouse;
            sensitivity = hcfg.input.sensitivity;
            force_no_accel = hcfg.input.forceNoAccel;

            touchpad = {
              natural_scroll = hcfg.touchpad.naturalScroll;
              disable_while_typing = hcfg.touchpad.disableWhileTyping;
              tap_to_click = hcfg.touchpad.tapToClick;
              clickfinger_behavior = hcfg.touchpad.clickfingerBehavior;
            };
          };

          general = {
            gaps_in = hcfg.gaps.inner;
            gaps_out = hcfg.gaps.outer;
            border_size = hcfg.borderSize;
            # Border colors managed by stylix
            resize_on_border = true;
            layout = "dwindle";
          };

          decoration = {
            inherit (hcfg) rounding;

            blur = {
              enabled = hcfg.blur.enable;
              size = hcfg.blur.size;
              passes = hcfg.blur.passes;
              new_optimizations = true;
            };

            shadow = {
              enabled = hcfg.shadow.enable;
              range = hcfg.shadow.range;
              render_power = hcfg.shadow.renderPower;
            };
          };

          animations = {
            enabled = hcfg.animations.enable;
          };

          cursor = {
            hide_on_key_press = hcfg.cursor.hideOnKeyPress;
          };

          xwayland = {
            force_zero_scaling = hcfg.xwayland.forceZeroScaling;
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
            # The display-manager module launches the session via
            # `uwsm start ... Hyprland`, which runs the Hyprland binary
            # directly and bypasses Hyprland's own `start-hyprland`
            # watchdog wrapper. Hyprland 0.55+ then nags at login with
            # "Hyprland is being launched without start-hyprland. This is
            # highly advised against." UWSM is the deliberate session
            # supervisor here (it activates graphical-session.target and
            # the user services), so the watchdog wrapper is intentionally
            # not used; silence the warning rather than nest supervisors.
            disable_watchdog_warning = true;
            # Lock client is DMS (one quickshell process drawing bar +
            # WlSessionLock). When that process aborts on a Wayland
            # fatal (protocol "invalid object" errors, or "no wl_display"
            # on respawn) while the screen is locked, Hyprland's
            # anti-bypass default refuses a replacement lock surface and
            # drops to the "lock app died" fallback, which needs TTY
            # recovery (and the fallback's own hyprctl keyword hint does
            # not work under the Lua config backend). dms.service is
            # Restart=on-failure, so allowing lock restore lets the
            # respawned shell re-grab the lock and the crash becomes a
            # recoverable blip instead of a lockout.
            allow_session_lock_restore = true;
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
          { leaf = "layers"; enabled = true; speed = 4; bezier = "default"; style = "fade"; }
          { leaf = "specialWorkspace"; enabled = true; speed = 5; bezier = "default"; style = "slidevert"; }
        ];

        # `hl.gesture({...})` per finger count.
        gesture = [
          { fingers = 3; direction = "horizontal"; action = "workspace"; }
          { fingers = 4; direction = "horizontal"; action = "workspace"; }
          # 3-finger swipe up: toggle the magic scratchpad (same as SUPER+S).
          { fingers = 3; direction = "up"; action = "special"; workspace_name = "magic"; }
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
        bind = import ./binds.nix { inherit lib pkgs termCfg; };
      };

      # The Lua serializer appends extraConfig verbatim after all
      # `hl.*` calls. Used for things that don't fit the structured
      # settings shape: window rules and the resize submap. The
      # `hyprflake.hyprland.extraLua` loader appends its `require(...)`
      # block after this via `lib.mkAfter` (see the sharedModule below),
      # so extra modules still load last.
      extraConfig = import ./rules.nix { inherit lib pkgs osConfig termCfg; };
    };

  # GNOME dconf settings
  dconf.settings = with hyprflakeInputs.home-manager.lib.hm.gvariant; {
    "org/gnome/desktop/wm/preferences" = {
      button-layout = "appmenu"; # Remove close/minimize/maximize buttons
    };
    # GTK3/GTK4 on Wayland take antialiasing from these keys (via the
    # settings portal), not from fontconfig. Mirror
    # hyprflake.style.fontRendering.subpixel so GTK follows it.
    "org/gnome/desktop/interface" =
      let
        subpixel = osConfig.hyprflake.style.fontRendering.subpixel;
      in
      {
        font-antialiasing = if subpixel == "none" then "grayscale" else "rgba";
      }
      // lib.optionalAttrs (subpixel != "none") {
        font-rgba-order = subpixel;
      };
  };
}
