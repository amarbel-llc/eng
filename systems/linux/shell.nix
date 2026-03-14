{
  pkgs ? import <nixpkgs> { },
  pkgs-master ? import <nixpkgs-master> { },
}:

let
  result = import ./default.nix { inherit pkgs; };
in
pkgs-master.mkShell {
  packages = builtins.attrValues result.packages;
}
