#! /usr/bin/env -S bash -e
set -euo pipefail

# Default values
CLONE="true"
COMMAND=""
FORCE="false"
ALL="false"

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
  echo "  -f           Force operation (skip safety checks)"
  echo "  -h           Show this help message"
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
while getopts "afh" opt; do
  case $opt in
  a)
    ALL="true"
    ;;
  f)
    FORCE="true"
    ;;
  h)
    usage
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
        temp_dir="$(git remote get-url "$sweatshop_id")"

        if [[ -d $temp_dir ]]; then
          local current_branch parent_branch
          current_branch="$(git -C "$temp_dir" branch --show-current)"
          parent_branch="$(git branch --show-current)"

          # Check if sweatshop has commits not in parent repo
          if git -C "$temp_dir" rev-list --count "$parent_branch..$current_branch" 2>/dev/null | grep -q '^[1-9]'; then
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
      temp_dir="$(git remote get-url "$sweatshop_id")"

      if [[ -n $temp_dir && -d $temp_dir ]]; then
        echo "Removing temporary directory: $temp_dir" >&2
        rm -rf "$temp_dir" 2>/dev/null || true
      fi

      if [[ -n $CLONE && -n $sweatshop_id ]]; then
        echo "Removing git remote: $sweatshop_id" >&2
        git remote remove "$sweatshop_id"
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
  temp_dir="$(git remote get-url "$sweatshop_id")"

  # Check if there are unmerged changes against the parent repo (unless force is used)
  if [[ $FORCE != "true" && -d $temp_dir ]]; then
    local current_branch parent_branch
    current_branch="$(git -C "$temp_dir" branch --show-current)"
    parent_branch="$(git branch --show-current)"

    # Check if sweatshop has commits not in parent repo
    if git -C "$temp_dir" rev-list --count "$parent_branch..$current_branch" 2>/dev/null | grep -q '^[1-9]'; then
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

  if [[ -n $temp_dir && -d $temp_dir ]]; then
    echo "Removing temporary directory: $temp_dir" >&2
    rm -rf "$temp_dir" 2>/dev/null || true
  fi

  if [[ -n $CLONE && -n $sweatshop_id ]]; then
    echo "Removing git remote: $sweatshop_id" >&2
    git remote remove "$sweatshop_id"
  fi

  exit $exit_code
}

create() {
  local custom_sweatshop_id="${1:-}"
  local temp_dir sweatshop_id

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

  # Create necessary directories if they don't exist
  mkdir -p "$HOME/.config/claude" >/dev/null 2>&1
  mkdir -p "$HOME/.local/share/claude" >/dev/null 2>&1

  # return value
  echo -n "$sweatshop_id"
}

run_temp() {
  trap 'destroy "$sweatshop_id"' EXIT INT TERM
  local sweatshop_id
  sweatshop_id="$(create "${1:-}")"
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
  temp_dir="$(git remote get-url "$sweatshop_id")"
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
  temp_dir="$(git remote get-url "$sweatshop_id")"
  branch="$(git branch --show-current)"

  git push "$sweatshop_id" HEAD:refs/heads/temp-updates
  git -C "$temp_dir" rebase temp-updates "$branch"
  git -C "$temp_dir" branch -d temp-updates

  # Clean up the remote tracking branch created in parent repo
  git branch -d -r "$sweatshop_id/temp-updates" 2>/dev/null || true

  git -C "$temp_dir" checkout .
  git add -N . # Add untracked files to index without staging content
  git diff HEAD | git -C "$temp_dir" apply --allow-empty -
}

pull() {
  local sweatshop_id
  sweatshop_id="$(get "${1:-}")"

  local branch
  branch="${2:-$(git branch --show-current)}"

  local temp_dir

  temp_dir="$(git remote get-url "$sweatshop_id")"
  branch="$(git branch --show-current)"

  git pull "$sweatshop_id" "$branch"
}

sync() {
  local sweatshop_id
  sweatshop_id="$(get "${1:-}")"

  pull "$sweatshop_id"
  push "$sweatshop_id"
}

list() {
  # List all git remotes that start with 'sweatshop-'
  git remote -v | grep "^sweatshop-" | awk '{print $1}' | sort -u
}

validate_remote() {
  local remote="${1:-}"

  # Validate that remote exists and is prefixed with 'sweatshop-'
  if ! git remote get-url "$remote" >/dev/null 2>&1; then
    echo "Error: Remote '$remote' does not exist" >&2
    exit 1
  fi

  if [[ $remote != sweatshop-* ]]; then
    echo "Error: Remote '$remote' must be prefixed with 'sweatshop-'" >&2
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
get) get "$@" ;;
list) list "$@" ;;
pull) pull "$@" ;;
push) push "$@" ;;
run) run "$@" ;;
run-temp) run_temp "$@" ;;
sync) sync "$@" ;;
esac
