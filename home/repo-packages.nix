{
  inputs,
  pkgs,
  lib,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;

  # Infrastructure inputs excluded from auto-import.
  # bob and purse-first produce marketplace outputs whose
  # .claude-plugin/marketplace.json would collide in symlinkJoin.
  infraInputs = [
    "self"
    "nixpkgs"
    "nixpkgs-master"
    "utils"
    "home-manager"
    "nix-darwin"
    "nix-plist-manager"
    "bob"
    "purse-first"
    "tacky"
  ];

  repoInputs = builtins.removeAttrs inputs infraInputs;

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
