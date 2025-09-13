{
  description = "A Nix-flake-based Nix development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";
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
