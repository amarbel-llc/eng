{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";

    devenv-python.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-python";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , utils
    , devenv-python
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
        packages = with pkgs; [];

        inputsFrom = [
          devenv-python.devShells.${system}.default
        ];
      };
    }
    );
}
