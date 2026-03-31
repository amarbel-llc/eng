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
in
{
  launchd.agents.pivy-agent = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      Label = "net.cooperi.pivy-agent";
      ProgramArguments = [
        "${pivy}/bin/pivy-agent"
        "-A"
        "-i"
        "-a"
        "${config.home.homeDirectory}/.ssh/pivy-agent.sock"
      ];
      EnvironmentVariables = {
        SSH_ASKPASS = "${pivy}/libexec/pivy/pivy-askpass";
        SSH_ASKPASS_REQUIRE = "force";
        SSH_CONFIRM = "${pivy}/libexec/pivy/pivy-askpass";
        SSH_NOTIFY_SEND = "${pivy}/libexec/pivy/pivy-notify";
      };
      RunAtLoad = true;
      KeepAlive = true;
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/pivy-agent.log";
    };
  };

  systemd.user.services.pivy-agent = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "PIV SSH Agent";
    Service = {
      ExecStartPre = "/bin/rm -f %h/.local/state/ssh/pivy-agent.sock";
      ExecStart = "${pivy}/bin/pivy-agent -i -A -a %h/.local/state/ssh/pivy-agent.sock";
      Environment = [
        "SSH_AUTH_SOCK=%h/.local/state/ssh/pivy-agent.sock"
        "PIV_SLOTS=all"
        "SSH_ASKPASS=${pivy}/libexec/pivy/pivy-askpass"
        "SSH_ASKPASS_REQUIRE=force"
        "SSH_CONFIRM=${pivy}/libexec/pivy/pivy-askpass"
        "SSH_NOTIFY_SEND=${pivy}/libexec/pivy/pivy-notify"
      ];
      Restart = "always";
      RestartSec = 3;
    };
    Install.WantedBy = [ "default.target" ];
  };
}
