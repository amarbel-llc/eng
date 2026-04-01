{
  pkgs,
  lib,
  config,
  inputs,
  ...
}:
let
  system = pkgs.stdenv.hostPlatform.system;
  ssh-agent-mux = inputs.ssh-agent-mux.packages.${system}.default;
  configPath = "${config.home.homeDirectory}/.config/ssh-agent-mux/ssh-agent-mux.toml";
in
{
  launchd.agents.ssh-agent-mux = lib.mkIf pkgs.stdenv.isDarwin {
    enable = true;
    config = {
      Label = "net.ross-williams.ssh-agent-mux";
      ProgramArguments = [
        "${ssh-agent-mux}/bin/ssh-agent-mux"
        "--config"
        configPath
      ];
      RunAtLoad = true;
      KeepAlive = true;
    };
  };

  systemd.user.services.ssh-agent-mux = lib.mkIf pkgs.stdenv.isLinux {
    Unit.Description = "SSH agent multiplexer";
    Service = {
      ExecStartPre = "/bin/rm -f %h/.local/state/ssh/mux-agent.sock";
      ExecStart = "${ssh-agent-mux}/bin/ssh-agent-mux --config %h/.config/ssh-agent-mux/ssh-agent-mux.toml";
      Restart = "on-failure";
    };
    Install.WantedBy = [ "default.target" ];
  };
}
