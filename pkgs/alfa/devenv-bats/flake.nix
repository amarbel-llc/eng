{
  description = "A Nix-flake-based BATS development environment";

  inputs = {
    nixpkgs-stable.url = "github:NixOS/nixpkgs/09eb77e94fa25202af8f3e81ddc7353d9970ac1b";
    nixpkgs.url = "github:NixOS/nixpkgs/d981d41ffe5b541eae3782029b93e2af5d229cc2";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs = { self, nixpkgs, utils, nixpkgs-stable }:
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
              bats
              parallel
              shellcheck
              shfmt
            ];
          };
        })
    );
}
