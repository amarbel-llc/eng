#! /usr/bin/env -S bash -e
set -euo pipefail

# Default values
CLONE="true"
COMMAND=""
FORCE="false"
ALL="false"
WORKTREE="false"
PULL="false"
DESTROY="false"

# TODO update this to not hardcode claude as the agent

# Function to show usage
usage() {
  echo "Usage: $0 [COMMAND] [OPTIONS] [args...]"
  echo ""
  echo "Commands:"
  echo "  attach SWEATSHOP_ID         Attach to an existing sweatshop"
  echo "  create [SWEATSHOP_ID]       Create a new sweatshop (optionally with custom ID)"
  echo "  destroy SWEATSHOP_ID        Destroy a sweatshop (will abort if unmerged changes exist, use -f to force)
  destroy -a                  Destroy all sweatshops (will abort if any have unmerged changes exist, use -f to force)"
  echo "  diff [SWEATSHOP_ID]         Show differences between current branch and sweatshop HEAD"
  echo "  get                         Get the single sweatshop ID (fails if multiple exist)"
  echo "  list                        List all sweatshop IDs"
  echo "  pull SWEATSHOP_ID           Pull changes from a sweatshop"
  echo "  push SWEATSHOP_ID           Push changes to a sweatshop"
  echo "  run [SWEATSHOP_ID]          Create a new sweatshop and attach to it (optionally with custom ID)"
  echo "  run-temp [SWEATSHOP_ID]     Create a new sweatshop and attach to it, destroy when it exits (optionally with custom ID)"
  echo "  sync [SWEATSHOP_ID]         Syncs changes to/from a sweatshop."
  echo ""
  echo "Options:"
  echo "  -a           Destroy all sweatshops (only valid with destroy command)"
  echo "  -d           Destroy sweatshop after pulling (only valid with pull command)"
  echo "  -f           Force operation (skip safety checks)"
  echo "  -h           Show this help message"
  echo "  -p           Pull changes before destroying (only valid with run-temp command)"
  echo "  -w           Use git worktrees instead of cloned repos"
  echo ""
  echo "All remaining arguments are passed to the agent (claude-code)"
  exit 1
}

# Parse command (first argument if it doesn't start with -)
if [[ $# -gt 0 && $1 != -* ]]; then
  COMMAND="$1"
  shift
else
  usage
fi

# Validate command
case $COMMAND in
# keep these sorted
attach) ;;
create) ;;
destroy) ;;
diff) ;;
get) ;;
list) ;;
pull) ;;
push) ;;
run) ;;
run-temp) ;;
sync) ;;
*)
  echo "Error: Unknown command '$COMMAND'" >&2
  usage
  ;;
esac

# Parse command line options
while getopts "afhpdw" opt; do
  case $opt in
  a)
    ALL="true"
    ;;
  d)
    DESTROY="true"
    ;;
  f)
    FORCE="true"
    ;;
  h)
    usage
    ;;
  p)
    PULL="true"
    ;;
  w)
    WORKTREE="true"
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    ;;
  esac
done

# Shift to get remaining arguments for claude
shift $((OPTIND - 1))

# Validate that -a flag is only used with destroy command
if [[ $ALL == "true" && $COMMAND != "destroy" ]]; then
  echo "Error: -a flag can only be used with destroy command" >&2
  usage
fi

# Validate that -p flag is only used with run-temp command
if [[ $PULL == "true" && $COMMAND != "run-temp" ]]; then
  echo "Error: -p flag can only be used with run-temp command" >&2
  usage
fi

# Validate that -d flag is only used with pull command
if [[ $DESTROY == "true" && $COMMAND != "pull" ]]; then
  echo "Error: -d flag can only be used with pull command" >&2
  usage
fi

# Helper functions for worktree support
is_worktree() {
  local sweatshop_id="${1:-}"
  if [[ -z $sweatshop_id ]]; then
    return 1
  fi

  # Check if this sweatshop_id exists as a worktree
  git worktree list --porcelain | grep -q "^worktree.*$sweatshop_id"
}

get_worktree_path() {
  local sweatshop_id="${1:-}"
  if [[ -z $sweatshop_id ]]; then
    return 1
  fi

  # Get worktree path from git worktree list
  git worktree list --porcelain | awk "/^worktree.*$sweatshop_id/ { print \$2 }"
}

list_worktrees() {
  # List all worktrees that match sweatshop pattern
  git worktree list --porcelain | awk '/^worktree/ { path=$2; if (match(path, /sweatshop-claude-[^\/]*$/)) print substr(path, RSTART, RLENGTH) }' | sort -u
}

