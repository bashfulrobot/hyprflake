{ config, lib, pkgs, ... }:

# Shortcuts Viewer - Dynamic Hyprland keybinding and global shortcut viewer
# Provides rofi and terminal (fzf) display modes
# Uses hyprctl for real-time keybinding data
# Default keybindings: Super+? and Super+Shift+?

with lib;

let
  cfg = config.hyprflake.shortcuts-viewer;

  shortcutsScript = pkgs.writeShellScriptBin "hypr-shortcuts" (builtins.readFile ./hypr-shortcuts.sh);

  # Rofi variants for convenience
  rofiBindsScript = pkgs.writeShellScriptBin "hypr-shortcuts-rofi" ''
    ${shortcutsScript}/bin/hypr-shortcuts binds rofi
  '';

  rofiGlobalScript = pkgs.writeShellScriptBin "hypr-shortcuts-rofi-global" ''
    ${shortcutsScript}/bin/hypr-shortcuts global rofi
  '';

  # Terminal variants for convenience
  terminalBindsScript = pkgs.writeShellScriptBin "hypr-shortcuts-terminal" ''
    ${shortcutsScript}/bin/hypr-shortcuts binds terminal
  '';

  terminalGlobalScript = pkgs.writeShellScriptBin "hypr-shortcuts-terminal-global" ''
    ${shortcutsScript}/bin/hypr-shortcuts global terminal
  '';
in
{
  options.hyprflake.shortcuts-viewer = {
    enable = mkEnableOption "Hyprland shortcuts viewer";

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
        default = "SUPER, question, exec, hypr-shortcuts-${cfg.defaultDisplay}";
        description = ''
          Keybinding to show regular keybindings.
          Default: Super+? (question mark)
        '';
      };

      showGlobal = mkOption {
        type = types.str;
        default = "SUPER SHIFT, question, exec, hypr-shortcuts-${cfg.defaultDisplay}-global";
        description = ''
          Keybinding to show global shortcuts.
          Default: Super+Shift+? (question mark)
        '';
      };
    };
  };

  config = mkIf cfg.enable {
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
      })
    ];
  };
}
