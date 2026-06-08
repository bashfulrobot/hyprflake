{ config
, lib
, pkgs
, hyprflakeInputs
, ...
}:

let
  systemdHelpers = import ../../../lib/systemd-helpers.nix { inherit lib; };

  package = hyprflakeInputs.snappy-switcher.packages.${pkgs.stdenv.hostPlatform.system}.default;

  snappy = lib.getExe package;

  # Icon theme used to resolve application icons in the switcher, tracking the
  # system icon theme. Bound here in the outer (NixOS) scope so it is not
  # shadowed by the home-manager `config` inside sharedModules below.
  iconTheme = config.hyprflake.style.icon.name;
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
  # Core desktop function: always on, not gated behind an enable option and
  # exposing no options. It ships ~/.config/snappy-switcher/config.ini (colors
  # derived from Stylix), runs the daemon as a graphical-session systemd user
  # service, and binds ALT+Tab / ALT+SHIFT+Tab via a conf.d Lua snippet. The
  # hyprland module yields ALT+Tab to snappy (no native cycle_next fallback),
  # so snappy is the sole owner of ALT+Tab.

  config = {
    environment.systemPackages = [ package ];

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
            mode = overview
            show_workspace_badge = false
            follow_monitor = true
            sticky_mode = false

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
            theme = ${iconTheme}
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
