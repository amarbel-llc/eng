{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
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
