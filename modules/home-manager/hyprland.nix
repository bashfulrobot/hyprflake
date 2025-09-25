{ config, lib, pkgs, ... }:

with lib;

{
  options.wayland.windowManager.hyprflake = {
    enable = mkEnableOption "Enable Hyprland window manager configuration";

    theme = {
      gtkTheme = mkOption {
        type = types.str;
        default = "Adwaita-dark";
        description = "GTK theme name";
      };

      iconTheme = mkOption {
        type = types.str;
        default = "Adwaita";
        description = "Icon theme name";
      };

      cursorTheme = mkOption {
        type = types.str;
        default = "Adwaita";
        description = "Cursor theme name";
      };

      cursorSize = mkOption {
        type = types.int;
        default = 24;
        description = "Cursor size";
      };
    };
  };

  config = mkIf config.wayland.windowManager.hyprflake.enable {
    # Enable Hyprland
    wayland.windowManager.hyprland = {
      enable = true;

    # Basic configuration
    settings = {
      "$mod" = "SUPER";

      # Keybindings
      bind = [
        "$mod, Q, exec, kitty"
        "$mod, C, killactive"
        "$mod, M, exit"
        "$mod, E, exec, dolphin"
        "$mod, V, togglefloating"
        "$mod, R, exec, wofi --show drun"
        "$mod, P, pseudo"
        "$mod, J, togglesplit"

        # Move focus
        "$mod, left, movefocus, l"
        "$mod, right, movefocus, r"
        "$mod, up, movefocus, u"
        "$mod, down, movefocus, d"

        # Workspaces
        "$mod, 1, workspace, 1"
        "$mod, 2, workspace, 2"
        "$mod, 3, workspace, 3"
        "$mod, 4, workspace, 4"
        "$mod, 5, workspace, 5"
        "$mod, 6, workspace, 6"
        "$mod, 7, workspace, 7"
        "$mod, 8, workspace, 8"
        "$mod, 9, workspace, 9"
        "$mod, 0, workspace, 10"

        # Move to workspace
        "$mod SHIFT, 1, movetoworkspace, 1"
        "$mod SHIFT, 2, movetoworkspace, 2"
        "$mod SHIFT, 3, movetoworkspace, 3"
        "$mod SHIFT, 4, movetoworkspace, 4"
        "$mod SHIFT, 5, movetoworkspace, 5"
        "$mod SHIFT, 6, movetoworkspace, 6"
        "$mod SHIFT, 7, movetoworkspace, 7"
        "$mod SHIFT, 8, movetoworkspace, 8"
        "$mod SHIFT, 9, movetoworkspace, 9"
        "$mod SHIFT, 0, movetoworkspace, 10"

        # Special workspace
        "$mod, S, togglespecialworkspace, magic"
        "$mod SHIFT, S, movetoworkspace, special:magic"
      ];

      bindm = [
        "$mod, mouse:272, movewindow"
        "$mod, mouse:273, resizewindow"
      ];
    };
    };

    # Session variables for Wayland
    home.sessionVariables = {
      NIXOS_OZONE_WL = "1"; # Hint Electron apps to use Wayland
    };

    # Enable required programs
    programs.kitty.enable = true; # Required for default Hyprland config

    # Essential packages
    home.packages = with pkgs; [
      wofi
      dolphin
      waybar
      dunst
      grim
      slurp
      wl-clipboard
      swww
    ];

    # GTK theme configuration
    gtk = {
      enable = true;
      theme = {
        name = config.wayland.windowManager.hyprflake.theme.gtkTheme;
      };
      iconTheme = {
        name = config.wayland.windowManager.hyprflake.theme.iconTheme;
      };
      cursorTheme = {
        name = config.wayland.windowManager.hyprflake.theme.cursorTheme;
        size = config.wayland.windowManager.hyprflake.theme.cursorSize;
      };
    };

    # Services
    services.dunst.enable = true;
  };
}