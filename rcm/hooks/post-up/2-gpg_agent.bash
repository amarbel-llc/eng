#! /usr/bin/env -S bash -e

export PATH="$HOME/eng/result/bin:$PATH"
eval "$(direnv hook bash)"

if ! fish -c reset-gpg >/dev/null; then
  gum log -l error "failed to start gpg agent"
fi

if ! ssh-agent-mux --restart-service; then
  gum log -l error "failed to start ssh-agent-mux"
fi
