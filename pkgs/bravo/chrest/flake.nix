{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
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
