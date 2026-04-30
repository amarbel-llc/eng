{
  pkgs,
  lib,
  config,
  identity,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  pivy = inputs.pivy.packages.${system}.default;
  piggy = inputs.piggy.packages.${system}.piggy;
in
{
  imports = [ inputs.piggy.homeManagerModules.piggy-agent ];

  services.piggy-agent = {
    enable = true;
    package = piggy;
    guid = identity.piggyGuid;
    socketPath = "$HOME/.local/state/ssh/pivy-agent.sock";
    askpass = "${pivy}/libexec/pivy/pivy-askpass";
    confirm = "${pivy}/libexec/pivy/pivy-askpass";
    notifySend = "${pivy}/libexec/pivy/pivy-notify";
    logFile = lib.mkIf pkgs.stdenv.isDarwin "${config.home.homeDirectory}/Library/Logs/piggy-agent.log";
  };
}
