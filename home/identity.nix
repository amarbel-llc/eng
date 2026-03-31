{ lib, ... }:
let
  envUser = builtins.getEnv "USER";
  envHome = builtins.getEnv "HOME";
in
{
  home.username = lib.mkDefault (if envUser != "" then envUser else "nobody");
  home.homeDirectory = lib.mkDefault (if envHome != "" then envHome else "/homeless-shelter");
}
