#!/usr/bin/env bash
set -euo pipefail

dry_run=false
if [[ ${1:-} == "--dry-run" ]]; then
  dry_run=true
fi

if [[ "$(uname)" == "Darwin" ]]; then
  identity_file="/etc/nix-darwin/identity.json"
else
  identity_file="$HOME/.config/identity.nix"
fi

if [[ -f $identity_file ]] && ! $dry_run; then
  if ! gum confirm "Overwrite existing $identity_file?"; then
    gum log --level info "aborted"
    exit 0
  fi
fi

git_name="$(gum input --prompt 'Git user name: ')"
git_email="$(gum input --prompt 'Git email: ')"

# Offer signing keys from pivy-agent
signing_key=""
if keys="$(SSH_AUTH_SOCK="${PIVY_AUTH_SOCK:-}" ssh-add -L 2>/dev/null)"; then
  choice="$(echo "$keys" | gum choose --header 'Select signing key from pivy-agent:')"
  # Strip the comment (third field onward) and add key:: prefix
  signing_key="key::$(echo "$choice" | awk '{print $1, $2}')"
else
  gum log --level warn "no keys found on pivy-agent, skipping signing key"
fi

generate_identity() {
  if [[ "$(uname)" == "Darwin" ]]; then
    hostname="$(scutil --get LocalHostName)"
    printf '{"username":"%s","homeDirectory":"%s","hostname":"%s","gitUserName":"%s","gitUserEmail":"%s","gitSigningKey":"%s"}\n' \
      "$USER" "$HOME" "$hostname" "$git_name" "$git_email" "$signing_key"
  else
    cat <<NIX
{
  gitUserName = "$git_name";
  gitUserEmail = "$git_email";
  gitSigningKey = "$signing_key";
}
NIX
  fi
}

if $dry_run; then
  gum log --level info "dry run — would write $identity_file"
  generate_identity
else
  if [[ "$(uname)" == "Darwin" ]]; then
    sudo mkdir -p "$(dirname "$identity_file")"
    generate_identity | sudo tee "$identity_file" >/dev/null
  else
    mkdir -p "$(dirname "$identity_file")"
    generate_identity >"$identity_file"
  fi
  gum log --level info "wrote $identity_file"
fi
