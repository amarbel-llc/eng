{
  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    utils.url = "github:numtide/flake-utils";
    utils-pandoc.url  = "github:friedenberg/dev-flake-templates?dir=pandoc";
    resume-builder.url = "path:../../bravo/resume-builder";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    utils,
    utils-pandoc,
    resume-builder,
  }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };

      in rec {
        devShells.default = pkgs.mkShell {
          packages = (with pkgs; [
            resume-builder.packages.${system}.resume-builder
          ]);

          inputsFrom = [];
        };
      }
    );
}
