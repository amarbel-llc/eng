{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  nonRepoInputs = import ./non-repo-inputs.nix;

  # Inputs whose default package is wrapped in lib.lowPrio so they lose
  # file collisions (e.g. shared man pages) to normal-priority inputs.
  lowPrioInputs = [
    "madder"
  ];

  hasDefaultPackage =
    _: input:
    (input ? packages) && (input.packages ? ${system}) && (input.packages.${system} ? default);

  repoInputs = lib.filterAttrs hasDefaultPackage (builtins.removeAttrs inputs nonRepoInputs);

  repoPackages = builtins.mapAttrs (
    name: input:
    let
      pkg = input.packages.${system}.default;
    in
    if builtins.elem name lowPrioInputs then lib.lowPrio pkg else pkg
  ) repoInputs;
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
