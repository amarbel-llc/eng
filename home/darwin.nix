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
    ./repo-packages.nix
  ];

  home.stateVersion = "24.11";

  home.packages = with pkgs; [
    pinentry_mac
    reattach-to-user-namespace
  ];
}
