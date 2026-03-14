{
  pkgs ? import <nixpkgs> { },
}:

let
  result = import ./default.nix { inherit pkgs; };
in
pkgs.mkShell {
  packages = builtins.attrValues result.packages;
}
