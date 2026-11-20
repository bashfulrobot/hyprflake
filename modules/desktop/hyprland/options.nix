# Typed knobs for the Hyprland look and feel: hyprflake.desktop.hyprland.*
#
# Every default is the value the module hardcoded before these options
# existed, so importing hyprflake without setting any of them changes
# nothing. Anything not exposed here is still reachable through
# `hyprflake.hyprland.extraLua`, which loads last and wins.
{ lib, ... }:

let
  inherit (lib) mkOption mkEnableOption types;

  number = types.oneOf [ types.int types.float ];
in
{
  options.hyprflake.desktop.hyprland = {
    gaps = {
      inner = mkOption {
        type = types.ints.unsigned;
        default = 4;
        description = "Gap between windows, in pixels (`general.gaps_in`).";
      };
      outer = mkOption {
        type = types.ints.unsigned;
        default = 8;
        description = "Gap between windows and screen edges, in pixels (`general.gaps_out`).";
      };
    };

    borderSize = mkOption {
      type = types.ints.unsigned;
      default = 2;
      description = "Window border width in pixels. Border colors come from Stylix.";
    };

    rounding = mkOption {
      type = types.ints.unsigned;
      default = 8;
      description = "Window corner radius in pixels.";
    };

    blur = {
      enable = mkEnableOption "background blur behind translucent windows" // { default = true; };
      size = mkOption {
        type = types.ints.positive;
        default = 3;
        description = "Blur kernel size.";
      };
      passes = mkOption {
        type = types.ints.positive;
        default = 1;
        description = "Blur passes. More is smoother and costs more GPU.";
      };
    };

    shadow = {
      enable = mkEnableOption "window drop shadows" // { default = true; };
      range = mkOption {
        type = types.ints.unsigned;
        default = 4;
        description = "Shadow size in pixels.";
      };
      renderPower = mkOption {
        type = types.ints.between 1 4;
        default = 3;
        description = "Shadow falloff sharpness (1 to 4, higher is sharper).";
      };
    };

    animations.enable = mkEnableOption "window, workspace and layer animations" // { default = true; };

    input = {
      repeatDelay = mkOption {
        type = types.ints.positive;
        default = 300;
        description = "Milliseconds before a held key starts repeating.";
      };
      repeatRate = mkOption {
        type = types.ints.positive;
        default = 30;
        description = "Key repeats per second once repeating.";
      };
      followMouse = mkOption {
        type = types.ints.between 0 3;
        default = 2;
        description = ''
          How focus follows the pointer. 0 = click to focus, 1 = focus
          follows the pointer, 2 = loose (click focuses windows, hover still
          works inside popups), 3 = like 2 but the cursor does not drive focus.
        '';
      };
      sensitivity = mkOption {
        type = number;
        default = 0;
        description = "Pointer sensitivity from -1.0 to 1.0.";
      };
      forceNoAccel = mkOption {
        type = types.bool;
        default = true;
        description = "Disable pointer acceleration (flat profile).";
      };
    };

    touchpad = {
      naturalScroll = mkOption {
        type = types.bool;
        default = true;
        description = "Natural (inverted) two-finger scrolling.";
      };
      disableWhileTyping = mkOption {
        type = types.bool;
        default = true;
        description = "Ignore the touchpad while typing.";
      };
      tapToClick = mkOption {
        type = types.bool;
        default = true;
        description = "A tap counts as a click.";
      };
      clickfingerBehavior = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Clickpad button areas by finger count instead of position:
          1 finger = left, 2 = right, 3 = middle.
        '';
      };
    };

    cursor.hideOnKeyPress = mkOption {
      type = types.bool;
      default = true;
      description = "Hide the pointer while typing, until it moves again.";
    };

    xwayland.forceZeroScaling = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Render XWayland apps at scale 1 and let them upscale themselves,
        which removes blur on fractional or 2x scaling. XWayland apps then
        look small unless they honor `GDK_SCALE`/`QT_SCALE_FACTOR`, so it is
        off by default.
      '';
    };

    idleInhibitFullscreen = mkOption {
      type = types.bool;
      default = true;
      description = ''
        Keep the session awake (no idle lock or screen off) while any window
        is fullscreen, so video and presentations never blank the screen.
      '';
    };
  };
}
