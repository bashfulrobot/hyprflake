{ config, lib, ... }:

let
  cfg = config.hyprflake.desktop.rio;
in
{
  options.hyprflake.desktop.rio.enable = lib.mkEnableOption "Rio terminal emulator (GPU/WebGPU, Kitty graphics protocol)";

  config = lib.mkIf cfg.enable {
    # Rio terminal configuration.
    #
    # Colors and fonts come from Stylix's Rio target automatically (it activates
    # whenever programs.rio is enabled), exactly as the kitty module leaves
    # colours to Stylix. This module only sets non-theme behaviour so it mirrors
    # the kitty setup: padding, decorations, cursor, clipboard, and the keymap.
    #
    # This module provides Rio's *config* only. To also launch Rio from
    # SUPER+RETURN / SUPER+T, Nautilus "Open in Terminal", and the terminal
    # opacity window rule, set the launcher in your consumer as well:
    #
    #   hyprflake.desktop.rio.enable = true;
    #   hyprflake.desktop.kitty.enable = false;       # optional: drop kitty
    #   hyprflake.desktop.terminal.package = pkgs.rio; # updates keybinds + rules
    #
    # Config schema verified against Rio 0.4.7 (rio-backend/src/config/*.rs).

    home-manager.sharedModules = [
      {
        programs.rio = {
          enable = true;

          settings = {
            # Don't prompt on window close (kitty: confirm_os_window_close = 0).
            confirm-before-quit = false;

            # Copy on mouse selection (kitty: copy_on_select = yes).
            copy-on-select = true;

            # 24-bit colour (kitty: environment COLORTERM = truecolor).
            env-vars = [ "COLORTERM=truecolor" ];

            # Inner padding between the terminal grid and the window edge, in px.
            # kitty: window_padding_width = 15. Rio 0.4.7's `margin` field has a
            # custom deserializer that reads a CSS-shorthand *sequence* of floats
            # (rio-backend/src/config/layout.rs: from_css_values accepts 1, 2, or
            # 4 values -> [all], [vertical, horizontal], or [top, right, bottom,
            # left]). A table is rejected with "invalid type: map, expected a
            # sequence". Values are floats: the field is f32 and the TOML parser
            # rejects bare integers here.
            margin = [
              15.0 # top
              15.0 # right
              15.0 # bottom
              15.0 # left
            ];

            window = {
              # kitty: hide_window_decorations = yes.
              decorations = "Disabled";
              # window.opacity is deliberately not set here: Stylix's Rio target
              # sets it from stylix opacity.terminal (the same source kitty uses),
              # and the Hyprland `opacity-terminal` window rule also applies by
              # class. The two settings tables deep-merge, so decorations and
              # Stylix's opacity coexist under [window].
            };

            cursor = {
              # kitty: cursor_shape = block.
              shape = "block";
              # kitty: cursor_blink_interval = 0 (no blink).
              blinking = false;
            };

            # Rio's Linux defaults already match most of the kitty keymap:
            # ctrl+shift+{c,v} copy/paste, ctrl+shift+t new tab, ctrl+shift+w
            # close, ctrl+shift+n new window. These entries only add the kitty
            # bindings that Rio spells differently; Rio merges them over the
            # defaults. Action strings and key tokens per bindings.rs / the
            # config key parser in frontends/rioterm/src/bindings/mod.rs.
            bindings.keys = [
              # Font size: kitty uses ctrl+shift; Rio defaults to plain ctrl.
              {
                key = "=";
                "with" = "control | shift";
                action = "IncreaseFontSize";
              }
              {
                key = "-";
                "with" = "control | shift";
                action = "DecreaseFontSize";
              }
              {
                key = "0";
                "with" = "control | shift";
                action = "ResetFontSize";
              }

              # Tab switching: kitty uses ctrl+shift+arrows; Rio defaults to
              # ctrl+Tab and ctrl+shift+[ / ].
              {
                key = "right";
                "with" = "control | shift";
                action = "SelectNextTab";
              }
              {
                key = "left";
                "with" = "control | shift";
                action = "SelectPrevTab";
              }

              # kitty: ctrl+shift+enter = new window, ctrl+shift+q = close tab.
              {
                key = "return";
                "with" = "control | shift";
                action = "CreateWindow";
              }
              {
                key = "q";
                "with" = "control | shift";
                action = "CloseTab";
              }
            ];
          };
        };
      }
    ];
  };
}
