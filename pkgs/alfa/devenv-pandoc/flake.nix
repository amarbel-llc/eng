{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    utils.url = "github:numtide/flake-utils";

    devenv-lua.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-lua";
  };

  outputs = { self, nixpkgs, utils, devenv-lua }:
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
