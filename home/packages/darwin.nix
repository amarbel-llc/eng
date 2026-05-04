# Single source of truth for darwin-only package set.
#
# Imported by both:
#   - home/darwin.nix             (home-manager home.packages on darwin)
#   - systems/darwin/default.nix  (eng/result symlinkJoin via flake.nix)
#
# pkgs-master is accepted for signature parity with common.nix / linux.nix
# even though no current entry needs it.
{ pkgs, pkgs-master }:
{
  inherit (pkgs)
    pinentry_mac
    reattach-to-user-namespace
    ;
}
