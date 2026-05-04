# Shared builder for home-manager (extra)specialArgs.
#
# Consumed by BOTH home-manager call sites in the top-level flake.nix:
#   1. homeConfigurations.linux          — standalone home-manager on Linux
#   2. darwinConfigurations.${hostname}  — nix-darwin's nested home-manager
#      module (also reused as the outer darwin specialArgs, since the two
#      sets are identical in practice)
#
# This file exists specifically so that adding a new pinned-tree input
# (see AGENTS.md → "Wrapper-Pinned Packages") is a SINGLE-LINE change here,
# not a three-site edit across flake.nix. If you are about to wire a new
# `nixpkgs-*-pinned` input into home-manager, this is the only file you
# need to touch in the flake plumbing layer — after adding the flake input
# itself in flake.nix.
#
# Callers pass `system` and merge in `identity` themselves, since identity
# differs per platform (linuxIdentity from ~/.config/identity.nix vs
# darwinIdentity from /etc/nix-darwin/identity.json).
#
# Usage from flake.nix:
#
#   mkHomeSpecialArgs = import ./home/special-args.nix { inherit inputs; };
#   ...
#   extraSpecialArgs = (mkHomeSpecialArgs system) // { identity = ...; };
{ inputs }:
system: {
  inherit inputs;
  pkgs-master = import inputs.nixpkgs-master {
    inherit system;
    config.allowUnfree = true;
    # See ../lib/fish-codesign-overlay.nix for context.
    overlays = [ (import ../lib/fish-codesign-overlay.nix) ];
  };
}
