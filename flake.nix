{
  description = "Monorepo containing devenv templates and system packages";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/23d72dabcb3b12469f57b37170fcbc1789bd7457";
    nixpkgs-master.url = "github:NixOS/nixpkgs/b28c4999ed71543e71552ccfd0d7e68c581ba7e9";
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
        pkgs = import nixpkgs { inherit system; };
      in
      {
        # No aggregated packages - each devenv and system flake should be built independently
        # Examples:
        #   nix build ./devenvs/devenv-go
        #   nix build ./systems/system-common

        # Provide a simple devShell for working in this repo
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            nix
            git
            just
            gum
          ];
        };
      }
    ));
}
