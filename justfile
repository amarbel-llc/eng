export PATH := join(env_var('HOME'), "eng", "result", "bin") + ":" + env_var('PATH')

default: build

clean-nix:
  nix-store --gc

clean: clean-nix

nix_nixpkgs_stable_git_branch := "nixos-25.05"

file_nixpkgs_git_master_sha := "nixpkgs-git-master.git-sha"
file_nixpkgs_stable_git_sha := "nixpkgs-stable-git.git-sha"

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


update-nix:
  #!/usr/bin/env bash

  set -euo pipefail

  # Track visited flakes to avoid cycles
  declare -A visited

  update_flake_recursive() {
      local dir="$1"
      local abs_dir=$(realpath "$dir")
      
      # Skip if already visited
      if [[ -n "${visited[$abs_dir]:-}" ]]; then
          return 0
      fi
      
      # Check if flake.nix exists
      if [[ ! -f "$abs_dir/flake.nix" ]]; then
          return 0
      fi
      
      echo "Processing: $abs_dir"
      visited[$abs_dir]=1
      
      # Parse local flake inputs and recurse
      if [[ -f "$abs_dir/flake.lock" ]]; then
          # Extract local path inputs from flake.lock
          local deps=$(jq -r '.nodes | to_entries[] | select(.value.locked.type == "path") | .value.locked.path' "$abs_dir/flake.lock" 2>/dev/null || true)
          
          for dep in $deps; do
              # Convert relative to absolute path
              if [[ ! "$dep" = /* ]]; then
                  dep="$abs_dir/$dep"
              fi
              update_flake_recursive "$dep"
          done
      fi

      local master_flake_path="github:NixOS/nixpkgs/$(cat "{{file_nixpkgs_git_master_sha}}")"
      local stable_flake_path="github:NixOS/nixpkgs/$(cat "{{file_nixpkgs_stable_git_sha}}")"
      
      # Update current flake after dependencies
      echo "Updating: $abs_dir"
      (cd "$abs_dir" && fh add "${master_flake_path}")
      (cd "$abs_dir" && fh add --input-name nixpkgs-stable "${stable_flake_path}")
      (cd "$abs_dir" && fh add --input-name utils numtide/flake-utils)
      (cd "$abs_dir" && nix flake update)
  }

  # Start from current directory or specified directory
  root_dir="${1:-.}"

  # Find all directories with flake.nix and update depth-first
  # TODO modify this to generate a list of all flakes first and then perform
  # updates on that expanded list. Then modify this to make running `nix flake
  # update` optional
  find "$root_dir" -name "flake.nix" -type f | while read -r flake_file; do
      flake_dir=$(dirname "$flake_file")
      update_flake_recursive "$flake_dir"
  done

update: update-nix

build-nix:
  nix build --show-trace

[working-directory: "rcm"]
build-rcm: build-rcm-hooks-pre-up build-rcm-hooks-post-up
  rcup

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
