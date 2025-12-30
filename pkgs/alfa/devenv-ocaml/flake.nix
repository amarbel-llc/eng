{
  description = "A Nix-flake-based OCaml development environment";

  inputs.utils.url = "https://flakehub.com/f/numtide/flake-utils/0.1.102";
  inputs.nixpkgs-stable.url = "github:NixOS/nixpkgs/9ef261221d1e72399f2036786498d78c38185c46";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/c4cfc9ced33f81099f419fa59893df11dc3f9de9";

  outputs = { self, nixpkgs, nixpkgs-stable, utils }:
    let
      supportedSystems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forEachSupportedSystem = f: nixpkgs.lib.genAttrs supportedSystems (system: f {
        pkgs = import nixpkgs { inherit system; };
      });
    in
    {
      devShells = forEachSupportedSystem ({ pkgs }: {
        default = pkgs.mkShell {
          packages = with pkgs; [ ocaml ocamlformat ] ++
            (with pkgs.ocamlPackages; [ dune_3 odoc ]);
        };
      });
    };
}
