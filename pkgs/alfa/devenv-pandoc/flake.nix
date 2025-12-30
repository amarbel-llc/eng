{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
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
