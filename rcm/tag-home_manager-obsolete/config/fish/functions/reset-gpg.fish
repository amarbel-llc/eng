# vim: set syntax=fish:

function reset-gpg --description "Reloads GPG Agent"
  # set -e SSH_AGENT_PID
  set -gx GPG_TTY (tty)

  ln -sf (gpgconf --list-dirs agent-ssh-socket) $HOME/.local/state/ssh/gpg-agent.sock

  just --global-justfile reset-gpg

  return $status
end
