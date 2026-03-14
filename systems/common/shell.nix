{
  pkgs ? import <nixpkgs> { config.allowUnfree = true; },
  pkgs-master ? import <nixpkgs-master> { config.allowUnfree = true; },
}:

let
  result = import ./default.nix { inherit pkgs pkgs-master; };
in
pkgs-master.mkShell {
  packages = builtins.attrValues result.packages;
}
