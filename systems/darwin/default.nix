# systems/darwin/default.nix
{ pkgs }:
{
  packages = {
    inherit (pkgs)
      pinentry_mac
      reattach-to-user-namespace
      ;
  };
}
