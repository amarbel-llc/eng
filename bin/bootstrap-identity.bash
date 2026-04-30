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

# SSH hosts use agent forwarding instead of pivy-agent/ssh-agent-mux
is_ssh_host=false
ssh_confirm_flag=""
[[ -n ${SSH_CLIENT:-} ]] && ssh_confirm_flag="--default"
if gum confirm $ssh_confirm_flag "Configure as SSH host? (skips pivy-agent and ssh-agent-mux)"; then
  is_ssh_host=true
fi

# Capture the inserted PIV card's GUID for services.piggy-agent.guid.
# Skipped on SSH hosts (no local card).
piggy_guid=""
if ! $is_ssh_host; then
  guids="$(piggy tool list 2>/dev/null | awk '/^[[:space:]]*guid:/ {print $2}')"
  guid_count="$(printf '%s\n' "$guids" | grep -c . || true)"
  if [[ $guid_count -eq 0 ]]; then
    gum log --level warn "no PIV card detected via 'piggy tool list', leaving piggyGuid empty"
  elif [[ $guid_count -eq 1 ]]; then
    piggy_guid="$guids"
    gum log --level info "captured PIV GUID: $piggy_guid"
  else
    piggy_guid="$(printf '%s\n' "$guids" | gum choose --header 'Select PIV card GUID:')"
  fi
fi

generate_identity() {
  if [[ "$(uname)" == "Darwin" ]]; then
    hostname="$(scutil --get LocalHostName)"
    printf '{"username":"%s","homeDirectory":"%s","hostname":"%s","gitUserName":"%s","gitUserEmail":"%s","gitSigningKey":"%s","piggyGuid":"%s"}\n' \
      "$USER" "$HOME" "$hostname" "$git_name" "$git_email" "$signing_key" "$piggy_guid"
  else
    # piggyGuid: emit a Nix string when set, null when unset (SSH host or no card).
    if [[ -n $piggy_guid ]]; then
      piggy_guid_nix="\"$piggy_guid\""
    else
      piggy_guid_nix="null"
    fi
    cat <<NIX
{
  gitUserName = "$git_name";
  gitUserEmail = "$git_email";
  gitSigningKey = "$signing_key";
  isSshHost = $is_ssh_host;
  piggyGuid = $piggy_guid_nix;
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
