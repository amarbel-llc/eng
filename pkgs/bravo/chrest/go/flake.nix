{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";

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