get_sweatshop_path() {
  local sweatshop_id="${1:-}"
  if [[ -z $sweatshop_id ]]; then
    return 1
  fi

  # Check if it's a worktree first
  if git worktree list --porcelain | grep -q "worktree.*$sweatshop_id"; then
    git worktree list --porcelain | awk "/^worktree.*$sweatshop_id/ { print \$2 }"
  else
    # Fall back to git remote (clone mode)
    git remote get-url "$sweatshop_id" 2>/dev/null || return 1
  fi
}

# TODO update this to support tab-completion thru the list of git remotes
# prefixed with `sweatshop`
destroy() {
  if [[ $ALL == "true" ]]; then
    # Destroy all sweatshops
    local sweatshops
    sweatshops=$(list)

    if [[ -z $sweatshops ]]; then
      echo "No sweatshops to destroy" >&2
      return 0
    fi

    # Check for unmerged changes in all sweatshops first (unless force is used)
    if [[ $FORCE != "true" ]]; then
      while IFS= read -r sweatshop_id; do
        local temp_dir
        temp_dir="$(get_sweatshop_path "$sweatshop_id")"

        if [[ -d $temp_dir ]]; then
          # Check if sweatshop changes have been integrated into parent
          local parent_commit sweatshop_commit merge_base
          parent_commit="$(git rev-parse HEAD)"
          sweatshop_commit="$(git -C "$temp_dir" rev-parse HEAD)"
          merge_base="$(git merge-base "$parent_commit" "$sweatshop_commit" 2>/dev/null || echo "")"

          # If sweatshop commit is not an ancestor of parent, check for unmerged changes
          if [[ $merge_base != "$sweatshop_commit" ]]; then
            echo "Error: Sweatshop '$sweatshop_id' has unmerged changes" >&2
            echo "Use 'pull' or 'sync' to merge changes before destroying, or use -f to force" >&2
            exit 1
          fi

          # Check if sweatshop has uncommitted changes
          if ! git -C "$temp_dir" diff-index --quiet HEAD 2>/dev/null; then
            echo "Error: Sweatshop '$sweatshop_id' has uncommitted changes" >&2
            echo "Commit or stash changes before destroying, or use -f to force" >&2
            exit 1
          fi
        fi
      done <<<"$sweatshops"
    fi

    # Destroy all sweatshops
    while IFS= read -r sweatshop_id; do
      local temp_dir
      temp_dir="$(get_sweatshop_path "$sweatshop_id")"

      # Check if it's a worktree
      if git worktree list --porcelain | grep -q "worktree.*$sweatshop_id"; then
        echo "Removing worktree: $temp_dir" >&2
        git worktree remove "$temp_dir" --force 2>/dev/null || true
      else
        # Handle as clone/remote
        if [[ -n $temp_dir && -d $temp_dir ]]; then
          echo "Removing temporary directory: $temp_dir" >&2
          rm -rf "$temp_dir" 2>/dev/null || true
        fi

        if [[ -n $CLONE && -n $sweatshop_id ]]; then
          echo "Removing git remote: $sweatshop_id" >&2
          git remote remove "$sweatshop_id" 2>/dev/null || true
        fi
      fi
    done <<<"$sweatshops"

    echo "All sweatshops destroyed" >&2
    return 0
  fi

  # Single sweatshop destroy (original behavior)
  local sweatshop_id
  sweatshop_id="$(get "${1:-}")"

  local exit_code=$?

  local temp_dir
  temp_dir="$(get_sweatshop_path "$sweatshop_id")"

  # Check if there are unmerged changes against the parent repo (unless force is used)
  if [[ $FORCE != "true" && -d $temp_dir ]]; then
    # Check if sweatshop changes have been integrated into parent
    local parent_commit sweatshop_commit merge_base
    parent_commit="$(git rev-parse HEAD)"
    sweatshop_commit="$(git -C "$temp_dir" rev-parse HEAD)"
    merge_base="$(git merge-base "$parent_commit" "$sweatshop_commit" 2>/dev/null || echo "")"

    # If sweatshop commit is not an ancestor of parent, check for unmerged changes
    if [[ $merge_base != "$sweatshop_commit" ]]; then
      echo "Error: Sweatshop '$sweatshop_id' has unmerged changes" >&2
      echo "Use 'pull' or 'sync' to merge changes before destroying, or use -f to force" >&2
      exit 1
    fi

    # Check if sweatshop has uncommitted changes
    if ! git -C "$temp_dir" diff-index --quiet HEAD 2>/dev/null; then
      echo "Error: Sweatshop '$sweatshop_id' has uncommitted changes" >&2
      echo "Commit or stash changes before destroying, or use -f to force" >&2
      exit 1
    fi
  fi

  # Check if it's a worktree
  if git worktree list --porcelain | grep -q "worktree.*$sweatshop_id"; then
    echo "Removing worktree: $temp_dir" >&2
    git worktree remove "$temp_dir" --force 2>/dev/null || true
  else
    # Handle as clone/remote
    if [[ -n $temp_dir && -d $temp_dir ]]; then
      echo "Removing temporary directory: $temp_dir" >&2
      rm -rf "$temp_dir" 2>/dev/null || true
    fi

    if [[ -n $CLONE && -n $sweatshop_id ]]; then
      echo "Removing git remote: $sweatshop_id" >&2
      git remote remove "$sweatshop_id" 2>/dev/null || true
    fi
  fi

  exit $exit_code
}

