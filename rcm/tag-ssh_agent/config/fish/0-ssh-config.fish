
mkdir -p $HOME/.local/state/ssh
set -l SSH_OLD_AUTH_SOCK $SSH_AUTH_SOCK

if not test -L $HOME/.local/state/ssh/ssh-agent.sock
  eval (ssh-agent -c) >/dev/null
  ln -s $SSH_AUTH_SOCK $HOME/.local/state/ssh/ssh-agent.sock
  set -e SSH_AUTH_SOCK
end

set -gx SSH_AUTH_SOCK $SSH_OLD_AUTH_SOCK
