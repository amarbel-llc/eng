{
  pkgs ? import <nixpkgs> { },
}:

let
  result = import ./darwin { inherit pkgs; };
in
pkgs.mkShell {
  packages = builtins.attrValues result.packages;
}
