#!/usr/bin/env bash
set -euo pipefail

# Default values
BRANCH="$(git branch --show-current)"
TEMP_ID=""
TEMP_DIR=""
CLONE="true"
COMMAND=""

# Function to show usage
usage() {
  echo "Usage: $0 [COMMAND] [OPTIONS] [args...]"
  echo ""
  echo "Commands:"
  echo "  run          Run claude-code in sandboxed environment (default)"
  echo "  update REMOTE BRANCH   update changes from a claude-prefixed remote"
  echo ""
  echo "Options:"
  echo "  -b BRANCH    Branch to checkout (default: current branch)"
  echo "  -d TEMP_DIR  Temporary directory to use (default: auto-generated)"
  echo "  -h           Show this help message"
  echo ""
  echo "All remaining arguments are passed to claude-code"
  exit 1
}

# Function to cleanup on exit
cleanup() {
  local exit_code=$?

  # TODO check if there are unmerged changes against the parent repo. If there
  # are, do not delete the remote directory or git remote

  if [[ -n $TEMP_DIR && -d $TEMP_DIR ]]; then
    echo "Removing temporary directory: $TEMP_DIR" >&2
    rm -rf "$TEMP_DIR" 2>/dev/null || true
  fi

  if [[ -n $CLONE && -n $TEMP_ID ]]; then
    echo "Removing git remote: $TEMP_ID" >&2
    git remote remove "$TEMP_ID"
  fi

  exit $exit_code
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

# Parse command (first argument if it doesn't start with -)
if [[ $# -gt 0 && $1 != -* ]]; then
  COMMAND="$1"
  shift
else
  COMMAND="run"
fi

# Validate command
case $COMMAND in
run)
  # Default behavior - continue with existing logic
  ;;
update)
  # update command - validate arguments later
  ;;
*)
  echo "Error: Unknown command '$COMMAND'" >&2
  usage
  ;;
esac

# Parse command line options
while getopts "b:d:h" opt; do
  case $opt in
  b)
    BRANCH="$OPTARG"
    ;;
  d)
    TEMP_DIR="$OPTARG"
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

# Function to run claude-code in sandboxed environment
run_claude() {
  # Create temporary directory if not specified
  if [[ -z $TEMP_DIR ]]; then
    TEMP_DIR=$(mktemp -d -t claude-XXXXXX)
  else
    mkdir -p "$TEMP_DIR"
  fi

  # TODO be more intelligent about the TEMP_ID, as it could have been
  # user specified
  TEMP_ID="$(basename "$TEMP_DIR")"

  TO_BIND="$TEMP_DIR"
  origin="$(git rev-parse --show-toplevel)"

  if [[ -n $CLONE ]]; then
    (
      pushd "$TEMP_DIR" || true

      # Create the worktree
      if ! git clone --local "$origin" .; then
        echo "Error: Failed to clone repo" >&2
        exit 1
      fi

      echo "Cloned successfully" >&2
      echo "Clone directory: $TEMP_DIR" >&2
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
    if ! git remote add "$TEMP_ID" "$TEMP_DIR"; then
      echo "Error: Failed to add remote: $TEMP_ID" >&2
      exit 1
    fi

    echo "Git remote added successfully: $TEMP_ID" >&2
    echo "" >&2
  else
    TO_BIND="$origin"
  fi

  # Create necessary directories if they don't exist
  mkdir -p "$HOME/.config/claude"
  mkdir -p "$HOME/.local/share/claude"

  WORKSPACE_PATH="$(realpath --relative-to="$(git rev-parse --show-toplevel)" .)"

  # cannot use exec otherwise the cleanup TRAP won't execute
  @bwrap@ \
    --ro-bind / / \
    --bind "$TO_BIND" /mnt \
    --tmpfs /tmp \
    --bind "$HOME/.config/claude" /tmp/config \
    --bind "$HOME/.local/share/claude" /tmp/data \
    --chdir "/mnt/$WORKSPACE_PATH" \
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

# Function to update changes from a claude-prefixed remote
update_from_remote() {
  local remote="${1:-}"
  
  # Validate arguments
  if [[ -z $remote ]]; then
    echo "Error: update command requires REMOTE argument" >&2
    echo "Usage: $0 update REMOTE BRANCH" >&2
    exit 1
  fi
  
  # Validate that remote exists and is prefixed with 'claude'
  if ! git remote get-url "$remote" >/dev/null 2>&1; then
    echo "Error: Remote '$remote' does not exist" >&2
    exit 1
  fi
  
  if [[ $remote != claude* ]]; then
    echo "Error: Remote '$remote' must be prefixed with 'claude'" >&2
    exit 1
  fi

  TEMP_DIR="$(git remote get-url "$remote")"
  BRANCH="$(git branch --show-current)"
  
  git push "$remote" HEAD:refs/heads/temp-updates
  git -C "$TEMP_DIR" rebase temp-updates "$BRANCH"
  git -C "$TEMP_DIR" branch -d temp-updates
}

# Execute the appropriate command
case $COMMAND in
run)
  run_claude "$@"
  ;;
update)
  update_from_remote "$@"
  ;;
esac
