#!/usr/bin/env bash
set -euo pipefail

eng_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$eng_dir"

# Step 1: nix build (get tools like gum, rcm, etc. into result/bin)
echo "Building nix packages..."
nix build --show-trace
export PATH="$eng_dir/result/bin:$PATH"

# Step 2: identity bootstrap
if [[ "$(uname)" == "Darwin" ]]; then
  identity_file="/etc/nix-darwin/identity.json"
else
  identity_file="$HOME/.config/identity.nix"
fi
if [[ ! -f $identity_file ]]; then
  gum log --level info "identity file not found, running bootstrap..."
  "$eng_dir/bin/bootstrap-identity.bash"
fi

# Step 3: rcm setup
"$eng_dir/bin/bootstrap-rcrc.bash"
rcup -f

# Step 4: home-manager
if [[ "$(uname)" == "Darwin" ]]; then
  sudo darwin-rebuild switch --impure --flake .
else
  nix run home-manager -- switch -b backup --impure --flake .#linux
fi

gum log --level info "bootstrap complete"
echo ""
echo "Next steps:"
echo "  exec fish                                    # switch to fish shell"
echo "  just install-purse-first && just install-bob # Claude marketplaces"
