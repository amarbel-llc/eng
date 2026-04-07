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
      if [[ $dep != /* ]]; then
        dep="$abs_dir/$dep"
      fi
      update_flake_recursive "$dep"
    done
  fi

  local master_sha
  master_sha="$(cat "$file_nixpkgs_git_master_sha")"

  # Cascade eng's nixpkgs-master pin into this flake's nixpkgs-master
  # input via a line-anchored sed. The /nixpkgs-master\.url/ address
  # ensures we only touch the master SHA literal even when the flake
  # also has a stable nixpkgs SHA literal on a separate line.
  echo "Updating: $abs_dir"

  if grep -q 'nixpkgs-master\.url' "$abs_dir/flake.nix"; then
    sed -i -E "/nixpkgs-master\.url/ s|(github:NixOS/nixpkgs/)[0-9a-f]{40}|\\1${master_sha}|" "$abs_dir/flake.nix"
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
set -f # disable globbing for pattern splitting
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
