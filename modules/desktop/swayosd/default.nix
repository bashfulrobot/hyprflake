{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake;

  # Generate the style CSS content
  styleContent = import ./style.nix { inherit config; };

  # Write the style to a file in the store
  stylePath = pkgs.writeText "swayosd-style.css" styleContent;
in
{
  # SwayOSD - GTK based on-screen display for keyboard shortcuts
  # Shows volume, brightness, caps-lock indicators with Stylix theming

  # Add swayosd package to system
  environment.systemPackages = [ pkgs.swayosd ];

  # Enable udev rules for brightness control without root
  services.udev.packages = [ pkgs.swayosd ];

  # Add user to video and input groups for brightness control and caps lock detection
  users.users = lib.mkIf (cfg.user.username != null) {
    ${cfg.user.username}.extraGroups = [ "video" "input" ];
  };

  home-manager.sharedModules = [
    (_: {
      services.swayosd = {
        enable = true;

        # Use our Stylix-themed stylesheet
        stylePath = stylePath;

        # Top margin - 0.85 positions near bottom, visually balanced
        topMargin = 0.85;
      };

      # SwayOSD server configuration
      xdg.configFile."swayosd/config.toml".text = ''
        [server]
        show_percentage = true
        max_volume = 100
      '';

      # Enable libinput backend for caps/num/scroll lock detection
      systemd.user.services.swayosd-libinput-backend = {
        Unit = {
          Description = "SwayOSD LibInput Backend";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };
        Service = {
          Type = "simple";
          ExecStart = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
          Restart = "always";
          RestartSec = 3;
        };
        Install = {
          WantedBy = [ "graphical-session.target" ];
        };
      };
    })
  ];
}
