{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
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
