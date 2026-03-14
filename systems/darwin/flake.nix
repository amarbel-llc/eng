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
    utils.lib.eachSystem
      [
        "x86_64-darwin"
        "aarch64-darwin"
      ]
      (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
          };
          result = import ./default.nix { inherit pkgs; };
        in
        {
          packages = result.packages // {
            default = pkgs.symlinkJoin {
              failOnMissing = true;
              name = "system-packages";
              paths = builtins.attrValues result.packages;
            };
          };

          devShells.default = pkgs.mkShell {
            packages = builtins.attrValues result.packages;
          };
        }
      );
}
