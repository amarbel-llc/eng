{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";

    devenv-go.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-go";
    devenv-js.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-js";
  };

  outputs = { self, nixpkgs, nixpkgs-stable, utils, devenv-go, devenv-js }:
    (utils.lib.eachDefaultSystem
      (system:
        let

          pkgs = import nixpkgs {
            inherit system;
            overlays = [
              devenv-go.overlays.default
            ];
          };

          chrest = pkgs.buildGoApplication {
            name = "chrest";
            pname = "chrest";
            version = "0.0.1";
            pwd = ./go/cmd;
            src = ./go/cmd;
            modules = ./go/cmd/gomod2nix.toml;
            doCheck = false;
            enableParallelBuilding = true;
          };

        in
        {
          devShells.default = pkgs.mkShell {
            packages = (with pkgs; [
              fish
              gnumake
              httpie
              jq
              just
              web-ext
            ]);

            inputsFrom = [
              devenv-go.devShells.${system}.default
              devenv-js.devShells.${system}.default
            ];
          };

          pname = "chrest";
          packages.default = chrest;
        })
    );
}
