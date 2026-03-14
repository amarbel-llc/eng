#! /usr/bin/env -S bash

set -euo pipefail

# Track visited flakes to avoid cycles
declare -A visited

update_flake_recursive() {
  local dir="$1"
  local abs_dir

  abs_dir=$(realpath "$dir")

  # Skip if already visited
  if [[ -n ${visited[$abs_dir]:-} ]]; then
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
    local deps
    # Extract local path inputs from flake.lock
    deps=$(jq -r '.nodes | to_entries[] | select(.value.locked.type == "path") | .value.locked.path' "$abs_dir/flake.lock" 2>/dev/null || true)

    for dep in $deps; do
      # Convert relative to absolute path
      if [[ ! $dep == /* ]]; then
        dep="$abs_dir/$dep"
      fi
      update_flake_recursive "$dep"
    done
  fi

  local master_flake_path
  local stable_flake_path

  stable_flake_path="github:NixOS/nixpkgs/$(cat "$file_nixpkgs_stable_git_sha")"
  master_flake_path="github:NixOS/nixpkgs/$(cat "$file_nixpkgs_git_master_sha")"

  # Update current flake after dependencies (stable-first convention)
  echo "Updating: $abs_dir"

  if ! grep -q 'nixpkgs\.follows' "$abs_dir/flake.nix"; then
    (cd "$abs_dir" && fh add "${stable_flake_path}")
  fi

  if grep -q 'nixpkgs-master' "$abs_dir/flake.nix" && \
     ! grep -q 'nixpkgs-master\.follows' "$abs_dir/flake.nix"; then
    (cd "$abs_dir" && fh add --input-name nixpkgs-master "${master_flake_path}")
  fi

  if ! grep -q 'utils\.follows' "$abs_dir/flake.nix"; then
    (cd "$abs_dir" && fh add --input-name utils numtide/flake-utils)
  fi

  # Check if flake.nix is tracked by git - if not, use path: prefix
  # This handles directories in untracked paths of parent repos
  if (cd "$abs_dir" && git ls-files --error-unmatch flake.nix &>/dev/null); then
    # flake.nix is tracked, use normal update
    (cd "$abs_dir" && nix flake update)
  else
    # flake.nix is not tracked (or no git repo), use path: prefix
    (cd "$abs_dir" && nix flake update --flake "path:.")
  fi
}

# Start from current directory or specified directory
root_dir="${1:-.}"

# Exclude patterns (space-separated, default: none)
exclude_patterns="${UPDATE_FLAKES_EXCLUDE:-}"

# Build find exclude args from space-separated patterns
find_excludes=()
set -f  # disable globbing for pattern splitting
for pattern in $exclude_patterns; do
  find_excludes+=(-not -path "$pattern")
done
set +f

# Find all directories with flake.nix and update depth-first
# TODO modify this to generate a list of all flakes first and then perform
# updates on that expanded list. Then modify this to make running `nix flake
# update` optional
find "$root_dir" -name "flake.nix" -type f "${find_excludes[@]}" | while read -r flake_file; do
  flake_dir=$(dirname "$flake_file")
  update_flake_recursive "$flake_dir"
done
