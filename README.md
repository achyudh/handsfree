# Handsfree

A local, real-time speech-to-text utility for Linux using Whisper.

## Overview

Handsfree is a utility that provides fast, local speech-to-text transcription for Linux. Transcription is performed entirely offline on your machine via the efficient `faster-whisper` library based on OpenAI's Whisper model. It's controlled via a simple command-line interface (`handsfreectl`) and is designed primarily for dictation, outputting the transcribed text either as simulated keyboard input or directly to the system clipboard. This makes it particularly suitable for Linux desktop users who need a flexible hands-free input method.

**Current Status:** Handsfree is in active development and used daily by the maintainer.

## Motivation

Handsfree aims to:

* Fill a gap in easy-to-use **real-time dictation utilities** specifically for **Linux desktop environments**.
* Provide a robust, **entirely offline** speech-to-text solution, keeping your data private.
* Offer a flexible and customizable utility that is tailored to your workflow. You control how dictation is triggered (e.g., mapping `handsfreectl` commands to window manager keybindings) and how the daemon is managed (e.g., using the provided systemd user service).

## Key Features:
* Local & Private: All audio processing and transcription happens on your machine.
* High-Quality Transcriptions: Leverages the `faster-whisper` library based on OpenAI's Whisper model for accurate results.
* Flexible Control: Simple CLI (`handsfreectl`) that allows starting/stopping transcription, making it easy to integrate with various triggers like keyboard shortcuts, scripts or even foot pedals.
* Configurable Output: Transcribed text can be output as simulated keyboard input or copied to the clipboard using external tools configurable via config.toml.
* Voice Activity Detection (VAD): Optional VAD using the enterprise-grade Silero model allows automatic start/stop based on speech presence.
* Configurable: Behavior tuned via a simple TOML configuration file.

## Installation

There are two main ways to install Handsfree: using the Nix Flake (recommended for most users) or building manually (primarily for contributors or non-Nix users).

### Manual Installation

This method requires you to manage dependencies and builds yourself.

**Prerequisites:**

* **Rust:** Latest stable version (`rustc` and `cargo`). Required for `handsfreectl`.
* **Python:** Version 3.11 or later with `pip` and `venv`. Required for the `handsfreed` daemon.
* **System Dependencies:** Libraries needed by Python packages (`portaudio`, `libasound2-dev` (or equivalent) for `sounddevice`). Installation methods vary by distribution.

**Steps:**

1.  **Clone Repositories:**
    ```bash
    git clone [https://github.com/achyudh/handsfreectl.git](https://github.com/achyudh/handsfreectl.git)
    git clone [https://github.com/achyudh/handsfreed.git](https://github.com/achyudh/handsfreed.git)
    ```
2.  **Build `handsfreectl`:**
    ```bash
    cd handsfreectl
    cargo build --release
    # Optional: Copy target/release/handsfreectl to a location in your $PATH
    cd ..
    ```
3.  **Set up `handsfreed`:**
    ```bash
    cd handsfreed
    python -m venv .venv
    source .venv/bin/activate
    pip install -e .
    ```
4.  **Configure:** Create the configuration file as described in the "Configuration" section below.
5.  **Run:** Manually start the daemon (see "Usage") and use the compiled `handsfreectl` binary.

**Call for Contributions:** Packaging for other distributions and other package managers is welcome! Please open an issue if you'd like to help make Handsfree more accessible.

### Nix Flake

This is the easiest and most reproducible way to install and manage Handsfree if you use the Nix package manager with Flakes enabled.

**Prerequisites:**

* Nix package manager installed.
* Flakes support enabled (add `experimental-features = nix-command flakes` to your Nix configuration if needed).
* Home Manager (optional but recommended for managing the service and configuration).

**Steps:**

