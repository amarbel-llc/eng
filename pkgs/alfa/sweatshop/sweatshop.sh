#! /usr/bin/env -S bash -e
set -euo pipefail

# Default values
COMMAND=""
FORCE="false"
ALL="false"
SWEATSHOP_ID=""

# TODO support other $AGENT's
AGENT=claude

# Function to show usage
usage() {
  echo "Usage: $0 [COMMAND] [OPTIONS] [args...]"
  echo ""
  echo "Commands:"
  echo "  attach SWEATSHOP_ID [args...] Attach to an existing sweatshop"
  echo "  create [SWEATSHOP_ID]         Create a new sweatshop (optionally with custom ID)"
  echo "  destroy SWEATSHOP_ID          Destroy a sweatshop (will abort if unmerged changes exist, use -f to force)
  destroy -a                    Destroy all sweatshops (will abort if any have unmerged changes exist, use -f to force)"
  echo "  diff [SWEATSHOP_ID]           Show differences between current branch and sweatshop HEAD"
  echo "  get                           Get the single sweatshop ID (fails if multiple exist)"
  echo "  list                          List all sweatshop IDs"
  echo "  pull [SWEATSHOP_ID]           Pull changes from sweatshop to main branch"
  echo "  run [-s SWEATSHOP_ID] [args...] Create a new sweatshop and attach to it (optionally with custom ID)"
  echo "  run-temp [-s SWEATSHOP_ID] [args...] Create a new sweatshop and attach to it, destroy when it exits (optionally with custom ID)"
  echo "  sync [SWEATSHOP_ID]           Syncs changes to/from a sweatshop."
  echo ""
  echo "Options:"
  echo "  -a           Destroy all sweatshops (only valid with destroy command)"
  echo "  -f           Force operation (skip safety checks)"
  echo "  -h           Show this help message"
  echo "  -s ID        Specify sweatshop ID (for run and run-temp commands)"
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
run) ;;
run-temp) ;;
sync) ;;
*)
  echo "Error: Unknown command '$COMMAND'" >&2
  usage
  ;;
esac

# Parse command line options
while getopts "ahs:" opt; do
  case $opt in
  a)
    ALL="true"
    ;;
  h)
    usage
    ;;
  s)
    SWEATSHOP_ID="$OPTARG"
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    usage
    ;;
  esac
done

# Shift to get remaining arguments for $AGENT
shift $((OPTIND - 1))

# Validate that -a flag is only used with destroy command
if [[ $ALL == "true" && $COMMAND != "destroy" ]]; then
  echo "Error: -a flag can only be used with destroy command" >&2
  usage
fi

run_cmd() {
  name="$1"
  shift

  echo "Run: '$name'" >&2
  echo >&2
  echo "  \$ $*" >&2
  echo >&2

  # shellcheck disable=SC2034
  coproc cmd {
    local needs_newline=""

    # shellcheck disable=SC2068
    eval "$*" 2>&1 | while IFS= read -r line; do
      needs_newline=1
      echo "  > $line" >&2
    done

    status=$?

    if [[ -n $needs_newline ]]; then
      echo >&2
    fi

    exit $status
  }

  # shellcheck disable=SC2154
  if ! wait "$cmd_PID"; then
    echo "Failure: '$name'" >&2
    exit 1
  fi

  echo "Success '$name'" >&2
}

# Helper functions for worktree support
get_worktree_path() {
  local sweatshop_id="${1:-}"
  if [[ -z $sweatshop_id ]]; then
    return 1
  fi

  # Get worktree path from git worktree list
  git worktree list --porcelain | awk "\$0 ~ \"^worktree.*$sweatshop_id\" { print \$2 }"
}

list_worktrees() {
  # List all worktrees that match sweatshop pattern
  git worktree list --porcelain | awk "/^branch/ { path=\$2; if (match(path, \"sweatshop-$AGENT-[^/]*$\")) print substr(path, RSTART, RLENGTH) }" | sort -u
}

get_sweatshop_path() {
  local sweatshop_id="${1:-}"
  if [[ -z $sweatshop_id ]]; then
    return 1
  fi

  # Get worktree path
  git worktree list --porcelain | awk "\$0 ~ \"^worktree.*$sweatshop_id\" { print \$2 }"
  # git worktree list --porcelain | awk "/^branch/ { path=\$2; if (match(path, \"refs/heads/$sweatshop_id\")) print substr(path, RSTART, RLENGTH) }" | sort -u
}

