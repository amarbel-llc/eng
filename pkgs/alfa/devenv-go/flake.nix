{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/54b154f971b71d260378b284789df6b272b49634";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/fa83fd837f3098e3e678e6cf017b2b36102c7211";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";

    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      utils,
      gomod2nix,
      nixpkgs-stable,
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

        pkgs-stable = import nixpkgs-stable {
          inherit system;
        };

        packages = {
          inherit (pkgs)
            delve
            gofumpt
            golangci-lint
            golines
            gopls
            gotools
            govulncheck
            parallel
            ;

          inherit (pkgs-stable)
            go
            ;

          # gopls = gopls.packages.${system}.default;
          gomod2nix = gomod2nix.packages.${system}.default;
        };

      in

      {
        inherit packages;

        devShells.default = pkgs.mkShell {
          packages = builtins.attrValues packages;
        };
      }
    ));
}
