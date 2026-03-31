{
  pkgs,
  lib,
  pkgs-master,
  inputs,
  ...
}:
{
  imports = [ ./common.nix ];

  home.stateVersion = "24.11";
  home.username = "sfriedenberg";
  home.homeDirectory = "/Users/sfriedenberg";
}
