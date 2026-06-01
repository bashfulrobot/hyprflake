{ config, lib, pkgs, ... }:

# Shortcuts Viewer - Stylix-themed HTML keybinding cheat-sheet.
# A wrapper renders `hyprctl binds -j` into a themed HTML page on each open
# and launches it in the default browser. The bind list is always current
# and includes consumer conf.d binds; the styling is baked at Nix build time
# from Stylix so it cannot drift. Default keybind: Super+/.

let
  cfg = config.hyprflake.desktop.shortcutsViewer;
  c = config.lib.stylix.colors;

  themed = builtins.replaceStrings
    [ "@@BG@@" "@@FG@@" "@@ALT@@" "@@ACCENT@@" "@@FONT@@" ]
    [
      "#${c.base00}"
      "#${c.base05}"
      "#${c.base01}"
      "#${c.base0D}"
      config.stylix.fonts.sansSerif.name
    ]
    (builtins.readFile ./hypr-shortcuts-html.sh);

  shortcutsScript = pkgs.writeShellApplication {
    name = "hypr-shortcuts";
    runtimeInputs = [ pkgs.hyprland pkgs.jq pkgs.coreutils pkgs.xdg-utils ];
    text = themed;
  };
in
{
  imports = [
    (lib.mkRenamedOptionModule
      [ "hyprflake" "shortcuts-viewer" "defaultDisplay" ]
      [ "hyprflake" "desktop" "shortcutsViewer" "defaultDisplay" ])
    (lib.mkRenamedOptionModule
      [ "hyprflake" "shortcuts-viewer" "keybindings" "showBinds" ]
      [ "hyprflake" "desktop" "shortcutsViewer" "keybindings" "showBinds" ])
    (lib.mkRenamedOptionModule
      [ "hyprflake" "shortcuts-viewer" "keybindings" "showGlobal" ]
      [ "hyprflake" "desktop" "shortcutsViewer" "keybindings" "showGlobal" ])
  ];

  options.hyprflake.desktop.shortcutsViewer = {
    defaultDisplay = lib.mkOption {
      type = lib.types.enum [ "rofi" "terminal" "browser" ];
      default = "browser";
      description = ''
        Display method. Only "browser" is implemented (a themed HTML page);
        "rofi" and "terminal" are deprecated no-ops kept for compatibility.
      '';
    };

    keybindings = {
      showBinds = lib.mkOption {
        type = lib.types.lines;
        default = ''hl.bind("SUPER + slash", hl.dsp.exec_cmd("hypr-shortcuts"), { description = "Show keybindings" })'';
        description = ''
          Lua hl.bind snippet that registers the cheat-sheet keybind.
          Appended verbatim to wayland.windowManager.hyprland.extraConfig.
        '';
      };

      showGlobal = lib.mkOption {
        type = lib.types.lines;
        default = "";
        description = ''
          Optional extra Lua hl.bind snippet. Empty by default; the single
          HTML page already lists every bind.
        '';
      };
    };
  };

  config = {
    home-manager.sharedModules = [
      (_: {
        home.packages = [ shortcutsScript ];

        wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''

          -- shortcuts-viewer keybind
          ${cfg.keybindings.showBinds}
          ${cfg.keybindings.showGlobal}
        '';
      })
    ];
  };
}