create() {
  local custom_sweatshop_id="${1:-}"
  local temp_dir sweatshop_id

  if [[ $WORKTREE == "true" ]]; then
    # Worktree mode
    local current_branch
    current_branch="$(git branch --show-current)"

    if [[ -n $custom_sweatshop_id ]]; then
      sweatshop_id="sweatshop-claude-$custom_sweatshop_id"
    else
      sweatshop_id="sweatshop-claude-$(date +%s)-$$"
    fi

    temp_dir="$(mktemp -d -t "$sweatshop_id-XXXXXX")"

    echo "Creating worktree: $temp_dir" >&2

    if ! git worktree add "$temp_dir" "$current_branch" >/dev/null 2>&1; then
      echo "Error: Failed to create worktree" >&2
      exit 1
    fi

    # Configure git user in worktree
    if ! git -C "$temp_dir" config user.email "claude@anthropic.com" >/dev/null 2>&1; then
      echo "Error: Failed to update worktree user.email" >&2
      git worktree remove "$temp_dir" --force >/dev/null 2>&1 || true
      exit 1
    fi

    if ! git -C "$temp_dir" config user.name "Claude Code" >/dev/null 2>&1; then
      echo "Error: Failed to update worktree user.name" >&2
      git worktree remove "$temp_dir" --force >/dev/null 2>&1 || true
      exit 1
    fi

    echo "Worktree created successfully: $temp_dir" >&2
  else
    # Clone mode (original behavior)
    temp_dir="$(mktemp -d -t "sweatshop-claude-XXXXXX")"

    if [[ -n $custom_sweatshop_id ]]; then
      sweatshop_id="sweatshop-claude-$custom_sweatshop_id"
    else
      sweatshop_id="$(basename "$temp_dir")"
    fi

    local origin
    origin="$(git rev-parse --show-toplevel)"

    if [[ -n $CLONE ]]; then
      (
        pushd "$temp_dir" >/dev/null 2>&1 || true

        if ! git clone --local "$origin" . >/dev/null 2>&1; then
          echo "Error: Failed to clone repo" >&2
          exit 1
        fi

        echo "Clone directory: $temp_dir" >&2

        if ! git config user.email "claude@anthropic.com" >/dev/null 2>&1; then
          echo "Error: Failed to update clone user.email" >&2
          exit 1
        fi

        if ! git config user.name "Claude Code" >/dev/null 2>&1; then
          echo "Error: Failed to update clone user.name" >&2
          exit 1
        fi

        echo "Git user config created successfully" >&2
      )

      if ! git remote add "$sweatshop_id" "$temp_dir" >/dev/null 2>&1; then
        echo "Error: Failed to add remote: $sweatshop_id" >&2
        exit 1
      fi

      echo "Git remote added successfully: $sweatshop_id" >&2
    fi
  fi

  # Create necessary directories if they don't exist
  mkdir -p "$HOME/.config/claude" >/dev/null 2>&1
  mkdir -p "$HOME/.local/share/claude" >/dev/null 2>&1

  # return value
  echo -n "$sweatshop_id"
}

run_temp() {
  local sweatshop_id
  sweatshop_id="$(create "${1:-}")"

  if [[ $PULL == "true" ]]; then
    trap 'pull "$sweatshop_id"; destroy "$sweatshop_id"' EXIT INT TERM
  else
    trap 'destroy "$sweatshop_id"' EXIT INT TERM
  fi

  attach "$sweatshop_id"
}

run() {
  local sweatshop_id
  sweatshop_id="$(create "${1:-}")"
  attach "$sweatshop_id"
}

