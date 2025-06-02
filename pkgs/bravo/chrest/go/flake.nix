{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "nixpkgs/release-24.11";
    utils.url = "github:numtide/flake-utils";

    devenv-go.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-go";
    devenv-shell.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-shell";
  };

  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    utils,
    devenv-go,
    devenv-shell,
  }:
    (utils.lib.eachDefaultSystem
      (system:
        let
          pkgs = import nixpkgs {
            inherit system;

            overlays = [
              devenv-go.overlays.default
            ];
          };

        in
        {
          packages.default = pkgs.buildGoModule {
            doCheck = false;
            enableParallelBuilding = true;
            pname = "chrest";
            version = "0.0.0";
            src = ./.;
            vendorHash = "sha256-BOwTBGeC8qTdslNsKVluMnZPBLxnEAPaotED5/mSgc8=";
            proxyVendor = true;
          };

          devShells.default = pkgs.mkShell {
            packages = (with pkgs; [
              bats
              fish
              gnumake
              just
            ]);

            inputsFrom = [
              devenv-go.devShells.${system}.default
              devenv-shell.devShells.${system}.default
            ];
          };
        })
    );
}
