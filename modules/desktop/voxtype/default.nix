{ config
, lib
, pkgs
, hyprflakeInputs
, ...
}:

let
  cfg = config.hyprflake.desktop.voxtype;

  systemdHelpers = import ../../../lib/systemd-helpers.nix { inherit lib; };

  voxtypePackages = hyprflakeInputs.voxtype.packages.${pkgs.stdenv.hostPlatform.system};

  # Map a friendly acceleration name to the matching voxtype flake variant.
  # "cpu" is the portable whisper.cpp build; the GPU variants are Linux-only
  # and need the corresponding runtime (a Vulkan ICD or ROCm) present on the
  # host. This spares consumers from reaching into voxtype's flake outputs by
  # hand (e.g. inputs.hyprflake.inputs.voxtype.packages.<system>.vulkan).
  accelerationPackage = {
    cpu = voxtypePackages.default;
    inherit (voxtypePackages) vulkan rocm;
  }.${cfg.acceleration};
in
{
  options.hyprflake.desktop.voxtype = {
    enable = lib.mkEnableOption "Voxtype push-to-talk voice-to-text with whisper.cpp";

    acceleration = lib.mkOption {
      type = lib.types.enum [ "cpu" "vulkan" "rocm" ];
      default = "cpu";
      example = "vulkan";
      description = ''
        Hardware acceleration backend for whisper.cpp inference. Selects the
        matching variant from voxtype's flake:

        - "cpu": portable build, no GPU required (default).
        - "vulkan": GPU acceleration via Vulkan (AMD, Intel Arc, or NVIDIA).
        - "rocm": AMD GPU acceleration via ROCm.

        voxtype ships no whisper.cpp CUDA build, so NVIDIA users should use
        "vulkan". The GPU variants are Linux-only. Ignored when `package` is
        set explicitly.
      '';
    };

    package = lib.mkOption {
      type = lib.types.package;
      default = accelerationPackage;
      defaultText = lib.literalExpression ''voxtype.packages.''${system}.<acceleration variant>'';
      description = ''
        The voxtype package to use. Defaults to the variant chosen by
        `acceleration`. Set explicitly to override (for example, to use a
        Parakeet or ONNX build not covered by the `acceleration` enum).
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

    vad = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Enable Voice Activity Detection. VAD drops silence-only recordings
          before they reach whisper, which prevents whisper from hallucinating
          unrelated text on empty or near-silent audio (e.g. when push-to-talk
          is released without speech, or the mic momentarily captures nothing).

          On by default because it fixes a common push-to-talk failure mode.
          Disable it if a quiet speaker or low mic gain causes real speech to be
          dropped, or lower `vad.threshold` to make detection more sensitive.
        '';
      };

      backend = lib.mkOption {
        type = lib.types.enum [
          "auto"
          "energy"
          "whisper"
        ];
        default = "energy";
        example = "whisper";
        description = ''
          VAD detection backend.

          - "energy": RMS-amplitude detection, needs no model file (default).
          - "whisper": Silero VAD, more accurate but requires the
            ggml-silero-vad.bin model present under voxtype's models dir.
          - "auto": whisper VAD for the whisper engine, energy VAD otherwise.

          "energy" is the default so the module needs no model provisioning.
        '';
      };

      threshold = lib.mkOption {
        type = lib.types.float;
        default = 0.5;
        example = 0.3;
        description = ''
          Speech detection threshold, 0.0 (most sensitive) to 1.0 (most
          aggressive). Lower it if real speech is being dropped.
        '';
      };

      minSpeechDurationMs = lib.mkOption {
        type = lib.types.int;
        default = 100;
        example = 250;
        description = ''
          Minimum detected speech duration, in milliseconds, for a recording to
          be transcribed. Recordings with less are treated as silence.
        '';
      };
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
            # voxtype renamed this key from `backend` to `mode` (the old name
            # still parses but logs a deprecation warning). Values are unchanged.
            mode = "${cfg.backend}"
            model = "${cfg.model}"
            language = "${cfg.language}"
            translate = false${lib.optionalString (cfg.threads != null) "\nthreads = ${toString cfg.threads}"}${
              lib.optionalString (cfg.backend == "remote") ''

                remote_endpoint = "${cfg.remoteEndpoint}"
                remote_timeout_secs = ${toString cfg.remoteTimeoutSecs}''
            }

            [vad]
            # Filter silence-only recordings so whisper can't hallucinate
            # unrelated text on empty audio. Energy backend needs no model file.
            enabled = ${lib.boolToString cfg.vad.enable}
            backend = "${cfg.vad.backend}"
            threshold = ${toString cfg.vad.threshold}
            min_speech_duration_ms = ${toString cfg.vad.minSpeechDurationMs}

            [text]
            spoken_punctuation = true

            [output]
            mode = "type"
            fallback_to_clipboard = true
            type_delay_ms = 0

            [output.notification]
            on_recording_start = false
            on_recording_stop = false
            on_transcription = false
          '';
        in
        {
          # Voxtype configuration. Push-to-talk reads evdev directly, so no
          # Hyprland keybinding or submap wiring is needed. DankMaterialShell's
          # privacyIndicator shows when the microphone is live.
          xdg.configFile."voxtype/config.toml".source = configToml;

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
