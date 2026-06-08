{ config
, lib
, pkgs
, hyprflakeInputs
, ...
}:

let
  cfg = config.hyprflake.desktop.snappySwitcher;

  systemdHelpers = import ../../../lib/systemd-helpers.nix { inherit lib; };

  snappy = lib.getExe cfg.package;
in
{
  # Snappy Switcher: a traditional MRU Alt+Tab window switcher for Hyprland.
  #
  # DMS-first exception: DankMaterialShell's SUPER+Tab `toggleOverview` is a
  # spatial exposé, NOT a most-recently-used switcher, and DMS ships no
  # alt-tab switcher. snappy-switcher fills that gap. It is a standalone
  # Wayland layer-shell overlay that talks to Hyprland's IPC directly, so it
  # neither depends on nor conflicts with DMS. See docs/architecture.md.
  #
  # Upstream has no home-manager module, so this module configures it by hand:
  # it ships ~/.config/snappy-switcher/config.ini (colors derived from Stylix),
  # runs the daemon as a graphical-session systemd user service, and binds
  # ALT+Tab / ALT+SHIFT+Tab via a conf.d Lua snippet. When this module is
  # enabled, the hyprland module drops its native cycle_next fallback on those
  # keys (see modules/desktop/hyprland) so snappy is the sole owner of ALT+Tab.

  options.hyprflake.desktop.snappySwitcher = {
    enable = lib.mkEnableOption "Snappy Switcher — traditional MRU Alt+Tab window switcher for Hyprland";

    package = lib.mkOption {
      type = lib.types.package;
      default = hyprflakeInputs.snappy-switcher.packages.${pkgs.stdenv.hostPlatform.system}.default;
      defaultText = lib.literalExpression "hyprflakeInputs.snappy-switcher.packages.\${system}.default";
      description = ''
        The snappy-switcher package to use.
        Defaults to the package from hyprflake's flake input.
      '';
    };

    mode = lib.mkOption {
      type = lib.types.enum [ "overview" "context" ];
      default = "overview";
      example = "context";
      description = ''
        Window grouping mode. Either mode cycles in most-recently-used (MRU)
        order, which is the traditional alt-tab behaviour.

        - "overview": one card per window (classic alt-tab). hyprflake default.
        - "context": groups windows by app class (macOS-style), adding a
          group-count badge to stacked cards.
      '';
    };

    showWorkspaceBadge = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        Show the small workspace-indicator pill in each card's bottom-left
        corner (e.g. [3] for workspace 3, [S] for a special workspace). It
        tells you which workspace a window lives on before you switch to it.

        hyprflake defaults this off for a cleaner switcher; upstream's default
        is true.
      '';
    };

    followMonitor = lib.mkOption {
      type = lib.types.bool;
      default = true;
      example = false;
      description = ''
        Render the switcher on the focused monitor instead of the primary one.
      '';
    };

    stickyMode = lib.mkOption {
      type = lib.types.bool;
      default = false;
      example = true;
      description = ''
        When true, opening the switcher keeps focus on the current window
        instead of pre-selecting the previous (MRU) window. Leave false for
        traditional alt-tab, where a single Alt+Tab tap jumps to the last
        used window.
      '';
    };

    iconTheme = lib.mkOption {
      type = lib.types.str;
      default = config.hyprflake.style.icon.name;
      defaultText = lib.literalExpression "config.hyprflake.style.icon.name";
      description = ''
        Icon theme used to resolve application icons in the switcher.
        Defaults to the system icon theme (hyprflake.style.icon.name).
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    home-manager.sharedModules = [
      (
        { config, ... }:
        let
          # Stylix base16 palette + sans font, read from the home-manager
          # config (Stylix populates lib.stylix / stylix.fonts there — see
          # modules/desktop/kitty for the same access pattern). snappy parses
          # #RRGGBB / #RRGGBBAA; base16 colors are bare hex, so prefix '#'.
          inherit (config.lib.stylix) colors;

          # All eleven color keys are set explicitly: the C defaults are garish
          # debug colors meant to be overridden by a theme file, so supplying
          # every one means we need no theme file at all (src/config.c
          # set_defaults). Stylix is the single source of truth for color, the
          # same as DMS / GTK / kitty.
          configIni = pkgs.writeText "snappy-switcher-config.ini" ''
            # Snappy Switcher — managed by hyprflake
            # (modules/desktop/snappy-switcher). Do not edit; colors track the
            # active Stylix base16 palette.

            [general]
            mode = ${cfg.mode}
            show_workspace_badge = ${lib.boolToString cfg.showWorkspaceBadge}
            follow_monitor = ${lib.boolToString cfg.followMonitor}
            sticky_mode = ${lib.boolToString cfg.stickyMode}

            [theme]
            background = #${colors.base00}
            card_bg = #${colors.base01}
            card_selected = #${colors.base02}
            border_color = #${colors.base0D}
            text_color = #${colors.base05}
            subtext_color = #${colors.base04}
            bundle_bg = #${colors.base01}
            badge_bg = #${colors.base0D}
            badge_text_color = #${colors.base00}
            badge_bg_selected = #${colors.base0C}
            badge_text_color_selected = #${colors.base00}
            border_width = 2
            corner_radius = 15

            [icons]
            theme = ${cfg.iconTheme}
            fallback = hicolor
            show_letter_fallback = true

            [font]
            family = ${config.stylix.fonts.sansSerif.name}
            weight = Bold
            title_size = 10
            icon_letter_size = 24
          '';
        in
        {
          xdg.configFile."snappy-switcher/config.ini".source = configIni;

          # The daemon queries Hyprland IPC and renders the overlay on demand.
          # Run it as a graphical-session user service (auto-restart) rather
          # than exec-once: hyprland's systemd integration imports WAYLAND_DISPLAY
          # / HYPRLAND_INSTANCE_SIGNATURE into the session env before
          # graphical-session.target is reached. The binary takes over any stale
          # daemon on start (src/main.c takeover_existing_daemon).
          systemd.user.services.snappy-switcher = systemdHelpers.mkGraphicalUserService {
            description = "Snappy Switcher daemon (Alt+Tab window switcher)";
            documentation = "https://github.com/OpalAayan/snappy-switcher";
            exec = "${snappy} --daemon";
            restart = "on-failure";
            restartSec = 2;
          };

          # ALT+Tab / ALT+SHIFT+Tab → snappy-switcher (MRU). Dropped into the
          # conf.d Lua loader (the documented Hyprland extension point — see
          # docs/architecture.md). --mod alt must match the held modifier so the
          # overlay dismisses on Alt release; descriptions surface in the
          # shortcuts-viewer cheatsheet.
          xdg.configFile."hypr/conf.d/snappy-switcher.lua".text = ''
            hl.bind("ALT + Tab", hl.dsp.exec_cmd("${snappy} next --mod alt"), { description = "Window switcher (next)" })
            hl.bind("ALT + SHIFT + Tab", hl.dsp.exec_cmd("${snappy} prev --mod alt"), { description = "Window switcher (previous)" })
          '';
        }
      )
    ];
  };
}
