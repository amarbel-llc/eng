{
  description = "A Nix-flake-based Nix development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/d981d41ffe5b541eae3782029b93e2af5d229cc2";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/09eb77e94fa25202af8f3e81ddc7353d9970ac1b";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.21.tar.gz";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-stable,
      utils,
      fh,
    }:
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        packages = {
          inherit (pkgs)
            parallel
            nil
            nixfmt-rfc-style
            nixpkgs-fmt
            ;

          fh = fh.packages.${system}.default;
        };

      in

      {
        packages.default = pkgs.symlinkJoin {
          name = "devenv-nix";
          paths = builtins.attrValues packages;
        };

        devShells.default = pkgs.mkShell {
          packages = builtins.attrValues packages;
        };
      }
    ));
}
