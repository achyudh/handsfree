{
  description = "Handsfree: A speech-to-text utility";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    handsfreectl-src = {
      url = "github:achyudh/handsfreectl";
      flake = false;
    };
    handsfreed-src = {
      url = "github:achyudh/handsfreed";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, handsfreectl-src, handsfreed-src
    , home-manager }@inputs:
    let
      systemSpecificOutputs = flake-utils.lib.eachDefaultSystem (system:
        let
          pkgs = import nixpkgs { inherit system; };
          pythonPackages = pkgs.python3Packages;

          handsfreectl-pkg = pkgs.callPackage ./packages/handsfreectl.nix {
            inherit pkgs;
            src = handsfreectl-src;
          };
          handsfreed-pkg = pkgs.callPackage ./packages/handsfreed.nix {
            inherit pkgs;
            inherit pythonPackages;
            src = handsfreed-src;
          };

        in {
          apps = {
            handsfreectl = flake-utils.lib.mkApp { drv = handsfreectl-pkg; };
            handsfreed = flake-utils.lib.mkApp { drv = handsfreed-pkg; };
          };

          devShells = {
            default = pkgs.mkShell {
              inputsFrom = [ handsfreectl-pkg handsfreed-pkg ];
              packages = with pkgs; [
                cargo
                clippy
                rustfmt
                rust-analyzer
                pythonPackages.python
                basedpyright
                ruff
              ];
            };
          };

          packages = {
            handsfreectl = handsfreectl-pkg;
            handsfreed = handsfreed-pkg;
          };
        });

    in systemSpecificOutputs // {
      homeManagerModules = {
        default = import ./modules/home.nix;
        handsfree = self.homeManagerModules.default;
      };

      overlay = final: prev: {
        handsfreed = self.packages.${prev.system}.handsfreed;
        handsfreectl = self.packages.${prev.system}.handsfreectl;
      };

      packages = systemSpecificOutputs.packages // {
        default = self.packages.${builtins.currentSystem}.handsfreectl;
      };
    };
}
