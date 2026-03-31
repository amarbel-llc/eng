{
  pkgs,
  lib,
  pkgs-master,
  inputs,
  ...
}:
{
  imports = [ ../../../../../home/common.nix ];

  home.stateVersion = "24.11";
}
