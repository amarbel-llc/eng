{
  pkgs,
  lib,
  config,
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
    guid = "55C3439DDF5E324B1A4DD9F9B75B6106";
    socketPath = "$HOME/.local/state/ssh/pivy-agent.sock";
    askpass = "${pivy}/libexec/pivy/pivy-askpass";
    confirm = "${pivy}/libexec/pivy/pivy-askpass";
    notifySend = "${pivy}/libexec/pivy/pivy-notify";
  };
}
