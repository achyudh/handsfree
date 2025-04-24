{ pkgs, lib ? pkgs.lib, src }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "handsfreectl";
  version = (lib.importTOML "${src}/Cargo.toml").package.version;

  inherit src;

  cargoLock.lockFile = "${src}/Cargo.lock";

  nativeBuildInputs = [ pkgs.pkg-config ];

  meta = with lib; {
    description = "CLI for the Handsfree speech-to-text daemon";
    homepage = "https://github.com/achyudh/handsfreectl";
    license = licenses.gpl3;
    platforms = platforms.linux;
  };
}
