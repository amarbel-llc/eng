{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8bb5646e0bed5dbd3ab08c7a7cc15b75ab4e1d0f";
    nixpkgs.url = "github:NixOS/nixpkgs/bd708996359444aa54ea97e10779ebc1eb6dad34";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    devenv-lua.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-lua";
  };

  outputs = { self, nixpkgs, utils, devenv-lua, nixpkgs-stable }:
    (utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };

        in

        {
          devShells.default = pkgs.mkShell {
            packages = with pkgs; [
              pandoc
            ];

            inputsFrom = [
              devenv-lua.devShells.${system}.default
            ];
          };
        })
    );
}
