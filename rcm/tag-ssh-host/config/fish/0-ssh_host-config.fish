
if test $SHLVL -gt 1
  return
end

if test -z $SSH_CLIENT
  return
end

mkdir -p $HOME/.local/state/ssh
set -l file_ssh_client_agent $HOME/.local/state/ssh/ssh_client-agent.sock

if test -S $file_ssh_client_agent
  gum log -t info "ssh-agent reused from: "(prompt_pwd $file_ssh_client_agent)
  set -x SSH_AUTH_SOCK $file_ssh_client_agent

else if test -S $SSH_AUTH_SOCK
  gum log -t info "ssh-agent newly set: $SSH_AUTH_SOCK"
  ln -sf $SSH_AUTH_SOCK $file_ssh_client_agent
  set -x SSH_AUTH_SOCK $file_ssh_client_agent

else if -n $SSH_AUTH_SOCK
  gum log -t warn "ssh-agent set to non-sock file: $SSH_AUTH_SOCK!"

else
  gum log -t warn "No ssh-agent forwarded set!"
end
