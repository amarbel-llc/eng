export PATH := join(env_var('HOME'), "eng", "result", "bin") + ":" + env_var('PATH')

default: \
    update-git \
    update-nix-flake \
    build-nix \
    deploy-flake-lock \
    build-rcm \
    install-purse-first \
    install-bob \
    install-dodder \
    install-moxy \
    install-pivy-agent-service \
    install-ssh-agent-mux \
    install-gcloud-auth-proxy \
    install-lux-service \

# TODO implement a check that enforces no active claude sessions, worktrees, or
# sweatshops open. This is because upgrading the entire environment can break
# existing sessions
check-active_sessions:

update: update-git update-nixpkgs update-nix-flake update-repos

update-git:
  git sync

# git syncs all repos in ~/eng/repos
update-repos:
  tap-dancer exec-parallel "cd {} && git pull" ::: "$HOME/eng/repos/"*

update-nix-flake:
  nix flake update

# push flake.lock to origin
deploy-flake-lock:
  #!/usr/bin/env bash
  set -euo pipefail
  if git diff --quiet flake.lock; then
    echo "flake.lock unchanged, skipping deploy"
    exit 0
  fi
  git add flake.lock
  git commit -m "update flake.lock"
  git push

# build, validate, and install purse-first marketplace (framework skills)
install-purse-first:
  #!/usr/bin/env bash
  set -euo pipefail
  store_path="$(nix build .#purse-first-marketplace --no-link --print-out-paths)"
  purse-first validate "$store_path/.claude-plugin/marketplace.json"
  purse-first install "$store_path"

# build, validate, and install bob marketplace (MCP servers + workflow skills)
install-bob:
  #!/usr/bin/env bash
  set -euo pipefail
  store_path="$(nix build .#bob-marketplace --no-link --print-out-paths)"
  purse-first validate "$store_path/.claude-plugin/marketplace.json"
  purse-first install "$store_path"

# build and validate purse-first marketplace without installing
validate-purse-first:
  #!/usr/bin/env bash
  set -euo pipefail
  store_path="$(nix build .#purse-first-marketplace --no-link --print-out-paths)"
  purse-first validate "$store_path/.claude-plugin/marketplace.json"

# build and validate bob marketplace without installing
validate-bob:
  #!/usr/bin/env bash
  set -euo pipefail
  store_path="$(nix build .#bob-marketplace --no-link --print-out-paths)"
  purse-first validate "$store_path/.claude-plugin/marketplace.json"

install-dodder:
  dodder install-mcp

install-moxy:
  moxy install-mcp

install-pivy-agent-service:
  #!/usr/bin/env bash
  set -euo pipefail
  if [[ -n "${SSH_HOST:-}" ]]; then
    gum log --level info "SSH_HOST set, skipping pivy-agent service install"
    exit 0
  fi
  pivy-agent install-service -A

install-ssh-agent-mux:
  #!/usr/bin/env bash

  set -euo pipefail

  if [[ -n "${SSH_HOST:-}" ]]; then
    gum log --level info "SSH_HOST set, skipping ssh-agent-mux install"
    exit 0
  fi

  ssh-agent-mux service install

install-gcloud-auth-proxy:
  #!/usr/bin/env -S bash

  set -euo pipefail

  if ! command -v gcloud; then
    gum log --level info "gcloud not present, skipping gcloud-auth-proxy install"
    exit 0
  fi

  if [[ -n "${SSH_HOST:-}" ]]; then
    gcloud-auth-proxy setup-remote
  else
    gcloud-auth-proxy service-install
  fi

install-lux-service:
  lux service-install

install-niri-session:
  #!/usr/bin/env bash
  set -euo pipefail
  if [[ "$(uname)" != "Linux" ]]; then
    gum log --level info "not Linux, skipping niri session install"
    exit 0
  fi
  src="$HOME/.local/share/wayland-sessions/niri.desktop"
  if [[ ! -f "$src" ]]; then
    gum log --level error "niri.desktop not found — run 'just build-rcm' first"
    exit 1
  fi
  pkexec install -m 644 "$src" /usr/share/wayland-sessions/niri.desktop

test-integration:
  nix develop ./devenvs/integration-test --command just -f devenvs/integration-test/justfile test

clean-nix:
  nix-store --gc

clean: clean-nix

update-kitty:
  curl -L https://sw.kovidgoyal.net/kitty/installer.sh | sh /dev/stdin
  pkexec ln -s "$(which kitty)" /usr/bin/kitty
  pkexec ln -s "$(which kitten)" /usr/bin/kitten

nix_nixpkgs_stable_git_branch := "nixos-25.11"
nix_nixpkgs_stable_darwin_git_branch := nix_nixpkgs_stable_git_branch + "-darwin"

