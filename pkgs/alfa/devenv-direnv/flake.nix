{
  inputs = {
    nixpkgs-stable.url = "nixpkgs/release-24.11";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self
    , nixpkgs-stable
    , utils
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
