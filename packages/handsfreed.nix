{ pkgs, lib ? pkgs.lib, pythonPackages, src }:

pythonPackages.buildPythonApplication rec {
  pname = "handsfreed";
  version = (lib.importTOML "${src}/pyproject.toml").project.version;

  inherit src;

  format = "pyproject";

  propagatedBuildInputs = with pythonPackages; [
    pydantic
    sounddevice
    numpy
    faster-whisper
  ];

  nativeBuildInputs = with pkgs; [ pythonPackages.setuptools pkg-config ];

  buildInputs = with pkgs; [ portaudio ];

  doCheck = true;
  checkInputs = with pythonPackages; [ pytest pytest-asyncio ];

  meta = with lib; {
    description = "Handsfree speech-to-text daemon";
    homepage = "https://github.com/achyudh/handsfreed";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
