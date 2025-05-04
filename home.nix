{ config, lib, pkgs, ... }:

{
  # Import the Hyprland module
  wayland.windowManager.hyprland = {
    enable = true;
    xwayland.enable = true;
    systemd.enable = true;

    # Basic configuration
    settings = {
      general = {
        layout = "dwindle";
        gaps_in = 5;
        gaps_out = 10;
        border_size = 2;
        "col.active_border" = "rgba(33ccffee)";
        "col.inactive_border" = "rgba(595959aa)";
      };

      input = {
        kb_layout = "us";
        follow_mouse = 1;
        touchpad = { natural_scroll = "true"; };
        sensitivity = 0;
      };

      dwindle = {
        pseudotile = true;
        preserve_split = true;
      };

      gestures = { workspace_swipe = true; };

      misc = { force_default_wallpaper = 0; };
    };

    # Custom keybindings
    extraConfig = ''
      # Start terminal
      bind = SUPER, Return, exec, kitty

      # Start launcher
      bind = SUPER, D, exec, wofi --show drun

      # Close active window
      bind = SUPER, Q, killactive,

      # Exit Hyprland
      bind = SUPER SHIFT, M, exit,

      # Move focus
      bind = SUPER, left, movefocus, l
      bind = SUPER, right, movefocus, r
      bind = SUPER, up, movefocus, u
      bind = SUPER, down, movefocus, d

      # Switch workspaces
      bind = SUPER, 1, workspace, 1
      bind = SUPER, 2, workspace, 2
      bind = SUPER, 3, workspace, 3
      bind = SUPER, 4, workspace, 4
      bind = SUPER, 5, workspace, 5

      # Move windows to workspaces
      bind = SUPER SHIFT, 1, movetoworkspace, 1
      bind = SUPER SHIFT, 2, movetoworkspace, 2
      bind = SUPER SHIFT, 3, movetoworkspace, 3
      bind = SUPER SHIFT, 4, movetoworkspace, 4
      bind = SUPER SHIFT, 5, movetoworkspace, 5

      # Screenshot
      bind = SUPER, S, exec, grim -g "$(slurp)" - | wl-copy

      # Autostart
      exec-once = waybar
      exec-once = mako
    '';
  };

  # Install user packages
  home.packages = with pkgs; [
    # Terminal
    kitty

    # File manager
    ranger

    # Media
    imv
    mpv

    # Theming
    papirus-icon-theme

    # Utils
    ripgrep
    fd
    fzf
    bat
  ];

  # Configure programs
  programs = {
    waybar = {
      enable = true;
      settings = {
        mainBar = {
          layer = "top";
          position = "top";
          height = 30;
          modules-left = [ "hyprland/workspaces" ];
          modules-center = [ "hyprland/window" ];
          modules-right = [ "network" "cpu" "memory" "battery" "clock" "tray" ];
        };
      };
    };

    mako = {
      enable = true;
      defaultTimeout = 5000;
    };
  };

  # Set GTK theme
  gtk = {
    enable = true;
    theme = {
      name = "Adwaita-dark";
      package = pkgs.gnome.gnome-themes-extra;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
  };
}
