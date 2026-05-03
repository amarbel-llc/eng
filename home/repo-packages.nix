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

  # Spinclass with build-time pins for madder (per-worktree blob store
  # init) and direnv (worktree shell resolution). See issue #63 / FDR
  # 0003 (spinclass repo). Without these pins, `sc start` does not
  # initialise .madder/, does not symlink madder into <git-common-dir>/
  # spinclass/bin/, and does not wire Bash(madder:*) into claude-allow.
  spinclassPinned = inputs.spinclass.lib.${system}.mkSpinclass {
    madder = inputs.madder.packages.${system}.default;
    direnv = pkgs.direnv;
  };
in
{
  home.packages =
    builtins.attrValues repoPackages
    ++ [
      spinclassPinned
      inputs.purse-first.packages.${system}.purse-first
      # tap-dancer-bash provides a bash library used by git aliases (cob,
      # cobu, merge-and-cleanup) via home/common.nix's TAP_DANCER_LIB.
      # eng consumes only caldav from bob (via the flake-level symlinkJoin)
      # and tap-dancer-bash from amarbel-llc/tap (split out of bob in
      # bob 2e88c78).
      inputs.tap.packages.${system}.tap-dancer-bash
    ]
    ++ lib.optionals pkgs.stdenv.isDarwin [
      inputs.tacky.packages.${system}.default
    ];
}
