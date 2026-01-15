{ config, lib, pkgs, ... }:

# Shortcuts Viewer - Dynamic Hyprland keybinding and global shortcut viewer
# Provides rofi and terminal (fzf) display modes
# Uses hyprctl for real-time keybinding data
# Default keybindings: Super+/ and Super+Shift+/ (displays as ?)

with lib;

let
  cfg = config.hyprflake.shortcuts-viewer;
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
  options.hyprflake.shortcuts-viewer = {
    defaultDisplay = mkOption {
      type = types.enum [ "rofi" "terminal" ];
      default = "rofi";
      description = ''
        Default display method for shortcuts viewer.
        - rofi: GUI overlay using rofi
        - terminal: Terminal-based with fzf
      '';
    };

    keybindings = {
      showBinds = mkOption {
        type = types.str;
        default = "SUPER, slash, exec, hypr-shortcuts-${cfg.defaultDisplay}";
        description = ''
          Keybinding to show regular keybindings.
          Default: Super+/ (slash)
        '';
      };

      showGlobal = mkOption {
        type = types.str;
        default = "SUPER SHIFT, slash, exec, hypr-shortcuts-${cfg.defaultDisplay}-global";
        description = ''
          Keybinding to show global shortcuts.
          Default: Super+Shift+/ (produces ? symbol)
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

        # Add keybindings to Hyprland
        wayland.windowManager.hyprland.settings = {
          bind = [
            cfg.keybindings.showBinds
            cfg.keybindings.showGlobal
          ];
        };

        # Install custom theme for the shortcuts viewer rofi
        xdg.configFile."rofi/shortcuts-viewer.rasi".text = stylix.mkStyle ./theme.nix;
      })
    ];
  };
}
