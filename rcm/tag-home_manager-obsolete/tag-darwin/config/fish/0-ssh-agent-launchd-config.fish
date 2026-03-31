
set -l launchd_ssh_auth_sock (launchctl getenv SSH_AUTH_SOCK)

if ! test -S $launchd_ssh_auth_sock
  return
end

mkdir -p $HOME/.local/state/ssh

ln -sf $launchd_ssh_auth_sock $HOME/.local/state/ssh/launchd-agent.sock
