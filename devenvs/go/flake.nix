{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      gomod2nix,
      nixpkgs-master,
    }:
    {
      overlays = gomod2nix.overlays;
    }
    // (utils.lib.eachDefaultSystem (
      system:
      let

        pkgs = import nixpkgs {
          inherit system;
        };

        pkgs-master = import nixpkgs-master {
          inherit system;
        };

        packages = {
          inherit (pkgs-master)
            delve
            gofumpt
            golangci-lint
            golines
            gopls
            gotools
            govulncheck
            parallel
            ;

          inherit (pkgs)
            go
            ;

          # gopls = gopls.packages.${system}.default;
          gomod2nix = gomod2nix.packages.${system}.default;
        };

      in

      {
        inherit packages;

        devShells.default = pkgs-master.mkShell {
          packages = builtins.attrValues packages;

          env = {
            GOPATH = "$HOME/.cache/go";
          };
        };
      }
    ));
}
