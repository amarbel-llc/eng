#!/usr/bin/env bash
set -euo pipefail

eng_dir="$(cd "$(dirname "$0")/.." && pwd)"
cd "$eng_dir"

nix_installer="${1:-}"
nix_profile_script="/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh"

# Step 0: install nix if missing, or just source its profile if it's
# installed but not yet on PATH (e.g. fresh login after first install).
if ! command -v nix >/dev/null 2>&1; then
  if [[ ! -e $nix_profile_script ]]; then
    if [[ -n $nix_installer ]]; then
      "$nix_installer" install --no-confirm
    else
      echo "nix not found, installing via Determinate Systems installer..."
      # /tmp is often mounted noexec on hardened hosts; the installer
      # extracts and execs nix-installer from $TMPDIR, so point it at a
      # $HOME-anchored dir for the install subprocess only.
      cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}"
      mkdir -p "$cache_dir"
      installer_tmpdir="$(mktemp -d "$cache_dir/nix-installer.XXXXXX")"
      trap 'rm -rf "$installer_tmpdir"' EXIT
      if ! (
        export TMPDIR="$installer_tmpdir"
        curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install --no-confirm
      ); then
        echo "If nix failed to install, re-run this script with an installer path as the first arg" >&2
        exit 1
      fi
      rm -rf "$installer_tmpdir"
      trap - EXIT
    fi
  fi
  # shellcheck disable=SC1090
  . "$nix_profile_script"
fi

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
  "$eng_dir/bin/bootstrap-identity.mjs"
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
