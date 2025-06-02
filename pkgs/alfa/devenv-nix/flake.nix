{
  description = "A Nix-flake-based Nix development environment";

  inputs = {
    nixpkgs-stable.url = "nixpkgs/release-24.11";
    utils.url = "github:numtide/flake-utils";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.21.tar.gz";
  };

  outputs =
    { self
    , nixpkgs
    , nixpkgs-stable
    , utils
    , fh
    }:
    (utils.lib.eachDefaultSystem
      (system:
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
        inherit packages;

        devShells.default = pkgs.mkShell {
          packages = builtins.attrValues packages;
        };
      }
      )
    );
}
