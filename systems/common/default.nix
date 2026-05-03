# systems/common/default.nix
#
# Thin wrapper around home/packages/common.nix so the eng symlinkJoin
# (via flake.nix:platformPackages) and home-manager (via home/common.nix)
# share one platform-neutral package list.
{ pkgs, pkgs-master }:
{
  packages = import ../../home/packages/common.nix { inherit pkgs pkgs-master; };
}
