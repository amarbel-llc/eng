{
  pkgs,
  lib,
  pkgs-master,
  inputs,
  ...
}:
{
  imports = [ ../../../../../home/darwin.nix ];

  home.stateVersion = "24.11";
}
