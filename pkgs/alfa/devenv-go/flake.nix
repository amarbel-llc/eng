{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/f4ee7c92235a73f6af52d4ac2ba25b784214aa75";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/8cd5ce828d5d1d16feff37340171a98fc3bf6526";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";

    gomod2nix = {
      url = "github:nix-community/gomod2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, utils, gomod2nix, nixpkgs-stable }:
    {
      overlays = gomod2nix.overlays;
    } //
    (utils.lib.eachDefaultSystem
      (system:
        let

          pkgs = import nixpkgs {
            inherit system;
          };

          packages = {
            inherit (pkgs)
              delve
              go
              gofumpt
              golangci-lint
              golines
              gopls
              gotools
              govulncheck
              parallel
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
      )
    );
}
