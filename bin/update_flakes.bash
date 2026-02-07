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
  (cd "$abs_dir" && fh add "${stable_flake_path}")
  (cd "$abs_dir" && fh add --input-name nixpkgs-master "${master_flake_path}")
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
