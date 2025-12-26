
mkdir -p $HOME/.local/state/ssh

set -l SSH_OLD_AUTH_SOCK $SSH_AUTH_SOCK
echo "saving old socket: SSH_OLD_AUTH_SOCK:$SSH_OLD_AUTH_SOCK" >&2

if not test -L $HOME/.local/state/ssh/ssh-agent.sock
  echo "boostrapping new ssh-agent" >&2
  eval (ssh-agent -c) >/dev/null
  echo "new socket: SSH_AUTH_SOCK:$SSH_AUTH_SOCK" >&2
  ln -s $SSH_AUTH_SOCK $HOME/.local/state/ssh/ssh-agent.sock
  set -e SSH_AUTH_SOCK
end

set -gx SSH_AUTH_SOCK $SSH_OLD_AUTH_SOCK
