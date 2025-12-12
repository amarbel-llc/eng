{
  description = "claude code";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/09eb77e94fa25202af8f3e81ddc7353d9970ac1b";
    nixpkgs.url = "github:NixOS/nixpkgs/d981d41ffe5b541eae3782029b93e2af5d229cc2";
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
