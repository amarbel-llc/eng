{
  pkgs ? import <nixpkgs> { },
  pkgs-master ? import <nixpkgs-master> { },
}:

let
  result = import ./linux { inherit pkgs; };
in
pkgs-master.mkShell {
  packages = builtins.attrValues result.packages;
}
