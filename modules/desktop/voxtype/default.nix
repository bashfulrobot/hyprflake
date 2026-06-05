{ config
, lib
, pkgs
, hyprflakeInputs
, ...
}:

let
  cfg = config.hyprflake.desktop.voxtype;

  systemdHelpers = import ../../../lib/systemd-helpers.nix { inherit lib; };

  # Map common evdev key names to Hyprland (XKB) key names
  hyprlandKeyMap = {
    "SCROLLLOCK" = "Scroll_Lock";
    "INSERT" = "Insert";
    "PAUSE" = "Pause";
    "RIGHTALT" = "Alt_R";
  };
  hyprlandHotkey = hyprlandKeyMap.${lib.strings.toUpper cfg.hotkey} or cfg.hotkey;

  hyprlandSubmap = pkgs.writeText "voxtype-submap.conf" ''
    # Voxtype compositor integration
    # Fixes modifier key interference when using compositor keybindings

    # Consume the hotkey at compositor level so terminals don't receive it
    # as input (e.g. Kitty protocol encodes it as [57359u). Voxtype reads
    # evdev directly so push-to-talk is unaffected.
    bind = , ${hyprlandHotkey}, exec, true
    bindr = , ${hyprlandHotkey}, exec, true

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
  options.hyprflake.desktop.voxtype = {
    enable = lib.mkEnableOption "Voxtype push-to-talk voice-to-text with whisper.cpp";

    package = lib.mkOption {
      type = lib.types.package;
      inherit (hyprflakeInputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system}) default;
      description = ''
        The voxtype package to use.
        Defaults to the voxtype package from hyprflake's input.
      '';
    };

    hotkey = lib.mkOption {
      type = lib.types.str;
      default = "SCROLLLOCK";
      example = "SCROLLLOCK";
      description = ''
        Evdev key name for push-to-talk activation.
        Hold to record, release to transcribe.

        Common choices: INSERT, SCROLLLOCK, PAUSE, RIGHTALT, F13-F24
        Use `evtest` to find key names for your keyboard.
      '';
    };

    model = lib.mkOption {
      type = lib.types.str;
      default = "base.en";
      example = "tiny.en";
      description = ''
        Whisper model for transcription.
        .en models are English-only but faster and more accurate for English.

        Options: tiny, tiny.en, base, base.en, small, small.en,
                 medium, medium.en, large-v3, large-v3-turbo
      '';
    };

    threads = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 4;
      description = ''
        Number of CPU threads for Whisper inference.
        When null (default), voxtype uses its own default.
        Should not exceed the number of physical CPU cores.
        Lower values reduce CPU usage; higher values speed up transcription.
      '';
    };

    language = lib.mkOption {
      type = lib.types.str;
      default = "en";
      example = "auto";
      description = ''
        Language code for Whisper transcription.
        Use a BCP-47 language code (e.g. "en", "fr", "de") or "auto"
        for automatic detection.
      '';
    };

    backend = lib.mkOption {
      type = lib.types.enum [
        "local"
        "remote"
      ];
      default = "local";
      example = "remote";
      description = ''
        Whisper execution backend.
        "local" runs whisper.cpp locally, "remote" sends audio to a
        remote whisper.cpp server or OpenAI-compatible API.
      '';
    };

    remoteEndpoint = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "http://192.168.1.100:8080";
      description = ''
        Base URL of the remote Whisper server.
        Required when backend is "remote". Must include protocol
        (http:// or https://). Audio is transmitted over the network,
        so use HTTPS for non-localhost connections.
      '';
    };

    remoteTimeoutSecs = lib.mkOption {
      type = lib.types.int;
      default = 30;
      example = 60;
      description = ''
        Maximum wait time in seconds for the remote server to respond.
        Only used when backend is "remote".
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.backend == "remote" -> cfg.remoteEndpoint != null;
        message = "hyprflake.desktop.voxtype.remoteEndpoint must be set when backend is \"remote\".";
      }
    ];

    environment.systemPackages = [ cfg.package ];

    # Voxtype's push-to-talk daemon runs as the user and reads keyboard
    # evdev directly to detect its hotkey. Without read access to
    # /dev/input/event* (root:input 0660) it logs "No keyboard device
    # found in /dev/input/" and dictation silently dies. Rather than add
    # the user to the broad `input` group, grant the active-seat user an
    # ACL on keyboard devices (incl. the keyd virtual keyboard) via the
    # uaccess tag — scoped to the login session.
    #
    # The 70- prefix is deliberate: the rule must run AFTER
    # 60-input-id.rules (which sets ID_INPUT_KEYBOARD) and BEFORE
    # 73-seat-late.rules (which invokes the uaccess builtin). NixOS
    # services.udev.extraRules land in 99-local.rules — too late for
    # uaccess to take effect — so this ships as a package instead.
    services.udev.packages = [
      (pkgs.writeTextFile {
        name = "voxtype-uaccess-udev-rules";
        destination = "/etc/udev/rules.d/70-voxtype-uaccess.rules";
        text = ''
          ACTION=="add|change", SUBSYSTEM=="input", KERNEL=="event*", ENV{ID_INPUT_KEYBOARD}=="1", TAG+="uaccess"
        '';
      })
    ];

    home-manager.sharedModules = [
      (
        { config, ... }:
        let
          configToml = pkgs.writeText "config.toml" ''
            state_file = "${config.home.homeDirectory}/.local/share/voxtype/state.toml"

            [hotkey]
            key = "${lib.strings.toUpper cfg.hotkey}"
            modifiers = []

            [audio]
            device = "default"
            sample_rate = 16000
            max_duration_secs = 60

            [whisper]
            backend = "${cfg.backend}"
            model = "${cfg.model}"
            language = "${cfg.language}"
            translate = false${lib.optionalString (cfg.threads != null) "\nthreads = ${toString cfg.threads}"}${
              lib.optionalString (cfg.backend == "remote") ''

                remote_endpoint = "${cfg.remoteEndpoint}"
                remote_timeout_secs = ${toString cfg.remoteTimeoutSecs}''
            }

            [text]
            spoken_punctuation = true

            [output]
            mode = "type"
            fallback_to_clipboard = true
            type_delay_ms = 0
            # Lua-backend dispatch syntax: hyprctl dispatch evals as
            # hl.dispatch(...). Legacy `submap voxtype_suppress` parses
            # wrong; use hl.dsp.submap("...") instead.
            pre_output_command = "hyprctl dispatch 'hl.dsp.submap(\"voxtype_suppress\")'"
            post_output_command = "hyprctl dispatch 'hl.dsp.submap(\"reset\")'"

            [output.notification]
            on_recording_start = false
            on_recording_stop = false
            on_transcription = false
          '';
        in
        {
          # Voxtype configuration
          xdg.configFile."voxtype/config.toml".source = configToml;

          # Hyprland submap for modifier suppression during output
          xdg.configFile."hypr/conf.d/voxtype-submap.conf".source = hyprlandSubmap;

          # Systemd user service for the daemon
          systemd.user.services.voxtype = systemdHelpers.mkGraphicalUserService {
            description = "Voxtype push-to-talk voice-to-text daemon";
            documentation = "https://voxtype.io";
            exec = "${cfg.package}/bin/voxtype daemon";
            environment = "XDG_RUNTIME_DIR=%t";
          };
        }
      )
    ];
  };
}
