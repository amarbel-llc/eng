# Per-host eng circus, gated on identity.enableCaldav.
#
# Re-imports lib/circus.nix with the per-host flag and exposes the
# resulting clown wrapper as the module arg `engCircus`, consumed by
# home/repo-packages.nix.
#
# The flake-output-level circus (self.packages.${system}.circus,
# defined in flake.nix via lib/circus.nix) stays caldav-on so
# `nix run`, CI, and eng-* overlays are unaffected.
{
  identity,
  inputs,
  pkgs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  engCircusBundle = import ../lib/circus.nix {
    inherit pkgs inputs system;
    engSelf = inputs.self;
    enableCaldav = identity.enableCaldav or true;
  };
in
{
  _module.args.engCircus = engCircusBundle.circus.packages.default;
}
