{ pkgs, lib, config, ... }:

with lib;

let
  cfg = config.services.handsfree;
  filteredSettings =
    filterAttrsRecursive (path: value: value != null) cfg.settings;
  tomlFormat = pkgs.formats.toml { };
in {
  options.services.handsfree = {
    enable = mkEnableOption (mdDoc "Handsfree speech-to-text daemon");

    package = mkOption {
      type = types.package;
      default = pkgs.handsfreed;
      defaultText = literalExpression "self.packages.${pkgs.system}.handsfreed";
      description = mdDoc "The handsfreed daemon package to use.";
    };

    ctlPackage = mkOption {
      type = types.package;
      default = pkgs.handsfreectl;
      defaultText =
        literalExpression "self.packages.${pkgs.system}.handsfreectl";
      description = mdDoc "The handsfreectl control package to use.";
    };

    settings = {
      audio = {
        input_gain = mkOption {
          type = types.float;
          default = 1.0;
          description = mdDoc "Input gain multiplier (1.0 = no gain).";
        };
        dc_offset_correction = mkOption {
          type = types.bool;
          default = true;
          description = mdDoc "Enable DC offset correction for raw audio.";
        };
        dc_offset_window_ms = mkOption {
          type = types.ints.unsigned;
          default = 512;
          description = mdDoc "Window size for DC offset calculation (ms).";
        };
      };

      whisper = {
        beam_size = mkOption {
          type = types.ints.positive;
          default = 3;
          description = mdDoc "Beam size for search (1-10, higher is slower but more accurate).";
        };
        compute_type = mkOption {
          type = types.enum [
            "auto"
            "int8"
            "int8_float16"
            "int16"
            "float16"
            "float32"
          ];
          default = "auto";
          description = mdDoc "Compute type for inference (auto, float32, float16, int8).";
        };
        cpu_threads = mkOption {
          type = types.ints.unsigned;
          default = 0;
          description = mdDoc "Number of CPU threads for inference (0 = auto).";
        };
        device = mkOption {
          type = types.enum [ "auto" "cpu" "cuda" ];
          default = "auto";
          description = mdDoc "Device for inference (auto, cpu, cuda).";
        };
        language = mkOption {
          type = types.str;
          default = "";
          description = mdDoc "Optional language code (empty for auto-detect).";
        };
        model = mkOption {
          type = types.str;
          default = "base.en";
          description = mdDoc "Whisper model identifier (e.g., small.en, medium.en).";
        };
      };

      vad = {
        enabled = mkOption {
          type = types.bool;
          default = true;
          description = mdDoc "Enable Voice Activity Detection.";
        };
        threshold = mkOption {
          type = types.float;
          default = 0.5;
          description = mdDoc "Speech probability threshold (0.0-1.0).";
        };
        neg_threshold = mkOption {
          type = types.float;
          default = 0.35;
          description = mdDoc "Negative threshold for speech detection (0.0-1.0, optional).";
        };
        min_speech_duration_ms = mkOption {
          type = types.ints.unsigned;
          default = 256;
          description = mdDoc "Minimum duration for a speech segment (ms).";
        };
        min_silence_duration_ms = mkOption {
          type = types.ints.positive;
          default = 1024;
          description = mdDoc "Minimum duration of silence to end a speech segment (ms).";
        };
        max_speech_duration_s = mkOption {
          type = types.float;
          default = 30.0;
          description = mdDoc "Maximum duration of a single speech segment in seconds (0 = unlimited).";
        };
        auto_disable_duration_s = mkOption {
          type = types.float;
          default = 5.0;
          description = mdDoc
            "Maximum duration in seconds before listening stops (0 = disabled).";
        };
        pre_roll_duration_ms = mkOption {
          type = types.ints.unsigned;
          default = 192;
          description = mdDoc
            "Pre-roll duration to include before a detected speech segment (ms).";
        };
      };

      output = {
        keyboard_command = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = mdDoc "Command to execute for keyboard output.";
        };
        clipboard_command = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = mdDoc "Command to execute for clipboard output.";
        };
      };

      daemon = {
        log_level = mkOption {
          type = types.enum [ "DEBUG" "INFO" "WARNING" "ERROR" ];
          default = "INFO";
          description = mdDoc "Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL).";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.ctlPackage ];

    xdg.configFile."handsfree/config.toml".source =
      (tomlFormat.generate "handsfree-config.toml" filteredSettings);

    systemd.user.services.handsfreed = {
      Unit = {
        Description = "Handsfree speech-to-text daemon";
        After = [ "graphical-session.target" "network.target" "sound.target" ];
        PartOf = [ "graphical-session.target" ];
      };

      Install = { WantedBy = [ "graphical-session.target" ]; };

      Service = {
        ExecStart = "${cfg.package}/bin/handsfreed";
        Restart = "on-failure";
        RestartSec = "5s";
      };
    };
  };
}
