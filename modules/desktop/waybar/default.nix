{ config, lib, ... }:

{
  # DEPRECATED: the status bar is now provided by DankMaterialShell
  # (modules/desktop/dank). This module is an options-only stub: the full
  # option surface is kept verbatim (consumers such as nixerator's
  # lib/mkWebApp.nix set hyprflake.desktop.waybar.workspaceAppIcons.rewrites)
  # so they keep evaluating, but nothing is rendered.
  options.hyprflake.desktop.waybar = {
    enable = lib.mkEnableOption "Waybar status bar" // { default = true; };

    workspaceAppIcons = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        example = false;
        description = ''
          Render application icons within each Hyprland workspace indicator
          using Waybar's `window-rewrite` feature. Icons are Nerd Font glyphs
          matched against window class or title.
        '';
      };

      format = lib.mkOption {
        type = lib.types.str;
        default = "{name} {windows}";
        example = "{icon} {windows}";
        description = ''
          Format string for workspace buttons when app icons are enabled.
          Supports Waybar placeholders: `{id}`, `{name}`, `{icon}`, `{windows}`.
        '';
      };

      defaultIcon = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "";
        description = ''
          Fallback glyph rendered for windows that do not match any entry in
          `rewrites`. Set to an empty string to render nothing for unmatched
          windows.
        '';
      };

      iconColor = lib.mkOption {
        type = lib.types.str;
        default = "";
        example = "#f9e2af";
        description = ''
          CSS hex color (with leading `#`) for workspace app-icon glyphs.
          When non-empty, each rendered glyph is wrapped in a Pango
          `<span foreground='...'>` tag so the icon takes this color while
          the workspace number continues to inherit the CSS-driven
          active/inactive/occupied color.

          Pango foreground is a static color — it cannot track CSS state
          transitions — so pick one that reads well on every workspace
          button background in your theme. Leave empty to have icons
          inherit the same color as the workspace number.
        '';
      };

      includeDefaultRewrites = lib.mkOption {
        type = lib.types.bool;
        default = true;
        example = false;
        description = ''
          Whether to include hyprflake's baked-in `rewrites` baseline (Firefox,
          Chromium, Kitty, VS Code, Discord, Slack, etc.). Set to `false` to
          start from an empty map and define every rewrite yourself.
        '';
      };

      rewrites = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        default = { };
        example = lib.literalExpression ''
          {
            "class<firefox>" = "";
            "class<kitty>" = "";
            "title<.*github.*>" = "";
          }
        '';
        description = ''
          Extensions/overrides for the `window-rewrite` map. Keys use Waybar's
          matcher syntax, e.g. `class<regex>`, `title<regex>`, or both
          space-separated. Values are the glyph (typically Nerd Font) rendered
          for matching windows.

          When `includeDefaultRewrites = true` these entries are concatenated
          onto hyprflake's baseline via `//`, so colliding keys here override
          the baseline and non-colliding baseline entries still apply. Set a
          value to an empty string to suppress rendering for a matched window
          without dropping the entry.
        '';
      };
    };
  };

  config = lib.mkIf config.hyprflake.desktop.waybar.enable {
    warnings = [
      "hyprflake.desktop.waybar is a no-op: the status bar is now provided by DankMaterialShell (modules/desktop/dank). workspaceAppIcons.* options are ignored."
    ];
  };
}
