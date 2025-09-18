{
  description = "A Nix-flake-based Purescript development environment";

  inputs = {
    utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102.tar.gz";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/e9b7f2ff62b35f711568b1f0866243c7c302028d";
    nixpkgs.url = "github:NixOS/nixpkgs/dcfec31546cb7676a5f18e80008e5c56af471925";
    easy-purescript-nix = {
      url = "github:justinwoo/easy-purescript-nix";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, easy-purescript-nix, nixpkgs-stable, utils }:
    let
      supportedSystems = [ "x86_64-linux" "x86_64-darwin" "aarch64-darwin" ]; # "aarch64-linux" not supported
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default =
          let
            easy-ps = import easy-purescript-nix { inherit pkgs; };
          in
          pkgs.mkShell {
            packages = (with pkgs; [ nodejs ]) ++ (with easy-ps; [
              purs
              spago
              purescript-language-server
              purs-tidy
            ]);
          };
      });
    };
}
