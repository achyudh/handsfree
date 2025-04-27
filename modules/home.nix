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
      whisper = {
        beam_size = mkOption {
          type = types.ints.positive;
          default = 3;
          description = mdDoc "Beam size for decoding.";
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
          description = mdDoc "Computation type.";
        };
        cpu_threads = mkOption {
          type = types.ints.unsigned;
          default = 0;
          description = mdDoc "Number of CPU threads for inference";
        };
        device = mkOption {
          type = types.enum [ "auto" "cpu" "cuda" ];
          default = "auto";
          description = mdDoc "Device for inference.";
        };
        language = mkOption {
          type = types.str;
          default = "";
          description = mdDoc "Language code (auto-detect by default).";
        };
        model = mkOption {
          type = types.str;
          default = "base.en";
          description = mdDoc "Whisper model identifier.";
        };
      };

      vad = {
        enabled = mkOption {
          type = types.bool;
          default = true;
          description = mdDoc "Enable VAD segmentation.";
        };
        threshold = mkOption {
          type = types.float;
          default = 0.5;
          description = mdDoc "VAD probability threshold (0.0-1.0).";
        };
        neg_threshold = mkOption {
          type = types.float;
          default = 0.35;
          description = mdDoc "VAD negative threshold (0.0-1.0).";
        };
        min_speech_duration_ms = mkOption {
          type = types.ints.unsigned;
          default = 256;
          description = mdDoc "Min speech duration (ms) to process.";
        };
        min_silence_duration_ms = mkOption {
          type = types.ints.positive;
          default = 1024;
          description = mdDoc "Silence duration (ms) to end segment.";
        };
        max_speech_duration_s = mkOption {
          type = types.float;
          default = 30.0;
          description = mdDoc "Max segment duration (s) (0=infinity).";
        };
        pre_roll_duration_ms = mkOption {
          type = types.ints.unsigned;
          default = 192;
          description = mdDoc "Pre-roll audio duration (ms).";
        };
      };

      output = {
        keyboard_command = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = mdDoc "Keyboard output command.";
        };
        clipboard_command = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = mdDoc "Clipboard output command.";
        };
      };

      daemon = {
        log_level = mkOption {
          type = types.enum [ "DEBUG" "INFO" "WARNING" "ERROR" ];
          default = "INFO";
          description = mdDoc "Daemon logging level.";
        };
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package cfg.ctlPackage ];

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
