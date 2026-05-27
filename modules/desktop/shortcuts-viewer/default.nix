{ config, lib, pkgs, ... }:

# Shortcuts Viewer - Dynamic Hyprland keybinding and global shortcut viewer
# Provides rofi and terminal (fzf) display modes
# Uses hyprctl for real-time keybinding data
# Default keybindings: Super+/ and Super+Shift+/ (displays as ?)

let
  cfg = config.hyprflake.desktop.shortcutsViewer;
  stylix = import ../../../lib/stylix-helpers.nix { inherit lib config; };

  shortcutsScript = pkgs.writeShellScriptBin "hypr-shortcuts" (builtins.readFile ./hypr-shortcuts.sh);
  rofiBindsScript = pkgs.writeShellScriptBin "hypr-shortcuts-rofi" ''
    exec ${lib.getExe shortcutsScript} binds rofi
  '';
  rofiGlobalScript = pkgs.writeShellScriptBin "hypr-shortcuts-rofi-global" ''
    exec ${lib.getExe shortcutsScript} global rofi
  '';
  terminalBindsScript = pkgs.writeShellScriptBin "hypr-shortcuts-terminal" ''
    exec ${lib.getExe shortcutsScript} binds terminal
  '';
  terminalGlobalScript = pkgs.writeShellScriptBin "hypr-shortcuts-terminal-global" ''
    exec ${lib.getExe shortcutsScript} global terminal
  '';
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
      type = lib.types.enum [ "rofi" "terminal" ];
      default = "rofi";
      description = ''
        Default display method for shortcuts viewer.
        - rofi: GUI overlay using rofi
        - terminal: Terminal-based with fzf
      '';
    };

    keybindings = {
      showBinds = lib.mkOption {
        type = lib.types.lines;
        default = ''hl.bind("SUPER + slash", hl.dsp.exec_cmd("hypr-shortcuts-${cfg.defaultDisplay}"), { description = "Show keybindings" })'';
        description = ''
          Lua snippet that registers the "show regular keybindings"
          keybind. Defaults to `Super+/`. With Hyprland's Lua config
          backend this must be one or more `hl.bind(...)` lines; it is
          appended verbatim to `wayland.windowManager.hyprland.extraConfig`.
          Include a `description = "..."` opt so the shortcuts viewer
          (which renders this list) shows a human-readable label rather
          than `__lua <ref>`.
        '';
      };

      showGlobal = lib.mkOption {
        type = lib.types.lines;
        default = ''hl.bind("SUPER + SHIFT + slash", hl.dsp.exec_cmd("hypr-shortcuts-${cfg.defaultDisplay}-global"), { description = "Show global shortcuts" })'';
        description = ''
          Lua snippet that registers the "show global shortcuts"
          keybind. Defaults to `Super+Shift+/` (produces ? symbol).
          See `showBinds` for the expected format.
        '';
      };
    };
  };

  config = {
    # Configure via home-manager sharedModules to apply to all users
    home-manager.sharedModules = [
      (_: {
        # Install all script variants and required dependencies
        home.packages = [
          shortcutsScript
          rofiBindsScript
          rofiGlobalScript
          terminalBindsScript
          terminalGlobalScript
          pkgs.jq
          pkgs.fzf
        ];

        # Add keybindings to Hyprland (Lua backend). Appended to extraConfig
        # so each option value is treated as raw Lua — the user supplies
        # `hl.bind(...)` calls themselves rather than a hyprlang bind line.
        wayland.windowManager.hyprland.extraConfig = lib.mkAfter ''

          -- shortcuts-viewer keybinds
          ${cfg.keybindings.showBinds}
          ${cfg.keybindings.showGlobal}
        '';

        # Install custom theme for the shortcuts viewer rofi
        xdg.configFile."rofi/shortcuts-viewer.rasi".text = stylix.mkStyle ./theme.nix;
      })
    ];
  };
}
