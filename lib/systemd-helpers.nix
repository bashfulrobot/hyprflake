{ lib }:

{
  # Build a home-manager systemd user-service definition that's bound to the
  # graphical session (Hyprland). Use for daemons that should start with the
  # session and stop when it ends.
  #
  # Example:
  #   systemd.user.services.swayosd-libinput-backend = mkGraphicalUserService {
  #     description = "SwayOSD LibInput Backend";
  #     exec        = "${pkgs.swayosd}/bin/swayosd-libinput-backend";
  #     restart     = "always";
  #     restartSec  = 3;
  #   };
  mkGraphicalUserService =
    { description
    , exec
    , documentation ? null
    , restart ? "on-failure"
    , restartSec ? 5
    , environment ? null
    }: {
      Unit = {
        Description = description;
        PartOf = [ "graphical-session.target" ];
        After = [ "graphical-session.target" ];
      } // lib.optionalAttrs (documentation != null) {
        Documentation = documentation;
      };
      Service = {
        Type = "simple";
        ExecStart = exec;
        Restart = restart;
        RestartSec = restartSec;
      } // lib.optionalAttrs (environment != null) {
        Environment = environment;
      };
      Install = {
        WantedBy = [ "graphical-session.target" ];
      };
    };
}