attach() {
  local sweatshop_id
  sweatshop_id="$(get "${1:-}")"

  local temp_dir workspace_path
  temp_dir="$(get_sweatshop_path "$sweatshop_id")"
  workspace_path="$(realpath --relative-to="$(git rev-parse --show-toplevel)" .)"

  # cannot use exec otherwise the cleanup TRAP won't execute
  @bwrap@ \
    --ro-bind / / \
    --bind "$temp_dir" /mnt \
    --tmpfs /tmp \
    --bind "$HOME/.config/claude" /tmp/config \
    --bind "$HOME/.local/share/claude" /tmp/data \
    --bind "./.claude" "/mnt/$workspace_path/.claude" \
    --chdir "/mnt/$workspace_path" \
    --tmpfs /home \
    --tmpfs /root \
    --setenv XDG_CONFIG_HOME /tmp/config \
    --setenv XDG_DATA_HOME /tmp/data \
    --setenv CLAUDE_CONFIG_DIR /tmp/config \
    --setenv CLAUDE_DATA_DIR /tmp/data \
    --dev-bind /dev/null /dev/null \
    --dev-bind /dev/zero /dev/zero \
    --dev-bind /dev/random /dev/random \
    --dev-bind /dev/urandom /dev/urandom \
    --unshare-all \
    --share-net \
    --die-with-parent \
    @claude-code@
}

# TODO add support for force pushes
push() {
  local sweatshop_id
  sweatshop_id="$(get "${1:-}")"

  local branch
  branch="${2:-$(git branch --show-current)}"

  local temp_dir
  temp_dir="$(get_sweatshop_path "$sweatshop_id")"
  branch="$(git branch --show-current)"

  # Check if it's a worktree
  if git worktree list --porcelain | grep -q "worktree.*$sweatshop_id"; then
    # For worktrees, we need to handle this differently since they share the same repo
    # First, commit current changes to temp branch, then rebase in worktree
    local temp_branch
    temp_branch="temp-push-$(date +%s)"

    git add -A
    git commit -m "Temporary commit for push to $sweatshop_id" --allow-empty
    git branch "$temp_branch"

    # Switch to worktree and rebase
    git -C "$temp_dir" fetch . "$temp_branch:$temp_branch"
    git -C "$temp_dir" rebase "$temp_branch"

    # Clean up temp branch
    git branch -D "$temp_branch"
    git -C "$temp_dir" branch -D "$temp_branch" 2>/dev/null || true
  else
    # Original clone-based behavior
    git push "$sweatshop_id" HEAD:refs/heads/temp-updates
    git -C "$temp_dir" rebase temp-updates "$branch"
    git -C "$temp_dir" branch -d temp-updates

    # Clean up the remote tracking branch created in parent repo
    git branch -d -r "$sweatshop_id/temp-updates" 2>/dev/null || true

    git -C "$temp_dir" checkout .
    git add -N . # Add untracked files to index without staging content
    git diff HEAD | git -C "$temp_dir" apply --allow-empty -
  fi
}

pull() {
  local sweatshop_id
  sweatshop_id="$(get "${1:-}")"

  local branch
  branch="${2:-$(git branch --show-current)}"

  local temp_dir
  temp_dir="$(get_sweatshop_path "$sweatshop_id")"
  branch="$(git branch --show-current)"

  # Check if it's a worktree
  if git worktree list --porcelain | grep -q "worktree.*$sweatshop_id"; then
    # For worktrees, we need to handle this differently
    # Create a temporary branch from worktree state
    local temp_branch
    temp_branch="temp-pull-$(date +%s)"
    git -C "$temp_dir" branch "$temp_branch"

    # Switch to main repo and merge the changes
    git fetch . "refs/heads/$temp_branch:refs/heads/$temp_branch"
    git merge "$temp_branch"

    # Clean up temp branch
    git branch -D "$temp_branch"
    git -C "$temp_dir" branch -D "$temp_branch" 2>/dev/null || true
  else
    # Original clone-based behavior
    git pull "$sweatshop_id" "$branch"
  fi

  # Destroy sweatshop after pulling if -d flag is used
  if [[ $DESTROY == "true" ]]; then
    destroy "$sweatshop_id"
  fi
}