export file_nixpkgs_git_master_sha := "nixpkgs-git-master.git-sha"
export file_nixpkgs_stable_git_sha := "nixpkgs-stable-git.git-sha"
export file_nixpkgs_stable_darwin_git_sha := "nixpkgs-stable-darwin-git.git-sha"

# TODO add flake-utils
update-nixpkgs:
  #!/usr/bin/env bash

  set -euo pipefail

  # Track visited flakes to avoid cycles
  declare -A visited

  echo "Fetching nixpkgs unstable git master digest..." >&2
  nix_nixpkgs_git_master_digest="$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/master | awk '{print $1}')"
  echo "Fetched nixpkgs unstable git master digest: ${nix_nixpkgs_git_master_digest}" >&2
  echo ${nix_nixpkgs_git_master_digest} > {{file_nixpkgs_git_master_sha}}

  echo "Fetching nixpkgs stable git {{nix_nixpkgs_stable_git_branch}} digest..." >&2
  nix_nixpkgs_stable_git_digest="$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/{{nix_nixpkgs_stable_git_branch}} | awk '{print $1}')"
  echo "Fetched nixpkgs stable git {{nix_nixpkgs_stable_git_branch}} digest: ${nix_nixpkgs_stable_git_digest}" >&2
  echo ${nix_nixpkgs_stable_git_digest} > {{file_nixpkgs_stable_git_sha}}

  echo "Fetching nixpkgs stable_darwin git {{nix_nixpkgs_stable_darwin_git_branch}} digest..." >&2
  nix_nixpkgs_stable_darwin_git_digest="$(git ls-remote https://github.com/NixOS/nixpkgs refs/heads/{{nix_nixpkgs_stable_darwin_git_branch}} | awk '{print $1}')"
  if [[ -z "$nix_nixpkgs_stable_darwin_git_digest" ]]; then
    echo "Warning: {{nix_nixpkgs_stable_darwin_git_branch}} branch not found, skipping" >&2
  else
    echo "Fetched nixpkgs stable_darwin git {{nix_nixpkgs_stable_darwin_git_branch}} digest: ${nix_nixpkgs_stable_darwin_git_digest}" >&2
    echo ${nix_nixpkgs_stable_darwin_git_digest} > {{file_nixpkgs_stable_darwin_git_sha}}
  fi


# Update flakes in main eng repo (excludes repos/ and worktrees/)
update-nix:
  UPDATE_FLAKES_EXCLUDE="./repos/* ./worktrees/*" ./bin/update_flakes.bash

# Full lifecycle update for a single repo (pull, update inputs, build, commit, push)
[no-exit-message]
_update-repo-full dir:
  #!/usr/bin/env bash
  set -euo pipefail

  dir="$(realpath "{{dir}}")"
  eng_dir="{{justfile_directory()}}"

  if [[ ! -f "$dir/flake.nix" ]]; then
    exit 0
  fi

  cd "$dir"

  if ! git remote -v | grep -qE 'friedenberg|amarbel-llc'; then
    exit 0
  fi

  stable_sha="$(cat "$eng_dir/{{file_nixpkgs_stable_git_sha}}")"
  master_sha="$(cat "$eng_dir/{{file_nixpkgs_git_master_sha}}")"

  git pull --rebase

  if ! grep -q 'nixpkgs\.follows' flake.nix; then
    fh add "github:NixOS/nixpkgs/${stable_sha}"
  fi

  if grep -q 'nixpkgs-master' flake.nix && ! grep -q 'nixpkgs-master\.follows' flake.nix; then
    fh add --input-name nixpkgs-master "github:NixOS/nixpkgs/${master_sha}"
  fi

  if ! grep -q 'utils\.follows' flake.nix; then
    fh add --input-name utils numtide/flake-utils
  fi

  nix flake update

  if [[ -f justfile ]]; then
    just
  fi

  if ! git diff --quiet flake.nix flake.lock; then
    git add flake.nix flake.lock
    git commit -m "update flake.lock"
    git push
  fi

# Update flakes in repos/ in parallel (separate git repositories)
update-nix-repos:
  tap-dancer exec-parallel -j 1 "just _update-repo-full {}" ::: repos/*/

build-nix:
  nix build --show-trace

build-nix-darwin:
  sudo darwin-rebuild switch --flake ./rcm/tag-darwin/config/nix-darwin
  # sudo nix run nix-darwin/master -- switch --flake "$(readlink "$HOME/.config/nix-darwin")"

[working-directory: "rcm"]
build-rcm: build-rcm-hooks-pre-up build-rcm-hooks-post-up
  env PATH="/usr/bin:$PATH" rcup

[working-directory: "rcm"]
build-rcm-rcrc:
  # TODO
  cp rcrc ~/.rcrc

[working-directory: "rcm/hooks/pre-up"]
@build-rcm-hooks-pre-up:
  chmod +x *

[working-directory: "rcm/hooks/post-up"]
@build-rcm-hooks-post-up:
  chmod +x *

build: build-nix build-rcm
