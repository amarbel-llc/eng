{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/d981d41ffe5b541eae3782029b93e2af5d229cc2";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/09eb77e94fa25202af8f3e81ddc7353d9970ac1b";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    { self
    , nixpkgs-stable
    , utils
    , nixpkgs
    }:
    (utils.lib.eachDefaultSystem
      (system:
      let

        pkgs = import nixpkgs-stable
          {
            inherit system;
          };

      in
      {
        meta = {
          mainProgram = pkgs.direnv;
        };

        packages = {
          default = with pkgs; buildEnv {
            name = "direnv";
            paths = [
              direnv
            ];
          };
        };

      })
    );
}
