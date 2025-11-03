{
  description = "claude code";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    devenv-nix.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-nix";
    devenv-shell.url = "github:friedenberg/eng?dir=pkgs/alfa/devenv-shell";
  };

  outputs = { self, nixpkgs, devenv-nix, devenv-shell, nixpkgs-stable, utils }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        claude = pkgs.symlinkJoin {
          name = "claude";
          paths = with pkgs; [ claude-code ];
        };
      in
      {
        packages.default = claude;
        packages.claude = claude;

        devShells.default = pkgs.mkShell {
          buildInputs = [
            claude
          ];

          inputsFrom = [
            devenv-nix.devShells.${system}.default
            devenv-shell.devShells.${system}.default
          ];
        };
      });
}
