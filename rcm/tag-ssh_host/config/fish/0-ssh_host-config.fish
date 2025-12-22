
if test -z $SSH_CLIENT
  return
end

mkdir -p $HOME/.local/state/ssh
set -l file_ssh_client_agent $HOME/.local/state/ssh/ssh_client-agent.sock

if test -S $file_ssh_client_agent
  echo "ssh-agent reused from: $file_ssh_client_agent" >&2
  set -x SSH_AUTH_SOCK $file_ssh_client_agent

else if test -S $SSH_AUTH_SOCK
  echo "ssh-agent newly set: $SSH_AUTH_SOCK" >&2
  ln -sf $SSH_AUTH_SOCK $file_ssh_client_agent

else if -n $SSH_AUTH_SOCK
  echo "ssh-agent set to non-sock file: $SSH_AUTH_SOCK!" >&2

else
  echo "No ssh-agent forwarded set!" >&2
end
