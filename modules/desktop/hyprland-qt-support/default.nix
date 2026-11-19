{ config, lib, ... }:

let
  cfg = config.hyprflake.desktop.hyprlandQtSupport;
in
{
  options.hyprflake.desktop.hyprlandQtSupport = {
    enable = lib.mkEnableOption "Hyprland Qt support (QML style for hypr* Qt6 apps)" // { default = true; };

    settings = lib.mkOption {
      type = lib.types.attrs;
      default = { };
      example = lib.literalExpression ''
        {
          roundness = 3;
          reduce_motion = true;
        }
      '';
      description = ''
        Extra `~/.config/hypr/application-style.conf` keys, merged over the
        hyprflake defaults (`roundness = 2`, `border_width = 2`,
        `reduce_motion = false`). Rendered by home-manager's
        `programs.hyprland-qt-support`.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    # Hyprland Qt support is the Qt6 Quick Controls style the hypr* Qt apps
    # load (hyprland-qtutils, which Hyprland wraps onto its PATH for the
    # permission and update dialogs, and hyprsysteminfo). Colours are not set
    # here: the style reads them from the Qt palette (`control.palette.*`), so
    # they follow whatever Stylix's qt target provides. This module only
    # supplies the geometry/motion knobs in application-style.conf, matched to
    # the compositor config in modules/desktop/hyprland (decoration.rounding = 8
    # is roundness 2 = 8px; general.border_size = 2).
    #
    # DMS is not involved: DankMaterialShell draws its own Quickshell UI and
    # does not use this style, so there is no DMS-first conflict. hyprpolkitagent
    # is hyprtoolkit-based since 0.2.0 and ignores this file.
    #
    # Needs a home-manager that ships programs.hyprland-qt-support (added
    # 2026-06-19).
    home-manager.sharedModules = [
      {
        programs.hyprland-qt-support = {
          enable = true;
          settings = lib.mkMerge [
            (lib.mapAttrs (_: lib.mkDefault) {
              # 0 = 0px, 1 = 4px, 2 = 8px, 3 = 16px corner radius.
              roundness = 2;
              border_width = 2;
              reduce_motion = false;
            })
            cfg.settings
          ];
        };
      }
    ];
  };
}
