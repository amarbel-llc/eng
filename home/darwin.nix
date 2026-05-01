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
    ./ssh-agent-mux.nix
  ]
  ++ lib.optionals (identity.piggyGuid or null != null) [
    ./piggy-agent.nix
  ];

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    pinentry_mac
    reattach-to-user-namespace
  ];
}
