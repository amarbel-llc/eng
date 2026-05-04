# systems/linux/default.nix
#
# Thin wrapper around home/packages/linux.nix so the eng symlinkJoin
# (via flake.nix:platformPackages) and home-manager (via home/linux.nix)
# share one linux-only package list.
{ pkgs, pkgs-master }:
{
  packages = import ../../home/packages/linux.nix { inherit pkgs pkgs-master; };
}
