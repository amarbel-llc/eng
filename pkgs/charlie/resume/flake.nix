{
  inputs = {
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.11";
    utils.url = "github:numtide/flake-utils";
    devenv-pandoc.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-pandoc";
    resume-builder.url = "github:friedenberg/eng?dir=pkgs/bravo/resume-builder";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , utils
    , devenv-pandoc
    , resume-builder
    ,
    }:
    utils.lib.eachDefaultSystem (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };

    in
    {
      devShells.default = pkgs.mkShell {
        packages = [
          resume-builder.packages.${system}.resume-builder
        ];

        inputsFrom = [
          devenv-pandoc.devShells.${system}.default
        ];
      };
    }
    );
}
