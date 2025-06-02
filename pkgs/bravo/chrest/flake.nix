{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-24.11";
    utils.url = "github:numtide/flake-utils";

    devenv-go.url = "path:../../alfa/devenv-go";
    devenv-js.url = "path:../../alfa/devenv-js";
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
