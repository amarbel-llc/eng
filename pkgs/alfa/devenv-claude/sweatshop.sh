#!/usr/bin/env bash
set -euo pipefail

# Default values
BRANCH="$(git branch --show-current)"
SWEATSHOP_BRANCH=""
TEMP_DIR=""
WORKTREE_PATH=""

WORKTREE_ON=""

# Function to show usage
usage() {
  echo "Usage: $0 [-b BRANCH] [-d TEMP_DIR] [claude-args...]"
  echo "  -b BRANCH    Branch to checkout (default: main)"
  echo "  -d TEMP_DIR  Temporary directory to use (default: auto-generated)"
  echo "  -h           Show this help message"
  echo ""
  echo "All remaining arguments are passed to claude-code"
  exit 1
}

# Function to cleanup on exit
cleanup() {
  local exit_code=$?

  if [[ -n $WORKTREE_ON && -n $WORKTREE_PATH && -d $WORKTREE_PATH ]]; then
    echo "Removing worktree: $WORKTREE_PATH" >&2
    git worktree remove "$WORKTREE_PATH" --force 2>/dev/null || true
  fi

  if [[ -n $TEMP_DIR && -d $TEMP_DIR ]]; then
    echo "Removing temporary directory: $TEMP_DIR" >&2
    rm -rf "$TEMP_DIR" 2>/dev/null || true
  fi

  # TODO check to see if the branch has been integrated into $BRANCH,
  # and don't delete it if it hasn't
  if [[ -n $WORKTREE_ON && -n $SWEATSHOP_BRANCH ]]; then
    echo "Removing sweatshop branch: $SWEATSHOP_BRANCH" >&2
    git branch -d "$SWEATSHOP_BRANCH" 2>/dev/null || true
  fi

  exit $exit_code
}

# Set up cleanup trap
trap cleanup EXIT INT TERM

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

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Error: Not in a git repository" >&2
  exit 1
fi

# Create temporary directory if not specified
if [[ -z $TEMP_DIR ]]; then
  TEMP_DIR=$(mktemp -d -t claude-worktree-XXXXXX)
else
  mkdir -p "$TEMP_DIR"
fi

if [[ -n $WORKTREE_ON ]]; then
  # Set worktree path
  WORKTREE_PATH="$TEMP_DIR/worktree"

  # TODO be more intelligent about the TEMP_ID, as it could have been
  # user specified
  TEMP_ID="$(basename "$TEMP_DIR")"
  SWEATSHOP_BRANCH="$TEMP_ID"

  git branch "$TEMP_ID"
  echo "Creating linked worktree for branch '$BRANCH' in: $WORKTREE_PATH" >&2

  # Create the worktree
  if ! git worktree add "$WORKTREE_PATH" "$SWEATSHOP_BRANCH"; then
    echo "Error: Failed to create worktree for branch '$SWEATSHOP_BRANCH'" >&2
    echo "Branch may not exist or worktree already exists for this branch" >&2
    exit 1
  fi

  # Configure git user for the worktree
  (cd "$WORKTREE_PATH" && git config user.email "claude@anthropic.com" && git config user.name "Claude Code")

  echo "Worktree created successfully" >&2
  echo "Working directory: $WORKTREE_PATH" >&2
  echo "" >&2
else
  WORKTREE_PATH="$(git rev-parse --show-toplevel)"
fi

echo "$WORKTREE_PATH"

# Create necessary directories if they don't exist
mkdir -p "$HOME/.config/claude"
mkdir -p "$HOME/.local/share/claude"

WORKSPACE_PATH="$(realpath --relative-to="$(git rev-parse --show-toplevel)" .)"

exec @bwrap@ \
  --ro-bind / / \
  --bind "$WORKTREE_PATH" /mnt \
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