1.  **Add Handsfree Flake Input:** Add this repository as an input to your system or home-manager flake configuration:
    ```nix
    # Example: flake.nix inputs section
    inputs = {
      # ... other inputs like nixpkgs, home-manager ...
      handsfree.url = "github:achyudh/handsfree";
      # Ensure nixpkgs versions match if needed
      # handsfree.inputs.nixpkgs.follows = "nixpkgs";
      # handsfree.inputs.home-manager.follows = "home-manager";
    };
    ```

2.  **Configure the Home Manager Service:** Import the module and configure the service in your `home-manager` configuration (`home.nix` or similar):
    ```nix
    # Example: home.nix
    { inputs, pkgs, config, ... }: {

      # Import the handsfree home-manager module and setup the overlay
      imports = [ inputs.handsfree.homeManagerModules.default ];
      nixpkgs.overlays = [ inputs.handsfree.overlay ];

      # Enable and configure the daemon service
      services.handsfree = {
        enable = true;
        # The module automatically configures and manages the
        # handsfreed systemd user service.

        # Check the example config.toml below for more settings
        settings = {
          whisper = {
            model = "base.en"; # Choose desired model
            device = "cpu"; # Or "cuda" if applicable
            compute_type = "int8"; # Or "auto", "float16" etc.
          };
          vad = {
            enabled = true; # Enable VAD segmentation
            min_silence_duration_ms = 1024; # Adjust silence timing
            pre_roll_duration_ms = 256;
          };
          output = {
            # Example for Wayland (using wtype/wl-copy)
            keyboard_command = "wtype -";
            clipboard_command = "wl-copy";

            # Example for X11 (using xdotool/xclip)
            # keyboard_command = "xdotool type --clearmodifiers --file -";
            # clipboard_command = "xclip -selection clipboard -in";
          };
        };
      };

      # Alternatively, you can only install the packages instead of the service
      home.packages = [ pkgs.handsfreectl pkgs.handsfreed ];
    }

3.  **Apply Configuration:** Run your NixOS or home-manager rebuild/switch command.

## Configuration (`~/.config/handsfree/config.toml`)

Handsfree uses a configuration file located at `~/.config/handsfree/config.toml`. If you are using the Nix home-manager module, the settings you provide there will generate this file automatically. If running manually, you need to create this file.

```toml
# Example configuration for handsfreed daemon

[whisper]
# Model to use (supported models: tiny.en, base.en, small.en, medium.en, large)
model = "small.en"

# Device to use for inference (auto, cpu, cuda)
device = "auto"

# Compute type for inference (auto, float32, float16, int8)
compute_type = "auto"

# Optional language code (leave empty for auto-detect)
language = "en"

# Beam size for search (1-10, higher is slower but more accurate)
beam_size = 3

# Number of CPU threads for inference (0 = auto)
cpu_threads = 0

[vad]
# Enable Voice Activity Detection
enabled = false

# Threshold for voice detection (0.0-1.0)
threshold = 0.5

# Minimum duration for a speech segment (ms)
min_speech_duration_ms = 256

# Minimum duration for a silence segment (ms)
min_silence_duration_ms = 1024

# Pre-roll duration in milliseconds (captures audio before speech starts)
pre_roll_duration_ms = 192

# Optional negative threshold (must be between 0.0 and 1.0)
neg_threshold = 0.35

# Maximum speech duration in seconds (0 = unlimited)
max_speech_duration_s = 0.0

[output]
# Command to execute for keyboard output
keyboard_command = "wtype -"

# Command to execute for clipboard output
clipboard_command = "wl-copy"

[daemon]
# Log level (DEBUG, INFO, WARNING, ERROR, CRITICAL)
log_level = "INFO"

# Optional custom log file path
# Default: ~/.local/state/handsfree/handsfreed.log
# log_file = "/var/log/handsfreed.log"

# Optional custom socket path
# Default: $XDG_RUNTIME_DIR/handsfree/daemon.sock or /tmp/handsfree-$USER.sock
# socket_path = "/var/run/handsfree/daemon.sock"

# Time chunk size in seconds for audio processing
# This is only used if VAD is disabled
# time_chunk_s = 5.0
```
