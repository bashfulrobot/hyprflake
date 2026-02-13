{ config, lib, pkgs, ... }:

let
  cfg = config.hyprflake.desktop.voxtype;

  configToml = pkgs.writeText "config.toml" ''
    state_file = "auto"

    [hotkey]
    key = "${lib.strings.toUpper cfg.hotkey}"
    modifiers = []

    [audio]
    device = "default"
    sample_rate = 16000
    max_duration_secs = 60

    [whisper]
    model = "${cfg.model}"
    language = "en"
    translate = false${lib.optionalString (cfg.threads != null) "\nthreads = ${toString cfg.threads}"}

    [output]
    mode = "type"
    fallback_to_clipboard = true
    type_delay_ms = 0
    pre_output_command = "hyprctl dispatch submap voxtype_suppress"
    post_output_command = "hyprctl dispatch submap reset"

    [output.notification]
    on_recording_start = false
    on_recording_stop = false
    on_transcription = false
  '';

  hyprlandSubmap = pkgs.writeText "voxtype-submap.conf" ''
    # Voxtype compositor integration
    # Fixes modifier key interference when using compositor keybindings

    # Recording submap - active during recording and transcription
    # F12 cancels recording/transcription and returns to normal
    submap = voxtype_recording
    bind = , F12, exec, voxtype record cancel
    bind = , F12, submap, reset
    submap = reset

    # Output submap - blocks modifier keys during text output
    submap = voxtype_suppress
    bind = , SUPER_L, exec, true
    bind = , SUPER_R, exec, true
    bind = , Control_L, exec, true
    bind = , Control_R, exec, true
    bind = , Alt_L, exec, true
    bind = , Alt_R, exec, true
    bind = , Shift_L, exec, true
    bind = , Shift_R, exec, true
    bind = , F12, submap, reset
    submap = reset
  '';
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    home-manager.sharedModules = [
      (_: {
        # Voxtype configuration
        xdg.configFile."voxtype/config.toml".source = configToml;

        # Hyprland submap for modifier suppression during output
        xdg.configFile."hypr/conf.d/voxtype-submap.conf".source = hyprlandSubmap;

        # Systemd user service for the daemon
        systemd.user.services.voxtype = {
          Unit = {
            Description = "Voxtype push-to-talk voice-to-text daemon";
            Documentation = "https://voxtype.io";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            ExecStart = "${cfg.package}/bin/voxtype daemon";
            Restart = "on-failure";
            RestartSec = 5;
            Environment = "XDG_RUNTIME_DIR=%t";
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };
      })
    ];
  };
}
