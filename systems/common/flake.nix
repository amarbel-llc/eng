{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/3e20095fe3c6cbb1ddcef89b26969a69a1570776";
    nixpkgs-master.url = "github:NixOS/nixpkgs/e034e386767a6d00b65ac951821835bd977a08f7";
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  };

  outputs =
    {
      self,
      nixpkgs,
      nixpkgs-master,
      utils,
    }:
    (utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          config.allowUnfree = true;
          inherit system;
        };
        pkgs-master = import nixpkgs-master {
          config.allowUnfree = true;
          inherit system;
        };
        result = import ./default.nix { inherit pkgs pkgs-master; };
      in
      {
        packages = result.packages // {
          default = pkgs-master.symlinkJoin {
            failOnMissing = true;
            name = "system-packages";
            paths = builtins.attrValues result.packages;
          };
        };

        devShells.default = pkgs-master.mkShell {
          packages = builtins.attrValues result.packages;
        };
      }
    ));
}
