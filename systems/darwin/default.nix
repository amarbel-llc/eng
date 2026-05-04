# systems/darwin/default.nix
#
# Thin wrapper around home/packages/darwin.nix so the eng symlinkJoin
# (via flake.nix:platformPackages) and home-manager (via home/darwin.nix)
# share one darwin-only package list.
{ pkgs, pkgs-master }:
{
  packages = import ../../home/packages/darwin.nix { inherit pkgs pkgs-master; };
}