# TODO update this to support tab-completion through the list of worktrees
# prefixed with `sweatshop`
destroy() {
  sweatshops=("$@")

  if [[ $ALL == "true" ]]; then
    # Destroy all sweatshops
    local sweatshops
    mapfile -t sweatshops < <(list)
  fi

  if [[ ${#sweatshops[@]} -eq 0 ]]; then
    echo "No sweatshops to destroy" >&2
    return 0
  fi

  for sweatshop_id in "${sweatshops[@]}"; do
    local temp_dir
    temp_dir="$(get_sweatshop_path "$sweatshop_id")"

    cmd_git_mk_patch=(
      git worktree list --porcelain
    )

    cmd_git_apply_patch=(
      grep -q "worktree.*$sweatshop_id"
    )

    if "${cmd_git_mk_patch[@]}" |
      "${cmd_git_apply_patch[@]}"; then
      run_cmd \
        "remove sweatshop worktree: $sweatshop_id" \
        git worktree remove "$temp_dir" --force \
        >/dev/null
    fi

    if git show-ref --verify --quiet "refs/heads/$sweatshop_id"; then
      run_cmd \
        "remove sweatshop branch: $sweatshop_id" \
        git branch -d "$sweatshop_id" \
        >/dev/null
    fi

  done
}

create() {
  local custom_sweatshop_id="${1:-}"
  local temp_dir sweatshop_id

  # Worktree mode
  local current_branch
  current_branch="$(git branch --show-current)"

  if [[ -n $custom_sweatshop_id ]]; then
    sweatshop_id="sweatshop-$AGENT-$custom_sweatshop_id"
  else
    sweatshop_id="sweatshop-$AGENT-$(date +%Y-%m-%d_%H-%M-%S)-$$"
  fi

  run_cmd \
    "create sweatshop branch: $sweatshop_id" \
    git branch "$sweatshop_id" \
    >/dev/null

  temp_dir="$(mktemp -d -t "$sweatshop_id-XXXXXX")"

  run_cmd \
    "create worktree: $temp_dir" \
    git worktree add "$temp_dir" "$sweatshop_id" \
    >/dev/null

  # Create necessary directories for $AGENT if they don't exist
  # TODO support other $AGENT's
  mkdir -p "$HOME/.config/claude" >/dev/null 2>&1
  mkdir -p "$HOME/.local/share/claude" >/dev/null 2>&1

  run_cmd \
    "mark all working directory changes with --intent-to-add: $sweatshop_id" \
    git add -N . \
    >/dev/null

  run_cmd \
    "applying working directory changes to new worktree: $sweatshop_id" \
    git diff HEAD \| git -C "$temp_dir" apply --3way \
    >/dev/null

  echo -n "$sweatshop_id"
}

run_temp() {
  local sweatshop_id
  sweatshop_id="$(create "$SWEATSHOP_ID")"

  cleanup_temp() {
    local cleanup_sweatshop_id="$1"
    local temp_dir
    temp_dir="$(get_sweatshop_path "$cleanup_sweatshop_id")"

    # Check if worktree is dirty
    if git -C "$temp_dir" diff --quiet && git -C "$temp_dir" diff --cached --quiet; then
      # Worktree is clean, destroy without prompting
      destroy "$cleanup_sweatshop_id"
    else
      # Worktree is dirty, show changes and ask for confirmation
      {
        echo "=== Reviewing $cleanup_sweatshop_id changes before pulling ==="
        echo ""
        git -C "$temp_dir" diff --color=always
      } | ${PAGER:-less -R}

      echo "" >&2
      echo -n "Do you want to pull these changes to the current branch before destroying? (y/N): " >&2
      read -r response

      case "$response" in
      [yY] | [yY][eE][sS])
        echo "Pulling changes..." >&2
        if pull "$cleanup_sweatshop_id"; then
          echo "Changes successfully pulled." >&2
        else
          echo "Warning: Failed to pull changes. Aborting." >&2
          exit 1
        fi
        ;;
      *)
        echo "Changes will be lost." >&2
        ;;
      esac

      destroy "$cleanup_sweatshop_id"
    fi
  }

  # shellcheck disable=SC2064
  trap "cleanup_temp '$sweatshop_id'" EXIT INT TERM

  attach "$sweatshop_id" "$@"
}

run() {
  local sweatshop_id
  sweatshop_id="$(create "$SWEATSHOP_ID")"
  attach "$sweatshop_id" "$@"
}

attach() {
  local sweatshop_id
  sweatshop_id="$(get "${1:-}")"
  shift # Remove the sweatshop_id from arguments

  local temp_dir workspace_path
  temp_dir="$(get_sweatshop_path "$sweatshop_id")"
  workspace_path="$(realpath --relative-to="$(git rev-parse --show-toplevel)" .)"

  # TODO support other $AGENT's
  mkdir -p ./.claude

  # cannot use exec otherwise the cleanup TRAP won't execute
  # TODO support other $AGENT's

  # hide git entirely from the agent
  env GIT_DIR=/dev/null \
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
    @claude-code@ "$@"
}

diff() {
  local sweatshop_id
  sweatshop_id="$(get "${1:-}")"

  local temp_dir current_branch
  temp_dir="$(get_sweatshop_path "$sweatshop_id")"
  current_branch="$(git branch --show-current)"

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

  # Show uncommitted changes in the sweatshop
  if ! git -C "$temp_dir" diff-index --quiet HEAD 2>/dev/null; then
    echo ""
    echo "=== Uncommitted changes in sweatshop ==="
    git -C "$temp_dir" diff HEAD
  fi

  # Show untracked files in the sweatshop
  local untracked_files
  untracked_files="$(git -C "$temp_dir" ls-files --others --exclude-standard 2>/dev/null || true)"
  if [[ -n $untracked_files ]]; then
    echo ""
    echo "=== Untracked files in sweatshop ==="
    while IFS= read -r file; do
      echo "diff --git a/$file b/$file"
      echo "new file mode 100644"
      echo "index 0000000..$(git -C "$temp_dir" hash-object "$file" 2>/dev/null || echo "0000000")"
      echo "--- /dev/null"
      echo "+++ b/$file"
      git -C "$temp_dir" diff /dev/null "$file" 2>/dev/null | tail -n +5 || echo "+[Binary file or unreadable content]"
    done <<<"$untracked_files"
  fi
}

list() {
  # List all sweatshops (worktrees only)
  list_worktrees
}

validate_sweatshop() {
  local sweatshop_id="${1:-}"

  # Check if sweatshop_id is prefixed with 'sweatshop-'
  if [[ $sweatshop_id != sweatshop-* ]]; then
    echo "Error: Sweatshop ID '$sweatshop_id' must be prefixed with 'sweatshop-'" >&2
    exit 1
  fi

  # Validate that sweatshop exists as worktree
  if ! git worktree list --porcelain | grep -q "worktree.*$sweatshop_id"; then
    echo "Error: Sweatshop '$sweatshop_id' does not exist" >&2
    exit 1
  fi
}

get() {
  local sweatshop_id
  sweatshop_id="${1:-}"

  if [[ -n $sweatshop_id ]]; then
    validate_sweatshop "$sweatshop_id"
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

  validate_sweatshop "$sweatshops"
  echo -n "$sweatshops"
}

pull() {
  local sweatshop_id
  sweatshop_id="$(get "${1:-}")"
  shift # Remove the sweatshop_id from arguments

  local temp_dir
  temp_dir="$(get_sweatshop_path "$sweatshop_id")"

  # TODO adjust the pull strategy, as it currently fails with conflicts quite
  # often
  run_cmd \
    "adding --intent-to-add sweatshop changes: $sweatshop_id" \
    git -C "$temp_dir" add -N "$temp_dir" \
    >/dev/null

  run_cmd \
    "applying sweatshop patch: $sweatshop_id" \
    git -C "$temp_dir" diff \| git apply --3way \
    >/dev/null
}

sync() {
  echo "not implemented yet" >&1
  exit 1
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
run) run "$@" ;;
run-temp) run_temp "$@" ;;
sync) sync "$@" ;;
esac
