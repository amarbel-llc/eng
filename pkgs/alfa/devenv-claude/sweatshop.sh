#!/usr/bin/env bash
set -euo pipefail

# Default values
CLONE="true"
COMMAND=""

# TODO update this to not hardcode claude as the agent

# Function to show usage
usage() {
  # TODO update this to be accurate
  echo "Usage: $0 [COMMAND] [OPTIONS] [args...]"
  echo ""
  echo "Commands:"
  echo "  create                      Create a new sweatshop."
  echo "  run-temp                    Create a new sweatshop and attach to it. Destroy it when it exits."
  echo "  run                         Create a new sweatshop and attach to it"
  echo "  destroy SWEATSHOP_ID        Destroys a sweatshop. Will abort if unmerged changes exist."
  echo "  attach  SWEATSHOP_ID        Attach to an existing sweatshop."
  echo "  push SWEATSHOP_ID           Push changes to a sweatpshop."
  echo "  pull SWEATSHOP_ID           Pull changes from a sweatshop."
  echo ""
  echo "Options:"
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
  COMMAND="run-temp"
fi

# Validate command
case $COMMAND in
# keep these sorted
attach) ;;
create) ;;
destroy) ;;
pull) ;;
push) ;;
run) ;;
run-temp) ;;
*)
  echo "Error: Unknown command '$COMMAND'" >&2
  usage
  ;;
esac

# Parse command line options
while getopts "h" opt; do
  case $opt in
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

# TODO update this to support tab-completion thru the list of git remotes
# prefixed with `sweatshop`
destroy() {
  local sweatshop_id temp_dir
  sweatshop_id="${1:-}"
  shift

  local exit_code=$?

  temp_dir="$(git remote get-url "$sweatshop_id")"

  # TODO check if there are unmerged changes against the parent repo. If there
  # are, do not delete the remote directory or git remote

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

# TODO make sure that all command output is redirected to STDERR except for the
# last command which is treated as a return value
# TODO update this to allow a custom sweatshop_id
create() {
  local temp_dir
  temp_dir=$(mktemp -d -t sweatshop-claude-XXXXXX)

  # TODO be more intelligent about the TEMP_ID, as it could have been
  # user specified
  local sweatshop_id
  sweatshop_id="$(basename "$temp_dir")"

  local origin
  origin="$(git rev-parse --show-toplevel)"

  if [[ -n $CLONE ]]; then
    (
      pushd "$temp_dir" >/dev/null 2>&1 || true

      # Create the worktree
      if ! git clone --local "$origin" .; then
        echo "Error: Failed to clone repo" >&2
        exit 1
      fi

      echo "Cloned successfully" >&2
      echo "Clone directory: $temp_dir" >&2
      echo "" >&2

      if ! git config user.email "claude@anthropic.com"; then
        echo "Error: Failed to update clone user.email" >&2
        exit 1
      fi

      if ! git config user.name "Claude Code"; then
        echo "Error: Failed to update clone user.email" >&2
        exit 1
      fi

      echo "Git user config created successfully" >&2
      echo "" >&2
    )

    # TODO modify the remote add to use a simple counter suffix for unique
    # remotes rather than using the TEMP_ID to make them unique.
    if ! git remote add "$sweatshop_id" "$temp_dir"; then
      echo "Error: Failed to add remote: $sweatshop_id" >&2
      exit 1
    fi

    echo "Git remote added successfully: $sweatshop_id" >&2
    echo "" >&2
  fi

  # Create necessary directories if they don't exist
  mkdir -p "$HOME/.config/claude"
  mkdir -p "$HOME/.local/share/claude"

  # return value
  echo -n "$sweatshop_id"
}

run_temp() {
  trap 'destroy "$sweatshop_id"' EXIT INT TERM
  local sweatshop_id
  sweatshop_id="$(create)"
  attach "$sweatshop_id"
}

run() {
  local sweatshop_id
  sweatshop_id="$(create)"
  attach "$sweatshop_id"
}

attach() {
  local sweatshop_id temp_dir workspace_path
  sweatshop_id="${1:-}"

  shift

  # Validate arguments
  if [[ -z $sweatshop_id ]]; then
    echo "Error: attach command requires SWEATSHOP_ID argument" >&2
    echo "Usage: $0 attach SWEATSHOP_ID" >&2
    exit 1
  fi

  validate_remote "$sweatshop_id"

  temp_dir="$(git remote get-url "$sweatshop_id")"
  workspace_path="$(realpath --relative-to="$(git rev-parse --show-toplevel)" .)"

  # cannot use exec otherwise the cleanup TRAP won't execute
  @bwrap@ \
    --ro-bind / / \
    --bind "$temp_dir" /mnt \
    --tmpfs /tmp \
    --bind "$HOME/.config/claude" /tmp/config \
    --bind "$HOME/.local/share/claude" /tmp/data \
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

validate_remote() {
  local remote="${1:-}"
  shift

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

push() {
  local sweatshop_id
  sweatshop_id="${1:-}"
  shift

  local branch
  branch="${1:-$(git branch --show-current)}"
  shift

  # Validate arguments
  if [[ -z $sweatshop_id ]]; then
    echo "Error: push command requires SWEATSHOP_ID argument" >&2
    echo "Usage: $0 push SWEATSHOP_ID BRANCH" >&2
    exit 1
  fi

  validate_remote "$sweatshop_id"

  local temp_dir
  temp_dir="$(git remote get-url "$sweatshop_id")"
  branch="$(git branch --show-current)"

  git push "$sweatshop_id" HEAD:refs/heads/temp-updates
  git -C "$temp_dir" rebase temp-updates "$branch"
  git -C "$temp_dir" branch -d temp-updates
}

pull() {
  local sweatshop_id
  sweatshop_id="${1:-}"
  shift

  local branch
  branch="${1:-$(git branch --show-current)}"
  shift

  # Validate arguments
  if [[ -z $sweatshop_id ]]; then
    echo "Error: pull command requires SWEATSHOP_ID argument" >&2
    echo "Usage: $0 push SWEATSHOP_ID BRANCH" >&2
    exit 1
  fi

  validate_remote "$sweatshop_id"

  local temp_dir

  temp_dir="$(git remote get-url "$sweatshop_id")"
  branch="$(git branch --show-current)"

  git pull "$sweatshop_id" "$branch"
}

case $COMMAND in
# keep these sorted
attach) attach "$@" ;;
create) create "$@" ;;
destroy) destroy "$@" ;;
pull) pull "$@" ;;
push) push "$@" ;;
run) run "$@" ;;
run-temp) run_temp "$@" ;;
esac
