{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
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
