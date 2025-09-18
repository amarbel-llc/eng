{
  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
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
