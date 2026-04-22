{ config, ... }:
{
  home.sessionVariables = {
    CARGO_HOME = "${config.xdg.dataHome}/cargo";
    DOCKER_CONFIG = "${config.xdg.configHome}/docker";
    HTTPIE_CONFIG_DIR = "${config.xdg.configHome}/httpie";
    LESSHISTFILE = "${config.xdg.stateHome}/less/history";
    NODE_REPL_HISTORY = "${config.xdg.stateHome}/node/repl_history";
    PARALLEL_HOME = "${config.xdg.configHome}/parallel";
    PYTHON_HISTORY = "${config.xdg.stateHome}/python/history";
    XDG_LOG_HOME = "$HOME/.local/log";
  };
}
