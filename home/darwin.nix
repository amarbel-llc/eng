{
  pkgs,
  lib,
  pkgs-master,
  identity,
  inputs,
  ...
}:
{
  imports = [
    ./common.nix
    ./repo-packages.nix
    ./circus.nix
    ./ssh-agent-mux.nix
  ]
  ++ lib.optionals (identity.piggyGuid or null != null) [
    ./piggy-agent.nix
  ];

  home.stateVersion = "24.11";

  home.packages = builtins.attrValues (
    import ./packages/darwin.nix { inherit pkgs pkgs-master; }
  );
}
