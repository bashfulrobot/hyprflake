{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake.desktop.swayosd;

  systemdHelpers = import ../../../lib/systemd-helpers.nix { inherit lib; };

  # Generate the style CSS content
  styleContent = import ./style.nix { inherit config; };

  # Write the style to a file in the store
  stylePath = pkgs.writeText "swayosd-style.css" styleContent;
in
{
  options.hyprflake.desktop.swayosd.enable = lib.mkEnableOption "SwayOSD on-screen display. Note: Hyprland volume/brightness keybindings depend on swayosd-client" // { default = true; };

  config = lib.mkIf cfg.enable {
    # SwayOSD - GTK based on-screen display for keyboard shortcuts
    # Shows volume, brightness, caps-lock indicators with Stylix theming

    # Add swayosd package to system
    environment.systemPackages = [ pkgs.swayosd ];

    # Enable udev rules for brightness control without root
    services.udev.packages = [ pkgs.swayosd ];

    # Add user to video and input groups for brightness control and caps lock detection
    users.users = lib.mkIf (config.hyprflake.user.username != null) {
      ${config.hyprflake.user.username}.extraGroups = [ "video" "input" ];
    };

    home-manager.sharedModules = [
      (_: {
        services.swayosd = {
          enable = true;

          # Use our Stylix-themed stylesheet
          inherit stylePath;

          # Top margin - 0.85 positions near bottom, visually balanced
          topMargin = 0.85;
        };

        # SwayOSD server configuration
        xdg.configFile."swayosd/config.toml".text = ''
          [server]
          show_percentage = true
          max_volume = 150
        '';

        # Enable libinput backend for caps/num/scroll lock detection
        systemd.user.services.swayosd-libinput-backend = systemdHelpers.mkGraphicalUserService {
          description = "SwayOSD LibInput Backend";
          exec = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
          restart = "always";
          restartSec = 3;
        };
      })
    ];
  };
}
