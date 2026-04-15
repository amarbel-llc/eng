#!/usr/bin/env -S bash -e
# @brief Generate ~/.rcrc with interactive tag selection
#
# Discovers available rcm tags from ~/*/rcm/tag-* directories,
# auto-detects platform tags, and presents an interactive chooser.
# Base tags (direnv, nix) from rcm/rcrc are always included.
#
# On re-run, pre-selects tags from the existing ~/.rcrc.

set -uo pipefail

dry_run=false
if [[ ${1:-} == "--dry-run" ]]; then
  dry_run=true
fi

eng_dir="$(cd "$(dirname "$0")/.." && pwd)"
rcrc_src="$eng_dir/rcm/rcrc"

if [[ ! -f $rcrc_src ]]; then
  gum log --level error "rcrc template not found: $rcrc_src"
  exit 1
fi

# --- Auto-detect platform tags ---
os="$(uname -s | tr '[:upper:]' '[:lower:]')"
arch="$(arch)"
platform_tags=("$os" "${os}_${arch}")

# --- Discover available tags from ~/*/rcm/tag-* ---
declare -A seen_tags
available_tags=()
for tag_dir in "$HOME"/*/rcm/tag-*; do
  [[ -d $tag_dir ]] || continue
  tag="${tag_dir##*/tag-}"
  [[ $tag == *obsolete* ]] && continue
  if [[ -z ${seen_tags[$tag]:-} ]]; then
    seen_tags[$tag]=1
    available_tags+=("$tag")
  fi
done

mapfile -t available_tags < <(printf '%s\n' "${available_tags[@]}" | sort)

if [[ ${#available_tags[@]} -eq 0 ]]; then
  gum log --level warn "no tags discovered in ~/*/rcm/tag-*"
fi

# --- Determine pre-selected tags ---
preselected=()

if [[ -f "$HOME/.rcrc" ]]; then
  # Parse existing TAGS from ~/.rcrc
  in_tags=false
  while IFS= read -r line; do
    if [[ $line =~ ^TAGS=\" ]]; then
      in_tags=true
      continue
    fi
    if $in_tags; then
      if [[ $line =~ ^\" ]]; then
        break
      fi
      tag="$(echo "$line" | xargs)"
      [[ -n $tag ]] && preselected+=("$tag")
    fi
  done <"$HOME/.rcrc"
else
  preselected=("${platform_tags[@]}")
fi

# --- Build gum choose arguments ---
gum_args=(--no-limit --header "Select rcm tags (base tags direnv, nix are always included):")

for tag in "${preselected[@]}"; do
  gum_args+=("--selected=$tag")
done

selected="$(printf '%s\n' "${available_tags[@]}" | gum choose "${gum_args[@]}")" || true

if [[ -z $selected ]]; then
  gum log --level warn "no tags selected, using base tags only"
fi

# --- Parse base tags from rcrc_src ---
base_tags=()
in_tags=false
while IFS= read -r line; do
  if [[ $line =~ ^TAGS=\" ]]; then
    in_tags=true
    continue
  fi
  if $in_tags; then
    if [[ $line =~ ^\" ]]; then
      break
    fi
    tag="$(echo "$line" | xargs)"
    [[ -n $tag ]] && base_tags+=("$tag")
  fi
done <"$rcrc_src"

# --- Merge selected + base tags (deduplicated) ---
declare -A all_tags
final_tags=()

for tag in "${base_tags[@]}"; do
  if [[ -z ${all_tags[$tag]:-} ]]; then
    all_tags[$tag]=1
    final_tags+=("$tag")
  fi
done

if [[ -n $selected ]]; then
  while IFS= read -r tag; do
    if [[ -n $tag && -z ${all_tags[$tag]:-} ]]; then
      all_tags[$tag]=1
      final_tags+=("$tag")
    fi
  done <<<"$selected"
fi

# --- Generate ~/.rcrc ---
generate_rcrc() {
  # Copy everything except TAGS and DOTFILES_DIRS blocks
  sed '/^TAGS="/,/^"/d; /^DOTFILES_DIRS=/d' "$rcrc_src"

  printf 'TAGS="\n'
  for tag in "${final_tags[@]}"; do
    printf '  %s\n' "$tag"
  done
  printf '"\n\n'

  printf 'DOTFILES_DIRS="%s/rcm"\n' "$eng_dir"
}

if $dry_run; then
  gum log --level info "dry run — would write ~/.rcrc with tags: ${final_tags[*]}"
  generate_rcrc
else
  generate_rcrc >"$HOME/.rcrc"
  gum log --level info "wrote ~/.rcrc with tags: ${final_tags[*]}"
fi
