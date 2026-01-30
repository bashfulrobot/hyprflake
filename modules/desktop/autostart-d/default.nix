{ config, lib, ... }:

let
  cfg = config.hyprflake.desktop.autostartD;
in
{
  options.hyprflake.desktop.autostartD = {
    enable = lib.mkEnableOption "Hyprland .d directory autostart pattern" // {
      default = true;
    };

    execOnce = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "10-polkit" = "systemctl --user start polkit-gnome-authentication-agent-1";
        "20-telegram" = "telegram-desktop -startintray";
      };
      description = ''
        Nix-managed exec-once entries.

        Keys are filenames (without .conf extension), values are commands.
        Use numeric prefixes (00-, 10-, 20-) to control execution order.

        Commands run only at initial Hyprland startup, not on reload.
      '';
    };

    exec = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        "00-wallpaper" = "hyprpaper";
        "99-notify" = "notify-send 'Hyprland reloaded'";
      };
      description = ''
        Nix-managed exec entries.

        Keys are filenames (without .conf extension), values are commands.
        Use numeric prefixes (00-, 10-, 20-) to control execution order.

        Commands run on every Hyprland start AND reload.
        Use sparingly - prefer exec-once for most applications.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    home-manager.sharedModules = [
      (_: {
        # Create directories and Nix-managed entries
        xdg.configFile =
          # Ensure directories exist with .keep files
          {
            "hypr/exec-once.d/.keep".text = "";
            "hypr/exec.d/.keep".text = "";
          }
          # Add Nix-managed exec-once entries
          // lib.mapAttrs'
            (name: cmd: {
              name = "hypr/exec-once.d/${name}.conf";
              value.text = "exec-once = ${cmd}\n";
            })
            cfg.execOnce
          # Add Nix-managed exec entries
          // lib.mapAttrs'
            (name: cmd: {
              name = "hypr/exec.d/${name}.conf";
              value.text = "exec = ${cmd}\n";
            })
            cfg.exec;

        # Add source directives to Hyprland config
        wayland.windowManager.hyprland.extraConfig = ''
          # Autostart.d pattern - drop .conf files in these directories
          # Files are processed in alphanumeric order (use 00-, 10-, 20- prefixes)
          source = ~/.config/hypr/exec-once.d/*.conf
          source = ~/.config/hypr/exec.d/*.conf
        '';
      })
    ];
  };
}