diff() {
  local sweatshop_id
  sweatshop_id="$(get "${1:-}")"

  local temp_dir current_branch
  temp_dir="$(get_sweatshop_path "$sweatshop_id")"
  current_branch="$(git branch --show-current)"

  # Check if it's a worktree
  if git worktree list --porcelain | grep -q "worktree.*$sweatshop_id"; then
    # For worktrees, find merge base and show changes since divergence
    local sweatshop_branch merge_base
    sweatshop_branch="$(git -C "$temp_dir" branch --show-current)"
    merge_base="$(git merge-base HEAD "refs/heads/$sweatshop_branch" 2>/dev/null || echo "")"

    if [[ -n $merge_base ]]; then
      echo "Showing changes in sweatshop ($sweatshop_id:$sweatshop_branch) since divergence from $current_branch:"
      git diff "$merge_base" "refs/heads/$sweatshop_branch"
    else
      echo "No common history found between $current_branch and sweatshop ($sweatshop_id:$sweatshop_branch)"
      git diff HEAD "refs/heads/$sweatshop_branch"
    fi
  else
    # For clones, find merge base and show changes since divergence
    local sweatshop_branch merge_base
    sweatshop_branch="$(git -C "$temp_dir" branch --show-current)"

    # Create a temporary remote ref to compare against
    local temp_ref
    temp_ref="temp-diff-$(date +%s)"

    # Fetch the sweatshop's current HEAD to a temporary ref
    git -C "$temp_dir" push . HEAD:"refs/heads/$temp_ref" >/dev/null 2>&1
    git fetch "$sweatshop_id" "$temp_ref:refs/remotes/$sweatshop_id/$temp_ref" >/dev/null 2>&1

    # Find merge base between current HEAD and sweatshop HEAD
    merge_base="$(git merge-base HEAD "refs/remotes/$sweatshop_id/$temp_ref" 2>/dev/null || echo "")"

    if [[ -n $merge_base ]]; then
      echo "Showing changes in sweatshop ($sweatshop_id:$sweatshop_branch) since divergence from $current_branch:"
      git diff "$merge_base" "refs/remotes/$sweatshop_id/$temp_ref"
    else
      echo "No common history found between $current_branch and sweatshop ($sweatshop_id:$sweatshop_branch)"
      git diff HEAD "refs/remotes/$sweatshop_id/$temp_ref"
    fi

    # Clean up temporary refs
    git -C "$temp_dir" branch -D "$temp_ref" 2>/dev/null || true
    git branch -d -r "$sweatshop_id/$temp_ref" 2>/dev/null || true
  fi
}

sync() {
  local sweatshop_id
  sweatshop_id="$(get "${1:-}")"

  pull "$sweatshop_id"
  push "$sweatshop_id"
}

list() {
  # List all sweatshops (both git remotes and worktrees)
  local remotes worktrees

  # Get git remotes that start with 'sweatshop-'
  remotes=$(git remote -v | grep "^sweatshop-" | awk '{print $1}' | sort -u)

  # Get worktrees that match sweatshop pattern
  worktrees=$(list_worktrees)

  # Combine and sort uniquely
  {
    [[ -n $remotes ]] && echo "$remotes"
    [[ -n $worktrees ]] && echo "$worktrees"
  } | sort -u
}

validate_remote() {
  local sweatshop_id="${1:-}"

  # Check if sweatshop_id is prefixed with 'sweatshop-'
  if [[ $sweatshop_id != sweatshop-* ]]; then
    echo "Error: Sweatshop ID '$sweatshop_id' must be prefixed with 'sweatshop-'" >&2
    exit 1
  fi

  # Validate that sweatshop exists (either as remote or worktree)
  if ! git remote get-url "$sweatshop_id" >/dev/null 2>&1 && ! git worktree list --porcelain | grep -q "worktree.*$sweatshop_id"; then
    echo "Error: Sweatshop '$sweatshop_id' does not exist" >&2
    exit 1
  fi
}

get() {
  local sweatshop_id
  sweatshop_id="${1:-}"

  if [[ -n $sweatshop_id ]]; then
    validate_remote "$sweatshop_id"
    echo -n "$sweatshop_id"
    return
  fi

  # Get the single sweatshop ID, fail if there are multiple
  local sweatshops
  sweatshops=$(list)

  if [[ -z $sweatshops ]]; then
    echo "Error: No sweatshops found" >&2
    exit 1
  fi

  local count
  count=$(echo "$sweatshops" | wc -l)

  if [[ $count -gt 1 ]]; then
    echo "Error: Multiple sweatshops found:" >&2
    while IFS= read -r line; do
      echo "  $line" >&2
    done <<<"$sweatshops"
    exit 1
  fi

  validate_remote "$sweatshops"
  echo -n "$sweatshops"
}

case $COMMAND in
# keep these sorted
attach) attach "$@" ;;
create) create "$@" ;;
destroy) destroy "$@" ;;
diff) diff "$@" ;;
get) get "$@" ;;
list) list "$@" ;;
pull) pull "$@" ;;
push) push "$@" ;;
run) run "$@" ;;
run-temp) run_temp "$@" ;;
sync) sync "$@" ;;
esac
