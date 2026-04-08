{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # Inputs intentionally excluded from the auto-imported repo set,
  # even though they MAY expose a `packages.<system>.default`.
  # Mirrors `nonRepoInputs` in ../flake.nix — keep in sync.
  # Inputs without a default package at all (nixpkgs forks, flake-utils,
  # nixpkgs-claude-code-pinned wrapper-pin trees) are filtered by shape
  # below and do NOT need to be listed here. See CLAUDE.md →
  # "Wrapper-Pinned Packages".
  nonRepoInputs = [
    "self"
    "home-manager"
    "nix-darwin"
    "nix-plist-manager"
    "bob"
    "purse-first"
    "tacky"
  ];

  hasDefaultPackage =
    _: input:
    (input ? packages) && (input.packages ? ${system}) && (input.packages.${system} ? default);

  repoInputs = lib.filterAttrs hasDefaultPackage (builtins.removeAttrs inputs nonRepoInputs);

  repoPackages = builtins.mapAttrs (_: input: input.packages.${system}.default) repoInputs;
in
{
  home.packages =
    builtins.attrValues repoPackages
    ++ [
      inputs.purse-first.packages.${system}.purse-first
      # bob-all bundles gh man pages that collide with the standalone gh package,
      # so give it lower priority.
      (lib.lowPrio inputs.bob.packages.${system}.default)
      inputs.bob.packages.${system}.tap-dancer-bash
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      inputs.tacky.packages.${system}.default
    ];
}
