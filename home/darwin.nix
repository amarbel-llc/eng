{
  pkgs,
  lib,
  pkgs-master,
  inputs,
  ...
}:
{
  imports = [
    ./common.nix
    ./pivy-agent.nix
    ./repo-packages.nix
    ./ssh-agent-mux.nix
  ];

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    pinentry_mac
    reattach-to-user-namespace
  ];
}
