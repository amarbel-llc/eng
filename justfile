set output-format := "tap"

export PATH := join(env_var('HOME'), "eng", "result", "bin") + ":" + env_var('PATH')

# git pull and and flake update
default: && build-nix deploy-flake-lock build-rcm install-purse-first
  git pull
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

install-purse-first:
  purse-first install

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
  echo "Fetched nixpkgs stable_darwin git {{nix_nixpkgs_stable_darwin_git_branch}} digest: ${nix_nixpkgs_stable_darwin_git_digest}" >&2
  echo ${nix_nixpkgs_stable_darwin_git_digest} > {{file_nixpkgs_stable_darwin_git_sha}}


# Update flakes in main eng repo (excludes repos/)
update-nix:
  UPDATE_FLAKES_EXCLUDE="./repos/*" ./bin/update_flakes.bash

# Update a single repo's flake inputs using top-level git SHAs
[no-exit-message]
_update-repo-flake dir:
  #!/usr/bin/env bash
  set -euo pipefail

  dir="$(realpath "{{dir}}")"
  name="$(basename "$dir")"

  if [[ ! -f "$dir/flake.nix" ]]; then
    gum log --level warn "$name: no flake.nix, skipping"
    exit 0
  fi

  stable_sha="$(cat "{{file_nixpkgs_stable_git_sha}}")"
  master_sha="$(cat "{{file_nixpkgs_git_master_sha}}")"

  gum log --level info "$name: updating flake inputs"

  cd "$dir"
  fh add "github:NixOS/nixpkgs/${stable_sha}"

  if grep -q 'nixpkgs-master' flake.nix; then
    fh add --input-name nixpkgs-master "github:NixOS/nixpkgs/${master_sha}"
  fi

  fh add --input-name utils numtide/flake-utils
  nix flake update

  gum log --level info "$name: done"

# Update flakes in repos/ in parallel (separate git repositories)
update-nix-repos:
  #!/usr/bin/env bash
  set -euo pipefail

  stable_sha="$(cat "$file_nixpkgs_stable_git_sha")"
  master_sha="$(cat "$file_nixpkgs_git_master_sha")"
  stable_ref="github:NixOS/nixpkgs/${stable_sha}"
  master_ref="github:NixOS/nixpkgs/${master_sha}"

  tmpdir="$(mktemp -d)"
  trap 'rm -rf "$tmpdir"' EXIT

  pids=()
  names=()

  for dir in repos/*/; do
    if [[ ! -f "$dir/flake.nix" ]]; then
      continue
    fi

    abs_dir="$(realpath "$dir")"
    name="$(basename "$abs_dir")"
    log_file="$tmpdir/$name.log"

    (
      cd "$abs_dir"
      echo "updating flake inputs"
      fh add "$stable_ref"

      if grep -q 'nixpkgs-master' flake.nix; then
        fh add --input-name nixpkgs-master "$master_ref"
      fi

      fh add --input-name utils numtide/flake-utils
      nix flake update
      echo "done"
    ) > "$log_file" 2>&1 &

    pids+=($!)
    names+=("$name")
  done

  gum log --level info "updating ${#pids[@]} repos in parallel"

  failed=0
  for i in "${!pids[@]}"; do
    if wait "${pids[$i]}"; then
      gum log --level info "${names[$i]}: updated"
    else
      gum log --level error "${names[$i]}: failed"
      cat "$tmpdir/${names[$i]}.log" >&2
      failed=$((failed + 1))
    fi
  done

  if [[ $failed -gt 0 ]]; then
    gum log --level error "$failed repo(s) failed to update"
    exit 1
  fi

  gum log --level info "all ${#pids[@]} repos updated"

# Update all flakes (main repo + repos/)
update-nix-all: update-nix update-nix-repos

update: update-nix

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
