#! /usr/bin/env -S bash -e
# @brief starts ssh-agent-mux and gpg-agent

export PATH="$HOME/eng/result/bin:$PATH"
eval "$(direnv hook bash)"

{
  output="$(mktemp)"

  if ! fish -c reset-gpg >"$output" 2>&1; then
    gum log -l error "failed to start gpg agent:"
    xargs -L1 gum log -l error -- <"$output"
    rm "$output"
    exit 1
  fi

  gum log -l info "started gpg agent"

  rm "$output"
}

{
  output="$(mktemp)"

  if ! ssh-agent-mux --restart-service >"$output" 2>&1; then
    gum log -l error "failed to start ssh-agent-mux:"
    xargs -L1 gum log -l error -- <"$output"
    rm "$output"
    exit 1
  fi

  gum log -l info "started ssh-agent-mux"

  rm "$output"
}
