{
  description = "A Nix-flake-based Nix development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    nixpkgs-master.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
    fh.url = "https://flakehub.com/f/DeterminateSystems/fh/0.1.21.tar.gz";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
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
            nixfmt
            ;

          fh = fh.packages.${system}.default;
        };

      in

      {
        formatter = pkgs.nixfmt;

        apps.fmt = {
          type = "app";
          program = "${pkgs.nixfmt}/bin/nixfmt";
        };

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
